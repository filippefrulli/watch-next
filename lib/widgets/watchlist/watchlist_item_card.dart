import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/ratings_service.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:watch_next/utils/app_colors.dart';

class WatchlistItemCard extends StatefulWidget {
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
  State<WatchlistItemCard> createState() => _WatchlistItemCardState();
}

class _WatchlistItemCardState extends State<WatchlistItemCard> {
  String? _imdbRating;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
      String? imdbId;
      if (widget.item.isMovie) {
        imdbId = (await HttpService().fetchMovieDetails(widget.item.mediaId)).imdbId;
      } else {
        imdbId = await HttpService().fetchSeriesImdbId(widget.item.mediaId);
      }
      final ratings = await RatingsService.fetchByImdbId(imdbId);
      if (mounted && ratings.imdb != null) {
        setState(() => _imdbRating = ratings.imdb);
      }
    } catch (_) {
      // Rating is optional — leave it hidden on any failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final userServicesMap = widget.userServicesMap;
    final onMarkWatched = widget.onMarkWatched;
    final streamingIds = item.availability['streaming'] ?? [];
    final matchedLogos =
        streamingIds.where((id) => userServicesMap.containsKey(id)).map((id) => userServicesMap[id]!).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: ValueKey(item.mediaId),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right → mark watched.
            if (onMarkWatched != null) {
              onMarkWatched();
            }
          } else {
            // Swipe left → remove. The Firestore deletion drives the stream,
            // which animates the card out, so we don't auto-dismiss here.
            widget.onRemove();
          }
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
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'remove'.tr(),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.delete_outline, color: Colors.red, size: 28),
            ],
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.border, width: 1),
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
        child: widget.item.posterPath != null
            ? CachedNetworkImage(
                imageUrl: 'https://image.tmdb.org/t/p/w200${widget.item.posterPath}',
                fit: BoxFit.fill,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.movie_outlined, color: context.appColors.textTertiary, size: 24),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.movie_outlined, color: context.appColors.textTertiary, size: 24),
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
            widget.item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: context.appColors.surface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.item.isMovie ? 'movie'.tr() : 'tv_show'.tr(),
                style: TextStyle(color: context.appColors.textSecondary, fontSize: 11),
              ),
            ),
            if (_imdbRating != null) ...[
              const SizedBox(width: 6),
              _buildImdbBadge(_imdbRating!),
            ],
          ],
        ),
        const Spacer(),
        Row(
          children: [
            ..._buildStreamingLogos(matchedLogos),
          ],
        ),
      ],
    );
  }

  Widget _buildImdbBadge(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C518),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'IMDb',
            style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          Text(
            rating,
            style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStreamingLogos(List<String> logoPaths) {
    if (logoPaths.isEmpty) {
      return [
        Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.appColors.surface2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: context.appColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'not_available'.tr(),
                  style: TextStyle(
                    color: context.appColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
            placeholder: (ctx, __) => Container(
              width: 47,
              height: 47,
              color: ctx.appColors.surface,
            ),
            errorWidget: (ctx, __, ___) => Container(
              width: 47,
              height: 47,
              color: ctx.appColors.surface,
              child: const Icon(Icons.tv, size: 20, color: Colors.grey),
            ),
          ),
        ),
      );
    }).toList();
  }
}
