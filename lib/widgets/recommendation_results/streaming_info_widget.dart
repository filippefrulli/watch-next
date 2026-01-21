import 'package:cached_network_image/cached_network_image.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/objects/streaming_service.dart';

class StreamingInfoWidget extends StatelessWidget {
  final List<int>? watchProviders;
  final Future<dynamic> servicesList;
  final bool isRentOnly;
  final bool isBuyOnly;

  const StreamingInfoWidget({
    super.key,
    required this.watchProviders,
    required this.servicesList,
    this.isRentOnly = false,
    this.isBuyOnly = false,
  });

  String _getAvailabilityLabel() {
    if (isRentOnly && isBuyOnly) {
      return "rent_buy_on".tr();
    } else if (isRentOnly) {
      return "rent_on".tr();
    } else if (isBuyOnly) {
      return "buy_on".tr();
    }
    return "stream_it_on".tr();
  }

  @override
  Widget build(BuildContext context) {
    if (watchProviders == null || watchProviders!.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _getAvailabilityLabel(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          _streamingLogo(),
        ],
      ),
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
          return DelayedDisplay(
            delay: const Duration(milliseconds: 800),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 56,
                  width: 56,
                  child: _buildStreamingImage(snapshot.data),
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
            color: Theme.of(context).colorScheme.primary,
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
