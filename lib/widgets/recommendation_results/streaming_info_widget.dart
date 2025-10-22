import 'package:cached_network_image/cached_network_image.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/objects/streaming_service.dart';

class StreamingInfoWidget extends StatelessWidget {
  final List<int>? watchProviders;
  final Future<dynamic> servicesList;

  const StreamingInfoWidget({
    super.key,
    required this.watchProviders,
    required this.servicesList,
  });

  @override
  Widget build(BuildContext context) {
    if (watchProviders == null || watchProviders!.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "watch_it_on".tr(),
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 4),
        _streamingLogo(),
      ],
    );
  }

  Widget _streamingLogo() {
    return FutureBuilder(
      future: servicesList,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 32),
          );
        }

        if (snapshot.hasData && snapshot.data.length > 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DelayedDisplay(
              delay: const Duration(milliseconds: 1000),
              child: SizedBox(
                height: 64,
                width: 64,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildStreamingImage(snapshot.data),
                  ),
                ),
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget _buildStreamingImage(List<StreamingService> streamingList) {
    for (StreamingService item in streamingList) {
      if (item.providerId == watchProviders!.first) {
        return CachedNetworkImage(
          fit: BoxFit.fill,
          imageUrl: "https://image.tmdb.org/t/p/original//${item.logoPath}",
          placeholder: (context, url) => Container(
            color: const Color.fromRGBO(11, 14, 23, 1),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey,
          ),
        );
      }
    }
    return Container();
  }
}
