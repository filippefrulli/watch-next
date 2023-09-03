import 'dart:convert';
import 'dart:developer';
import 'dart:io';
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

class HttpService {
  final String apiKey = tmdbApiKey;

  String thumbnail = "https://i.ytimg.com//vi//d_m5csmrf7I//hqdefault.jpg";

  final String baseUrl = 'https://www.youtube.com/watch?v=';

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

  Future<SeriesResults> findShowByTitle(http.Client client, String title, String year) async {
    var response = await client.get(
      Uri.https('api.themoviedb.org', '/3/search/tv', {
        'api_key': apiKey,
        'language': 'en-US',
        'query': title,
        'first_air_date_year': year,
        'include_adult': 'true',
      }),
    );

    if (response.statusCode != 200) {
      return SeriesResults();
    }
    SeriesSearchResults? searchResults = SeriesSearchResults.fromJson(jsonDecode(response.body));

    if (searchResults.results!.isNotEmpty) {
      return searchResults.results![0];
    }
    return SeriesResults();
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

  Future<SeriesDetails> fetchSeriesDetails(http.Client client, int id) async {
    final response = await client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/tv/$id',
        {'api_key': apiKey, 'language': 'en-US'},
      ),
    );

    SeriesDetails details = SeriesDetails.fromJson(jsonDecode(response.body));

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

  Future<List<int>> getWatchProvidersSeries(http.Client client, int id) async {
    final response = await client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/tv/$id/watch/providers',
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

  Future<MovieCredits> fetchMovieCredits(http.Client client, int id) async {
    final response = await client.get(
      Uri.https(
        'api.themoviedb.org',
        '/3/movie/$id/credits',
        {'api_key': apiKey},
      ),
    );

    MovieCredits credits = MovieCredits.fromJson(jsonDecode(response.body));

    return credits;
  }

  Future<List<TrailerResults>> fetchTrailer(http.Client client, int id) async {
    List<TrailerResults> trailerList = [];

    final response = await client.get(
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

  Future<List<TrailerResults>> fetchTrailerSeries(http.Client client, int id) async {
    List<TrailerResults> trailerList = [];

    final response = await client.get(
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
      return null;
    }
  }
}
