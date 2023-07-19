class Trailer {
  int? id;
  List<TrailerResults>? results;

  Trailer({this.id, this.results});

  Trailer.fromJson(Map<dynamic, dynamic> json) {
    id = json['id'];
    if (json['results'] != null) {
      results = <TrailerResults>[];
      json['results'].forEach((v) {
        results!.add(TrailerResults.fromJson(v));
      });
    }
  }

  Map<dynamic, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (results != null) {
      data['results'] = results!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TrailerResults {
  String? id;
  String? iso6391;
  String? iso31661;
  String? key;
  String? name;
  String? site;
  int? size;
  String? type;

  TrailerResults({this.id, this.iso6391, this.iso31661, this.key, this.name, this.site, this.size, this.type});

  TrailerResults.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    iso6391 = json['iso_639_1'];
    iso31661 = json['iso_3166_1'];
    key = json['key'];
    name = json['name'];
    site = json['site'];
    size = json['size'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['iso_639_1'] = iso6391;
    data['iso_3166_1'] = iso31661;
    data['key'] = key;
    data['name'] = name;
    data['site'] = site;
    data['size'] = size;
    data['type'] = type;
    return data;
  }
}
