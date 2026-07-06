# Watch Next — API key proxy setup

All third-party API keys (OpenAI, TMDB, OMDb) now live **server-side**
in these Cloud Functions and no longer ship inside the app binary. The app
reaches them through App Check-gated endpoints, so a decompiled build no longer
leaks any usable key.

Functions:
- `llm`  — OpenAI recommendation + query validation. Has a global daily
  request cap (`LLM_DAILY_CAP` in `src/index.ts`) as a cost safety valve.
- `tmdb` — transparent TMDB v3 pass-through.
- `omdb` — OMDb ratings pass-through.

## One-time setup

### 1. Install + build
```bash
cd functions
npm install
npm run build
```

### 2. Set the keys as Firebase Secrets
Use **freshly rotated** keys here (the old ones must be treated as public — they
shipped in released builds). Run each and paste the value when prompted:
```bash
firebase functions:secrets:set OPENAI_KEY
firebase functions:secrets:set TMDB_KEY
firebase functions:secrets:set OMDB_KEY
```

### 3. Deploy
```bash
firebase deploy --only functions
```
Deployed URLs will be:
`https://us-central1-watch-next-13.cloudfunctions.net/{llm,tmdb,omdb}`
(matches `BackendService.base` in `lib/services/backend_service.dart`).

### 4. Enable App Check (the anti-abuse core)
In Firebase Console → **App Check**:
1. Register the **Android** app with the **Play Integrity** provider.
2. Register the **iOS** app with the **App Attest** provider.
   - Add the **App Attest** capability to the iOS target in Xcode.
3. Under App Check → **APIs**, set **Cloud Functions** to **Enforced** once the
   new app version with App Check is live (see rollout note below).

#### Local debug testing
Debug builds use the App Check *debug* provider. On first run the app logs a
debug token like:
`App Check debug token: 01234567-89AB-...`
Copy it into Firebase Console → App Check → your app → **Manage debug tokens**.

### 5. Rotate the old keys
After the secrets are set and functions deployed, rotate (regenerate) the keys
at their providers so the previously-leaked values stop working:
- OpenAI: platform.openai.com → API keys
- TMDB: themoviedb.org → Settings → API
- OMDb: request a new key if desired (low risk; free tier)

Set a **hard monthly usage limit** in the OpenAI dashboard as a second safety net.

## Rollout note (avoid breaking live users)

App Check enforcement on Cloud Functions will **reject any app build that
doesn't send a token** — i.e. every currently-installed older version. Sequence:

1. Deploy functions with App Check **unenforced** (verifyToken still runs in the
   code but you can start in Console "Monitoring" mode first if you prefer).
2. Release the new app version (this build sends App Check tokens + calls the
   proxy).
3. Watch App Check metrics until the vast majority of traffic is verified.
4. Flip Cloud Functions to **Enforced**, and force-upgrade stragglers if needed.

Because old app versions still call TMDB/OpenAI/etc. *directly* with the old
(now-rotated) keys, those old installs will lose recommendations until updated —
that's expected and is the point. Use the force-upgrade gate below to push them.

## Force-upgrade gate

The app checks Remote Config on launch (in `Splash`) and, if the running build
is older than the minimum, shows a blocking update screen
(`lib/pages/force_upgrade_page.dart`). Wiring: `VersionGateService` →
`min_required_build` (integer) Remote Config parameter.

To require an update:
1. Firebase Console → **Remote Config** → add/edit parameter
   **`min_required_build`** (Integer).
2. Set it to the lowest build number you want to keep alive. Current build is
   `49` (from `pubspec.yaml` `version: 2.8.3+49`). For example, after you ship a
   build `50` that uses the proxy, set `min_required_build = 50` to force
   everyone on `49` and below to update.
3. Publish. The gate fails **open** — if Remote Config can't be reached, or the
   value is `0`/unset, no one is blocked.

Notes:
- The value is the **build number** (the part after `+`), not the marketing
  version, so it increases monotonically and is easy to compare.
- Remote Config is throttled to a 6h `minimumFetchInterval`, so a freshly
  published bump can take up to ~6h to reach an already-open app (immediate on
  next cold start after the cache expires).
- Recommended sequence: release the proxy build → wait until it's live on both
  stores → bump `min_required_build` to that build number.
