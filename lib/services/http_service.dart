import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/streaming_service.dart';
import 'package:watch_next/objects/watch_providers.dart';
import 'package:watch_next/utils/secrets.dart';
import '../objects/search_results.dart';
import '../objects/movie_details.dart';
import 'database_service.dart';

class HttpService {
  final String apiKey = tmdbApiKey;

  Future<Results> findMovieByTitle(http.Client client, String title, String year) async {
    var response = await client.get(
      Uri.https('api.themoviedb.org', '/3/search/movie', {
        'api_key': apiKey,
        'language': 'en-US',
        'query': title,
        'year': year,
      }),
    );

    if (response.statusCode != 200) {
      return Results();
    }
    SearchResults? searchResults = SearchResults.fromJson(jsonDecode(response.body));

    if (searchResults.results!.isNotEmpty) {
      return searchResults.results![0];
    }
    return Results();
  }

  Future<MovieDetails> fetchMovieDetails(http.Client client, int id) async {
    final response = await client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/movie/$id',
        {'api_key': apiKey, 'language': 'en-US'},
      ),
    );

    MovieDetails details = MovieDetails.fromJson(jsonDecode(response.body));

    return details;
  }

  Future<List<int>> getWatchProviders(http.Client client, int id) async {
    final response = await client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/movie/$id/watch/providers',
        {'api_key': apiKey, 'language': 'en-US'},
      ),
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String region = prefs.getString('region') ?? 'DE';

    List<String> providers = jsonDecode(response.body)["results"].keys.toList();

    List<int> movieProvidersIds = [];

    if (providers.contains(region)) {
      List<int> myProvidersIds = await DatabaseService.getStreamingServicesIds();

      ProviderRegion provider = ProviderRegion.fromJson(jsonDecode(response.body)["results"][region]);
      if (provider.flatrate != null) {
        for (StreamingType item in provider.flatrate!) {
          if (myProvidersIds.contains(item.providerId)) {
            movieProvidersIds.add(item.providerId!);
          }
        }
      }
    }

    return movieProvidersIds;
  }

  Future<List<StreamingService>> getWatchProvidersByLocale(http.Client client) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String region = prefs.getString('region') ?? 'DE';
    final response = await client.get(
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
      (item) => item.displayPriority! > 10,
    );

    List<StreamingService> resultList = providers.results!;
    if (Platform.isIOS) {
      resultList.removeWhere(
        (item) => item.providerId == 337,
      );
    }
    return resultList;
  }
}
