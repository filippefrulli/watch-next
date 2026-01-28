import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/movie_credits.dart';
import 'package:watch_next/objects/series_details.dart';
import 'package:watch_next/objects/series_search_results.dart';
import 'package:watch_next/objects/streaming_service.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/objects/watch_providers.dart';
import 'package:watch_next/utils/secrets.dart';
import '../objects/search_results.dart';
import '../objects/movie_details.dart';
import 'database_service.dart';

/// Result containing watch providers and their availability type
class WatchProvidersResult {
  final List<int> providerIds;
  final bool hasStreaming; // Available on a streaming subscription
  final bool hasRent; // Available for rent
  final bool hasBuy; // Available to buy

  const WatchProvidersResult({
    required this.providerIds,
    this.hasStreaming = false,
    this.hasRent = false,
    this.hasBuy = false,
  });

  /// True if only available for rent (no streaming)
  bool get isRentOnly => !hasStreaming && hasRent;

  /// True if only available to buy (no streaming, no rent)
  bool get isBuyOnly => !hasStreaming && !hasRent && hasBuy;
}

class HttpService {
  final String apiKey = tmdbApiKey;

  String thumbnail = "https://i.ytimg.com//vi//d_m5csmrf7I//hqdefault.jpg";

  final String baseUrl = 'https://www.youtube.com/watch?v=';

  // Singleton HTTP client for connection reuse
  static final http.Client _client = http.Client();

  // Getter to access the shared client
  static http.Client get client => _client;

  Future<Results> findMovieByTitle(String title, String year) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String lang = prefs.getString('lang') ?? 'en-US';

      var response = await _client
          .get(
            Uri.https('api.themoviedb.org', '/3/search/movie', {
              'api_key': apiKey,
              'language': lang,
              'query': title,
              'year': year,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        log('TMDB API error: ${response.statusCode}');
        return Results();
      }
      SearchResults? searchResults = SearchResults.fromJson(jsonDecode(response.body));

      if (searchResults.results!.isNotEmpty) {
        return searchResults.results![0];
      }
      return Results();
    } catch (e) {
      log('Error finding movie by title: $e');
      return Results();
    }
  }

  Future<SeriesResults> findShowByTitle(String title, String year) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String lang = prefs.getString('lang') ?? 'en-US';

      var response = await _client
          .get(
            Uri.https('api.themoviedb.org', '/3/search/tv', {
              'api_key': apiKey,
              'language': lang,
              'query': title,
              'first_air_date_year': year,
              'include_adult': 'true',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        log('TMDB API error: ${response.statusCode}');
        return SeriesResults();
      }
      SeriesSearchResults? searchResults = SeriesSearchResults.fromJson(jsonDecode(response.body));

      if (searchResults.results!.isNotEmpty) {
        return searchResults.results![0];
      }
      return SeriesResults();
    } catch (e) {
      log('Error finding show by title: $e');
      return SeriesResults();
    }
  }

