class ResultProviders {
  List<StreamingService>? results;

  ResultProviders({this.results});

  ResultProviders.fromJson(Map<String, dynamic> json) {
    if (json['results'] != null) {
      results = <StreamingService>[];
      json['results'].forEach((v) {
        results!.add(StreamingService.fromJson(v));
      });
    }
  }
}

class StreamingService {
  int? displayPriority;
  String? logoPath;
  String? providerName;
  int? providerId;

  StreamingService({this.displayPriority, this.logoPath, this.providerName, this.providerId});

  factory StreamingService.fromJson(Map<String, dynamic> json) {
    return StreamingService(
      displayPriority: json['display_priority'],
      logoPath: json['logo_path'],
      providerName: json['provider_name'],
      providerId: json['provider_id'],
    );
  }
}
