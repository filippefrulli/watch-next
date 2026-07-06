/**
 * Watch Next — API key proxy.
 *
 * All third-party keys (OpenAI, TMDB, OMDb) live here as Firebase
 * Secrets and NEVER ship inside the app binary. The app calls these functions
 * instead of the upstream APIs. Every request must carry a valid Firebase
 * App Check token, which proves it came from a genuine, unmodified build of
 * the app — a decompiler can read a function URL out of the binary but cannot
 * forge an App Check token, so a scraped URL is useless to an attacker.
 */

import { onRequest, Request } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { getAppCheck } from "firebase-admin/app-check";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import type { Response } from "express";

initializeApp();

// ---- Secrets (set with: firebase functions:secrets:set OPENAI_KEY) ----------
const OPENAI_KEY = defineSecret("OPENAI_KEY");
const TMDB_KEY = defineSecret("TMDB_KEY");
const OMDB_KEY = defineSecret("OMDB_KEY");

// Safety valve: max LLM requests served per calendar day (UTC) across ALL
// users. Bounds the worst-case bill if App Check is ever bypassed. Tune to
// taste — a normal user makes a handful of recommendation calls per session.
const LLM_DAILY_CAP = 20000;

/**
 * Rejects the request unless it carries a valid App Check token.
 * Returns true when the request may proceed (response already sent on failure).
 */
async function requireAppCheck(req: Request, res: Response): Promise<boolean> {
  const token = req.header("X-Firebase-AppCheck");
  if (!token) {
    res.status(401).json({ error: "Missing App Check token" });
    return false;
  }
  try {
    await getAppCheck().verifyToken(token);
    return true;
  } catch (err) {
    logger.warn("App Check verification failed", err);
    res.status(401).json({ error: "Invalid App Check token" });
    return false;
  }
}

/**
 * Atomically increments today's LLM counter and returns false once the daily
 * cap is exceeded. Fails open on Firestore errors so a transient DB blip never
 * takes recommendations down.
 */
async function withinDailyLlmCap(): Promise<boolean> {
  try {
    const day = new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)
    const ref = getFirestore().collection("backend_meta").doc(`llm_usage_${day}`);
    const count = await getFirestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const current = (snap.exists ? (snap.get("count") as number) : 0) ?? 0;
      tx.set(ref, { count: current + 1, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      return current + 1;
    });
    return count <= LLM_DAILY_CAP;
  } catch (err) {
    logger.error("Daily-cap check failed, allowing request", err);
    return true;
  }
}

// ---------------------------------------------------------------------------
// LLM: OpenAI-backed recommendation + query validation. Body: { system?, user }
// Returns: { content }
// ---------------------------------------------------------------------------
export const llm = onRequest(
  { secrets: [OPENAI_KEY], timeoutSeconds: 120, memory: "256MiB" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }
    if (!(await requireAppCheck(req, res))) return;

    const { system, user } = req.body ?? {};
    if (typeof user !== "string" || user.length === 0) {
      res.status(400).json({ error: "Missing 'user' content" });
      return;
    }
    if (user.length > 8000 || (system && String(system).length > 8000)) {
      res.status(400).json({ error: "Prompt too long" });
      return;
    }

    if (!(await withinDailyLlmCap())) {
      logger.warn("Daily LLM cap reached");
      res.status(429).json({ error: "Daily limit reached" });
      return;
    }

    try {
      const messages: Array<{ role: string; content: string }> = [];
      if (system) messages.push({ role: "system", content: String(system) });
      messages.push({ role: "user", content: user });
      const r = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${OPENAI_KEY.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-5-mini",
          messages,
          reasoning_effort: "low",
        }),
      });
      if (!r.ok) {
        logger.error("OpenAI error", r.status, await r.text());
        res.status(502).json({ error: "Upstream LLM error" });
        return;
      }
      const data = (await r.json()) as any;
      const content = data?.choices?.[0]?.message?.content ?? "";

      res.status(200).json({ content });
    } catch (err) {
      logger.error("LLM request failed", err);
      res.status(500).json({ error: "LLM request failed" });
    }
  }
);

// ---------------------------------------------------------------------------
// TMDB: transparent pass-through. The app calls /tmdb/<tmdb-path>?<params>;
// we inject api_key server-side and return TMDB's JSON verbatim so the app's
// existing response parsing is unchanged.
// ---------------------------------------------------------------------------
const TMDB_ALLOWED = /^\/3\/[A-Za-z0-9/_-]*$/; // only TMDB v3 read paths

export const tmdb = onRequest(
  { secrets: [TMDB_KEY], timeoutSeconds: 30, memory: "256MiB" },
  async (req, res) => {
    if (!(await requireAppCheck(req, res))) return;

    // Normalise the path to the TMDB portion, e.g. "/3/movie/123". Depending on
    // routing the leading "/tmdb" function segment may or may not be present.
    const path = req.path.replace(/^\/tmdb/, "");
    if (!TMDB_ALLOWED.test(path)) {
      res.status(400).json({ error: "Unsupported path" });
      return;
    }

    const url = new URL(`https://api.themoviedb.org${path}`);
    for (const [k, v] of Object.entries(req.query)) {
      if (k === "api_key") continue; // never let the caller override the key
      if (typeof v === "string") url.searchParams.set(k, v);
    }
    url.searchParams.set("api_key", TMDB_KEY.value());

    try {
      const r = await fetch(url, { headers: { Accept: "application/json" } });
      const body = await r.text();
      res.status(r.status).set("Content-Type", "application/json").send(body);
    } catch (err) {
      logger.error("TMDB proxy failed", err);
      res.status(502).json({ error: "TMDB request failed" });
    }
  }
);

// ---------------------------------------------------------------------------
// OMDb: pass-through for ratings lookups. The app calls /omdb?i=<imdbId>.
// ---------------------------------------------------------------------------
export const omdb = onRequest(
  { secrets: [OMDB_KEY], timeoutSeconds: 30, memory: "256MiB" },
  async (req, res) => {
    if (!(await requireAppCheck(req, res))) return;

    const url = new URL("https://www.omdbapi.com/");
    for (const [k, v] of Object.entries(req.query)) {
      if (k === "apikey") continue;
      if (typeof v === "string") url.searchParams.set(k, v);
    }
    url.searchParams.set("apikey", OMDB_KEY.value());

    try {
      const r = await fetch(url, { headers: { Accept: "application/json" } });
      const body = await r.text();
      res.status(r.status).set("Content-Type", "application/json").send(body);
    } catch (err) {
      logger.error("OMDb proxy failed", err);
      res.status(502).json({ error: "OMDb request failed" });
    }
  }
);
