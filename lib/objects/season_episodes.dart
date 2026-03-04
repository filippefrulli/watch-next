class SeasonEpisodes {
  int? id;
  String? name;
  String? overview;
  String? posterPath;
  int? seasonNumber;
  List<Episode>? episodes;

  SeasonEpisodes({this.id, this.name, this.overview, this.posterPath, this.seasonNumber, this.episodes});

  SeasonEpisodes.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    overview = json['overview'];
    posterPath = json['poster_path'];
    seasonNumber = json['season_number'];
    if (json['episodes'] != null) {
      episodes = <Episode>[];
      for (final v in json['episodes'] as List) {
        episodes!.add(Episode.fromJson(v as Map<String, dynamic>));
      }
    }
  }
}

class Episode {
  int? id;
  int? episodeNumber;
  String? name;
  String? overview;
  int? runtime;
  String? airDate;
  double? voteAverage;

  Episode({this.id, this.episodeNumber, this.name, this.overview, this.runtime, this.airDate, this.voteAverage});

  Episode.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    episodeNumber = json['episode_number'];
    name = json['name'];
    overview = json['overview'];
    runtime = (json['runtime'] as num?)?.toInt();
    airDate = json['air_date'];
    voteAverage = (json['vote_average'] as num?)?.toDouble();
  }
}
