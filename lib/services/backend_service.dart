import 'dart:convert';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:http/http.dart' as http;

/// Talks to the Watch Next Cloud Functions that proxy every third-party API
/// (OpenAI, TMDB, OMDb). The real API keys live server-side and never ship
/// inside the app binary. Each request carries a Firebase App Check token so
/// the backend can prove it came from a genuine build of this app.
class BackendService {
  /// Base URL of the deployed functions (region-project.cloudfunctions.net).
  static const String base = 'https://us-central1-watch-next-13.cloudfunctions.net';

  static final http.Client _client = http.Client();

  /// Current App Check token, or null if one can't be obtained (offline, not
  /// yet attested). The token is short-lived; [FirebaseAppCheck.getToken]
  /// returns a cached one until it is close to expiry, so this is cheap.
  static Future<String?> appCheckToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (_) {
      return null; // Backend rejects with 401; callers handle the failure.
    }
  }

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await appCheckToken();
    return {
      if (token != null) 'X-Firebase-AppCheck': token,
      if (json) 'Content-Type': 'application/json',
    };
  }

  /// Calls the OpenAI-backed LLM proxy and returns the model's text content.
  /// [system] is an optional system prompt; [user] is the user prompt.
  static Future<String> llm({
    String? system,
    required String user,
  }) async {
    final res = await _client.post(
      Uri.parse('$base/llm'),
      headers: await _headers(json: true),
      body: jsonEncode({
        if (system != null) 'system': system,
        'user': user,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('LLM proxy error: ${res.statusCode} - ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['content'] as String?) ?? '';
  }

  /// OMDb pass-through. [params] are OMDb query params (e.g. {'i': imdbId}).
  static Future<http.Response> omdbGet(Map<String, String> params) async {
    final uri = Uri.parse('$base/omdb').replace(queryParameters: params);
    return _client.get(uri, headers: await _headers());
  }
}