  Future<MovieDetails> fetchMovieDetails(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lang = prefs.getString('lang') ?? 'en-US';

    final response = await _client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/movie/$id',
        {'api_key': apiKey, 'language': lang},
      ),
    );

    MovieDetails details = MovieDetails.fromJson(jsonDecode(response.body));

    return details;
  }

  Future<SeriesDetails> fetchSeriesDetails(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lang = prefs.getString('lang') ?? 'en-US';

    final response = await _client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/tv/$id',
        {'api_key': apiKey, 'language': lang},
      ),
    );

    SeriesDetails details = SeriesDetails.fromJson(jsonDecode(response.body));

    return details;
  }

  Future<WatchProvidersResult> getWatchProviders(
    int id, {
    bool includeRentals = false,
    bool includePurchases = false,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.https(
              'api.themoviedb.org',
              '/3/movie/$id/watch/providers',
              {'api_key': apiKey, 'language': 'en-US'},
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        log('TMDB API error getting watch providers: ${response.statusCode}');
        return const WatchProvidersResult(providerIds: []);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String region = prefs.getString('region') ?? 'DE';

      List<String> providers = jsonDecode(response.body)["results"].keys.toList();

      List<int> movieProvidersIds = [];
      bool hasStreaming = false;
      bool hasRent = false;
      bool hasBuy = false;

      if (providers.contains(region)) {
        List<int> myProvidersIds = await DatabaseService.getStreamingServicesIds();

        ProviderRegion provider = ProviderRegion.fromJson(jsonDecode(response.body)["results"][region]);

        // Always check streaming (flatrate) - only from user's selected services
        if (provider.flatrate != null) {
          for (StreamingType item in provider.flatrate!) {
            if (myProvidersIds.contains(item.providerId)) {
              movieProvidersIds.add(item.providerId!);
              hasStreaming = true;
            }
          }
        }

        // Check rentals if enabled - include any rental provider
        if (includeRentals && provider.rent != null) {
          for (StreamingType item in provider.rent!) {
            if (!movieProvidersIds.contains(item.providerId)) {
              movieProvidersIds.add(item.providerId!);
              hasRent = true;
            }
          }
        }

        // Check purchases if enabled - include any purchase provider
        if (includePurchases && provider.buy != null) {
          for (StreamingType item in provider.buy!) {
            if (!movieProvidersIds.contains(item.providerId)) {
              movieProvidersIds.add(item.providerId!);
              hasBuy = true;
            }
          }
        }
      }

      return WatchProvidersResult(
        providerIds: movieProvidersIds,
        hasStreaming: hasStreaming,
        hasRent: hasRent,
        hasBuy: hasBuy,
      );
    } catch (e) {
      log('Error getting watch providers: $e');
      return const WatchProvidersResult(providerIds: []);
    }
  }

  Future<WatchProvidersResult> getWatchProvidersSeries(
    int id, {
    bool includeRentals = false,
    bool includePurchases = false,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.https(
              'api.themoviedb.org',
              '/3/tv/$id/watch/providers',
              {'api_key': apiKey, 'language': 'en-US'},
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        log('TMDB API error getting watch providers for series: ${response.statusCode}');
        return const WatchProvidersResult(providerIds: []);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String region = prefs.getString('region') ?? 'DE';

      List<String> providers = jsonDecode(response.body)["results"].keys.toList();

      List<int> movieProvidersIds = [];
      bool hasStreaming = false;
      bool hasRent = false;
      bool hasBuy = false;

      if (providers.contains(region)) {
        List<int> myProvidersIds = await DatabaseService.getStreamingServicesIds();

        ProviderRegion provider = ProviderRegion.fromJson(jsonDecode(response.body)["results"][region]);

        // Always check streaming (flatrate) - only from user's selected services
        if (provider.flatrate != null) {
          for (StreamingType item in provider.flatrate!) {
            if (myProvidersIds.contains(item.providerId)) {
              movieProvidersIds.add(item.providerId!);
              hasStreaming = true;
            }
          }
        }

        // Check rentals if enabled - include any rental provider
        if (includeRentals && provider.rent != null) {
          for (StreamingType item in provider.rent!) {
            if (!movieProvidersIds.contains(item.providerId)) {
              movieProvidersIds.add(item.providerId!);
              hasRent = true;
            }
          }
        }

        // Check purchases if enabled - include any purchase provider
        if (includePurchases && provider.buy != null) {
          for (StreamingType item in provider.buy!) {
            if (!movieProvidersIds.contains(item.providerId)) {
              movieProvidersIds.add(item.providerId!);
              hasBuy = true;
            }
          }
        }
      }

      return WatchProvidersResult(
        providerIds: movieProvidersIds,
        hasStreaming: hasStreaming,
        hasRent: hasRent,
        hasBuy: hasBuy,
      );
    } catch (e) {
      log('Error getting watch providers for series: $e');
      return const WatchProvidersResult(providerIds: []);
    }
  }

  Future<List<StreamingService>> getWatchProvidersByLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String region = prefs.getString('region') ?? 'DE';
    final response = await _client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/watch/providers/movie',
        {'api_key': apiKey, 'language': 'en-US', 'watch_region': region},
      ),
    );

    ResultProviders providers = ResultProviders.fromJson(
      jsonDecode(response.body),
    );

    List<StreamingService> list = providers.results!;
    list.removeWhere(
      (item) => item.displayPriority! > 100,
    );

    return list;
  }

  Future<MovieCredits> fetchMovieCredits(int id) async {
    final response = await _client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/movie/$id/credits',
        {'api_key': apiKey},
      ),
    );

    MovieCredits credits = MovieCredits.fromJson(jsonDecode(response.body));

    return credits;
  }

  Future<List<TrailerResults>> fetchTrailer(int id) async {
    List<TrailerResults> trailerList = [];

    final response = await _client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/movie/$id/videos',
        {'api_key': apiKey, 'language': 'en-US'},
      ),
    );

    Map trailerMap = jsonDecode(response.body);
    Trailer trailer = Trailer.fromJson(trailerMap);
    if (trailer.results != null) {
      if (trailer.results!.isNotEmpty) {
        trailerList = trailer.results!;
        trailerList.removeWhere((item) => item.type != "Trailer");
        return trailerList;
      } else {
        return trailerList;
      }
    } else {
      return trailerList;
    }
  }

  Future<List<TrailerResults>> fetchTrailerSeries(int id) async {
    List<TrailerResults> trailerList = [];

    final response = await _client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/tv/$id/videos',
        {'api_key': apiKey, 'language': 'en-US'},
      ),
    );

    Map trailerMap = jsonDecode(response.body);
    Trailer trailer = Trailer.fromJson(trailerMap);
    if (trailer.results != null) {
      if (trailer.results!.isNotEmpty) {
        trailerList = trailer.results!;
        trailerList.removeWhere((item) => item.type != "Trailer");
        return trailerList;
      } else {
        return trailerList;
      }
    } else {
      return trailerList;
    }
  }

  Future<dynamic> getDetail(String? userUrl) async {
    //store http request response to res variable
    var res = await http.get(
      Uri.https('youtube.com', '/oembed', {'url': userUrl, 'format': 'json'}),
    );

    try {
      if (res.statusCode == 200) {
        //return the json from the response
        return json.decode(res.body);
      } else {
        //return null if status code other than 200
        return null;
      }
    } on FormatException catch (e) {
      log(e.message);
      return [];
    }
  }

  Future<CategorizedWatchProviders> getCategorizedWatchProviders(int id, bool isMovie) async {
    try {
      final endpoint = isMovie ? '/3/movie/$id/watch/providers' : '/3/tv/$id/watch/providers';

      final response = await _client
          .get(
            Uri.https(
              'api.themoviedb.org',
              endpoint,
              {'api_key': apiKey, 'language': 'en-US'},
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        log('TMDB API error getting watch providers: ${response.statusCode}');
        return CategorizedWatchProviders(streaming: [], rent: [], buy: []);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String region = prefs.getString('region') ?? 'DE';

      final results = jsonDecode(response.body)["results"];
      if (results == null || !results.keys.toList().contains(region)) {
        return CategorizedWatchProviders(streaming: [], rent: [], buy: []);
      }

      ProviderRegion provider = ProviderRegion.fromJson(results[region]);

      // Get all available providers with details
      final allProviders = await getWatchProvidersByLocale();

      // Helper function to convert provider IDs to StreamingService objects
      List<StreamingService> getServicesByIds(List<StreamingType>? types) {
        if (types == null) return [];
        final ids = types.map((t) => t.providerId).whereType<int>().toList();
        return allProviders.where((service) => ids.contains(service.providerId)).toList();
      }

      return CategorizedWatchProviders(
        streaming: getServicesByIds(provider.flatrate),
        rent: getServicesByIds(provider.rent),
        buy: getServicesByIds(provider.buy),
      );
    } catch (e) {
      log('Error getting categorized watch providers: $e');
      return CategorizedWatchProviders(streaming: [], rent: [], buy: []);
    }
  }

  Future<List<MultiSearchResult>> multiSearch(String query) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String lang = prefs.getString('lang') ?? 'en-US';

      var response = await _client
          .get(
            Uri.https('api.themoviedb.org', '/3/search/multi', {
              'api_key': apiKey,
              'language': lang,
              'query': query,
              'include_adult': 'false',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        log('TMDB API error: ${response.statusCode}');
        return [];
      }

      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      final List results = jsonData['results'] ?? [];

      // Filter for only movies and TV shows, convert to our model
      return results
          .where((item) => item['media_type'] == 'movie' || item['media_type'] == 'tv')
          .map((item) => MultiSearchResult.fromJson(item))
          .toList();
    } catch (e) {
      log('Error in multi search: $e');
      return [];
    }
  }
}

// Model for multi-search results
class MultiSearchResult {
  final int id;
  final String? title;
  final String? name;
  final String? posterPath;
  final String mediaType;
  final String? releaseDate;
  final String? firstAirDate;
  final double? voteAverage;
  final String? overview;

  MultiSearchResult({
    required this.id,
    this.title,
    this.name,
    this.posterPath,
    required this.mediaType,
    this.releaseDate,
    this.firstAirDate,
    this.voteAverage,
    this.overview,
  });

  factory MultiSearchResult.fromJson(Map<String, dynamic> json) {
    return MultiSearchResult(
      id: json['id'],
      title: json['title'],
      name: json['name'],
      posterPath: json['poster_path'],
      mediaType: json['media_type'],
      releaseDate: json['release_date'],
      firstAirDate: json['first_air_date'],
      voteAverage: json['vote_average']?.toDouble(),
      overview: json['overview'],
    );
  }

  String get displayTitle => title ?? name ?? 'Unknown';

  String get year {
    final date = releaseDate ?? firstAirDate;
    if (date != null && date.length >= 4) {
      return date.substring(0, 4);
    }
    return '';
  }

  bool get isMovie => mediaType == 'movie';
}

// Model for categorized watch providers
class CategorizedWatchProviders {
  final List<StreamingService> streaming;
  final List<StreamingService> rent;
  final List<StreamingService> buy;

  CategorizedWatchProviders({
    required this.streaming,
    required this.rent,
    required this.buy,
  });

  bool get isEmpty => streaming.isEmpty && rent.isEmpty && buy.isEmpty;
}
