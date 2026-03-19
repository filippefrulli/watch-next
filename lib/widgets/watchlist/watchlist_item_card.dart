import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/pages/media_detail_page.dart';

class WatchlistItemCard extends StatelessWidget {
  final WatchlistItem item;
  final List<int> userServiceIds;
  final Map<int, String> userServicesMap;
  final VoidCallback onRemove;
  final VoidCallback? onMarkWatched;

  const WatchlistItemCard({
    super.key,
    required this.item,
    required this.userServiceIds,
    required this.userServicesMap,
    required this.onRemove,
    this.onMarkWatched,
  });

  @override
  Widget build(BuildContext context) {
    final streamingIds = item.availability['streaming'] ?? [];
    final matchedLogos =
        streamingIds.where((id) => userServicesMap.containsKey(id)).map((id) => userServicesMap[id]!).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: ValueKey(item.mediaId),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          if (onMarkWatched != null) {
            onMarkWatched!();
          }
          // Don't auto-dismiss — we handle removal in the callback after rating
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(
                'mark_watched'.tr(),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaDetailPage(
                        mediaId: item.mediaId,
                        title: item.title,
                        isMovie: item.isMovie,
                        posterPath: item.posterPath,
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPoster(context),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 8, 8),
                              child: _buildInfo(matchedLogos),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(11),
        bottomLeft: Radius.circular(11),
      ),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: item.posterPath != null
            ? CachedNetworkImage(
                imageUrl: 'https://image.tmdb.org/t/p/w200${item.posterPath}',
                fit: BoxFit.fill,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.movie_outlined, color: Colors.grey[600], size: 24),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.movie_outlined, color: Colors.grey[600], size: 24),
                ),
              )
            : Container(
                color: Theme.of(context).colorScheme.primary,
                child: Icon(Icons.movie_outlined, color: Colors.grey[600], size: 24),
              ),
      ),
    );
  }

  Widget _buildInfo(List<String> matchedLogos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            item.isMovie ? 'movie'.tr() : 'tv_show'.tr(),
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            ..._buildStreamingLogos(matchedLogos),
            const Spacer(),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildStreamingLogos(List<String> logoPaths) {
    if (logoPaths.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[600]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                'not_available'.tr(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return logoPaths.take(4).map((logoPath) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: 'https://image.tmdb.org/t/p/original/$logoPath',
            width: 47,
            height: 47,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 47,
              height: 47,
              color: Colors.grey[800],
            ),
            errorWidget: (_, __, ___) => Container(
              width: 47,
              height: 47,
              color: Colors.grey[800],
              child: const Icon(Icons.tv, size: 20, color: Colors.grey),
            ),
          ),
        ),
      );
    }).toList();
  }
}
