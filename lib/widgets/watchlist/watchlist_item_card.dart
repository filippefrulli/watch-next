import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/pages/media_detail_page.dart';

class WatchlistItemCard extends StatelessWidget {
  final WatchlistItem item;
  final List<int> userServiceIds;
  final VoidCallback onRemove;

  const WatchlistItemCard({
    super.key,
    required this.item,
    required this.userServiceIds,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.isAvailable(userServiceIds);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildPoster(),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfo(isAvailable),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.grey[400],
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: item.posterPath != null
          ? CachedNetworkImage(
              imageUrl: 'https://image.tmdb.org/t/p/w200${item.posterPath}',
              width: 60,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 60,
                height: 90,
                color: Colors.grey[800],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 60,
                height: 90,
                color: Colors.grey[800],
                child: const Icon(
                  Icons.movie,
                  color: Colors.white,
                ),
              ),
            )
          : Container(
              width: 60,
              height: 90,
              color: Colors.grey[800],
              child: const Icon(
                Icons.movie,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildInfo(bool isAvailable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          item.isMovie ? 'movie'.tr() : 'tv_show'.tr(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _buildAvailabilityBadge(isAvailable),
      ],
    );
  }

  Widget _buildAvailabilityBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAvailable ? Colors.green : Colors.grey[600]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.info,
            size: 14,
            color: isAvailable ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'available'.tr() : 'not_available'.tr(),
            style: TextStyle(
              color: isAvailable ? Colors.green : Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
