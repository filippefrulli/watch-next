import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:watch_next/secrets.dart';
import 'objects/search_results.dart';
import 'objects/movie_details.dart';

class HttpService {
  final String apiKey = tmdbApiKey;

  fetchRecommendedMovies(http.Client client, String title) async {
    List<Results>? list = [];

    var response = await client.get(
      Uri.https('api.themoviedb.org', '/3/search/movie', {'api_key': apiKey, 'language': 'en-US', 'query': title}),
    );

    if (response.statusCode != 200) {
      return [];
    }
    SearchResults? searchResults = SearchResults.fromJson(jsonDecode(response.body));

    list = searchResults.results;

    return list;
  }

  fetchSimilarMovies(http.Client client, int? id) async {
    List<Results>? list = [];

    var response = await client.get(
      Uri.https('api.themoviedb.org', '/3/movie/$id/similar', {'api_key': apiKey, 'language': 'en-US', 'page': '1'}),
    );

    if (response.statusCode != 200) {
      return [];
    } else {
      var response2 = await client.get(
        Uri.https('api.themoviedb.org', '/3/movie/$id/similar', {'api_key': apiKey, 'language': 'en-US', 'page': '2'}),
      );

      SearchResults? searchResults = SearchResults.fromJson(jsonDecode(response.body));

      SearchResults? searchResults2 = SearchResults.fromJson(jsonDecode(response2.body));

      list = searchResults.results;
      list = list! + searchResults2.results!;

      return list;
    }
  }

  fetchMovieDetails(http.Client client, int id) async {
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

  // static fetchTvDetails(http.Client client, int id) async {

  //   final response = await client.get(
  //     Uri.https(
  //       'api.themoviedb.org',
  //       '/3/tv/$id',
  //       {'api_key': apiKey, 'language': 'en-US'},
  //     ),
  //   );

  //   TvShowDetails details = TvShowDetails.fromJson(jsonDecode(response.body));

  //   return details;
  // }
}
