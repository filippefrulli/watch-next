class WatchProviders {
  int? id;
  // ignore: prefer_typing_uninitialized_variables
  var results;

  WatchProviders({this.id, this.results});
}

class ProviderRegion {
  String? link;
  List<StreamingType>? flatrate;
  List<StreamingType>? rent;
  List<StreamingType>? buy;

  ProviderRegion({this.link, this.flatrate, this.rent, this.buy});

  ProviderRegion.fromJson(Map<String, dynamic> json) {
    link = json['link'];
    if (json['flatrate'] != null) {
      flatrate = <StreamingType>[];
      json['flatrate'].forEach((v) {
        flatrate!.add(StreamingType.fromJson(v));
      });
    }
    if (json['rent'] != null) {
      rent = <StreamingType>[];
      json['rent'].forEach((v) {
        rent!.add(StreamingType.fromJson(v));
      });
    }
    if (json['buy'] != null) {
      buy = <StreamingType>[];
      json['buy'].forEach((v) {
        buy!.add(StreamingType.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['link'] = link;
    if (flatrate != null) {
      data['flatrate'] = flatrate!.map((v) => v.toJson()).toList();
    }
    if (rent != null) {
      data['rent'] = rent!.map((v) => v.toJson()).toList();
    }
    if (buy != null) {
      data['buy'] = buy!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class StreamingType {
  int? displayPriority;
  String? logoPath;
  int? providerId;
  String? providerName;

  StreamingType({this.displayPriority, this.logoPath, this.providerId, this.providerName});

  StreamingType.fromJson(Map<String, dynamic> json) {
    displayPriority = json['display_priority'];
    logoPath = json['logo_path'];
    providerId = json['provider_id'];
    providerName = json['provider_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['display_priority'] = displayPriority;
    data['logo_path'] = logoPath;
    data['provider_id'] = providerId;
    data['provider_name'] = providerName;
    return data;
  }
}
