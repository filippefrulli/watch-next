/// Cleanup helpers applied to the title list the LLM returns.
///
/// The model is instructed not to repeat itself and not to hand back the very
/// title the user asked to be matched, but it does both often enough that the
/// app treats the prompt as a hint and enforces it here.
library;

/// Punctuation the model and TMDB disagree on ("Spider-Man" vs "Spider Man",
/// "Terminator 2: Judgment Day" vs "Terminator 2 Judgment Day"). Letters of any
/// script are left alone so non-Latin titles still normalise to something.
final RegExp _punctuation = RegExp(r"""[\-–—_:;,.!?'’"“”()\[\]{}/\\|*+~`^<>=@#$%&]""");
final RegExp _whitespace = RegExp(r'\s+');

/// Leading articles across the app's 8 languages — "The Terminator" and
/// "Terminator" have to collapse onto the same key.
const List<String> _articles = [
  'the', 'a', 'an', // en
  'il', 'lo', 'la', 'le', 'gli', 'i', 'un', 'uno', 'una', // it
  'der', 'die', 'das', 'ein', 'eine', // de
  'les', 'l', 'un', 'une', 'des', // fr
  'el', 'los', 'las', 'unos', 'unas', // es
  'o', 'os', 'as', 'um', 'uma', // pt
];

/// Phrases that mark the user's query as pointing *at* a title rather than
/// describing one, in any of the supported languages.
const List<String> _referenceCues = [
  'like', 'similar', 'such as', 'in the vein of', 'reminiscent', 'reminds',
  'come', 'simile', 'simili', 'stile di', // it
  'wie', 'ähnlich', 'aehnlich', // de
  'comme', 'similaire', 'dans le genre', // fr
  'como', 'parecido', 'parecida', 'similares', // es / pt
  'みたい', 'のよう', 'っぽい', // ja
  'जैसे', 'जैसी', 'जैसा', // hi
];

/// Lowercases, drops punctuation and collapses whitespace.
String normalizeTitle(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(_punctuation, ' ')
      .replaceAll(_whitespace, ' ')
      .trim();
}

/// [normalizeTitle] plus a leading article, so article variants share a key.
String _core(String raw) {
  final normalized = normalizeTitle(raw);
  final space = normalized.indexOf(' ');
  if (space <= 0) return normalized;
  final first = normalized.substring(0, space);
  if (!_articles.contains(first)) return normalized;
  return normalized.substring(space + 1);
}

/// Whole-token containment: "her" must not match "there", but Japanese and
/// other unspaced scripts fall back to a plain substring test.
bool _containsPhrase(String haystack, String needle) {
  if (needle.isEmpty) return false;
  if (!RegExp(r'[a-z0-9]').hasMatch(needle)) return haystack.contains(needle);
  return ' $haystack '.contains(' $needle ');
}

bool _hasReferenceCue(String request) =>
    _referenceCues.any((cue) => request.contains(cue));

/// True when [title] is the title the request is built around — "a movie like
/// Terminator" must not come back with Terminator itself, and a bare "Terminator"
/// is a request for what to watch *next*, not for the film the user just named.
///
/// Deliberately conservative: a single-word title only counts when the request
/// is that word alone or explicitly points at it, so "alien invasion movies"
/// still gets to recommend *Alien*.
bool isSeedTitle(String title, String request) {
  final core = _core(title);
  if (core.length < 4) return false; // "Up", "Her" — too generic to match on
  final normalizedRequest = normalizeTitle(request);
  if (normalizedRequest.isEmpty) return false;

  final mentioned = _containsPhrase(normalizedRequest, core) ||
      _containsPhrase(normalizedRequest, normalizeTitle(title));
  if (!mentioned) return false;

  // A multi-word title in the request is specific enough on its own.
  if (core.contains(' ')) return true;

  final requestCore = _core(request);
  return requestCore == core || _hasReferenceCue(normalizedRequest);
}

/// Drops repeated entries from the raw `title y:year,,` list before any TMDB
/// lookup happens, keying on the article-stripped title so "Terminator" and
/// "The Terminator" cost a single request instead of two.
///
/// Entries are returned in their original order, punctuation and all, since the
/// TMDB search still wants the model's own spelling.
List<String> dedupeResponseEntries(List<String> entries) {
  final seen = <String>{};
  final unique = <String>[];
  for (final entry in entries) {
    if (entry.trim().isEmpty) continue;
    final key = _core(entry.split('y:').first);
    if (key.isEmpty || seen.add(key)) unique.add(entry);
  }
  return unique;
}
