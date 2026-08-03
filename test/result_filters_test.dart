import 'package:flutter_test/flutter_test.dart';
import 'package:watch_next/utils/result_filters.dart';

void main() {
  group('dedupeResponseEntries', () {
    test('drops verbatim repeats', () {
      final entries = ' Dune y:2021,, Arrival y:2016,, Dune y:2021'.split(',,');
      expect(dedupeResponseEntries(entries).length, 2);
    });

    test('drops article and punctuation variants of the same title', () {
      final entries = 'The Terminator y:1984,, Terminator y:1984,, '
              'Terminator 2: Judgment Day y:1991,, Terminator 2 Judgment Day y:1991'
          .split(',,');
      final unique = dedupeResponseEntries(entries);
      expect(unique.length, 2);
      expect(unique.first.trim(), 'The Terminator y:1984');
    });

    test('keeps distinct titles that merely share words', () {
      final entries = 'Alien y:1979,, Aliens y:1986,, Alien: Romulus y:2024'.split(',,');
      expect(dedupeResponseEntries(entries).length, 3);
    });
  });

  group('isSeedTitle', () {
    test('matches the title a request points at', () {
      expect(isSeedTitle('The Terminator', 'A movie like Terminator'), isTrue);
      expect(isSeedTitle('Terminator', 'a movie like the terminator'), isTrue);
      expect(isSeedTitle('The Godfather', 'Movies similar to The Godfather'), isTrue);
      expect(isSeedTitle('Breaking Bad', 'shows like breaking bad'), isTrue);
    });

    test('matches a bare title typed on its own', () {
      expect(isSeedTitle('The Terminator', 'Terminator'), isTrue);
      expect(isSeedTitle('Inception', 'inception'), isTrue);
    });

    test('matches multi-word titles anywhere in the request', () {
      expect(isSeedTitle('Pulp Fiction', 'something with the energy of pulp fiction'), isTrue);
    });

    test('leaves the other 39 recommendations alone', () {
      expect(isSeedTitle('Predator', 'A movie like Terminator'), isFalse);
      expect(isSeedTitle('Mad Max: Fury Road', 'movies like terminator'), isFalse);
    });

    test('does not treat a descriptive word as a title reference', () {
      expect(isSeedTitle('Alien', 'alien invasion movies'), isFalse);
      expect(isSeedTitle('Drive', 'movies to drive the night away'), isFalse);
    });

    test('ignores titles too short to match safely', () {
      expect(isSeedTitle('Up', 'a movie like up'), isFalse);
      expect(isSeedTitle('Her', 'movies like her'), isFalse);
    });

    test('handles the media-detail similar flow', () {
      expect(isSeedTitle('Interstellar', 'Movies similar to Interstellar'), isTrue);
    });
  });
}
