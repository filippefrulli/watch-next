class PersonDetails {
  int? id;
  String? name;
  String? biography;
  String? birthday;
  String? deathday;
  String? placeOfBirth;
  String? profilePath;
  String? knownForDepartment;
  double? popularity;

  PersonDetails({
    this.id,
    this.name,
    this.biography,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    this.profilePath,
    this.knownForDepartment,
    this.popularity,
  });

  PersonDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    biography = json['biography'];
    birthday = json['birthday'];
    deathday = json['deathday'];
    placeOfBirth = json['place_of_birth'];
    profilePath = json['profile_path'];
    knownForDepartment = json['known_for_department'];
    popularity = (json['popularity'] as num?)?.toDouble();
  }
}

class PersonCredit {
  int? id;
  String? title; // movies
  String? name; // tv shows
  String? posterPath;
  String? mediaType; // 'movie' or 'tv'
  String? releaseDate; // movies
  String? firstAirDate; // tv shows
  double? voteAverage;
  String? character; // cast credits
  String? job; // crew credits

  PersonCredit({
    this.id,
    this.title,
    this.name,
    this.posterPath,
    this.mediaType,
    this.releaseDate,
    this.firstAirDate,
    this.voteAverage,
    this.character,
    this.job,
  });

  PersonCredit.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    name = json['name'];
    posterPath = json['poster_path'];
    mediaType = json['media_type'];
    releaseDate = json['release_date'];
    firstAirDate = json['first_air_date'];
    voteAverage = (json['vote_average'] as num?)?.toDouble();
    character = json['character'];
    job = json['job'];
  }

  String get displayTitle => title ?? name ?? '';
  String get displayDate => releaseDate ?? firstAirDate ?? '';
  bool get isMovie => mediaType == 'movie';
}

class PersonCredits {
  List<PersonCredit> cast;
  List<PersonCredit> crew;

  PersonCredits({required this.cast, required this.crew});

  PersonCredits.fromJson(Map<String, dynamic> json)
      : cast = (json['cast'] as List? ?? []).map((e) => PersonCredit.fromJson(e as Map<String, dynamic>)).toList(),
        crew = (json['crew'] as List? ?? []).map((e) => PersonCredit.fromJson(e as Map<String, dynamic>)).toList();
}
