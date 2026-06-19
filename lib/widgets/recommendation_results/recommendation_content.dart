import 'package:flutter/material.dart';
import 'package:watch_next/utils/constants.dart';
import 'package:watch_next/widgets/recommendation_results/action_buttons.dart';
import 'package:watch_next/widgets/recommendation_results/streaming_info_widget.dart';
import 'package:watch_next/widgets/shared/movie_poster_widget.dart';

class RecommendationContent extends StatelessWidget {
  final String posterPath;
  final String? overview;
  final List<int>? genreIds;
  final String? imdbRating;
  final List<int>? watchProviders;
  final Future<dynamic> servicesList;
  final int currentIndex;
  final int totalCount;
  final int mediaType;
  final VoidCallback onReloadPressed;
  final VoidCallback? onWatchlistPressed;
  final bool isInWatchlist;
  final bool isWatched;
  final int? watchedRating;
  final VoidCallback? onWatchedPressed;
  final VoidCallback? onNotInterestedPressed;
  final bool isNotInterested;
  final bool isRentOnly;
  final bool isBuyOnly;
  final VoidCallback? onProviderTap;

  const RecommendationContent({
    super.key,
    required this.posterPath,
    this.overview,
    this.genreIds,
    this.imdbRating,
    required this.watchProviders,
    required this.servicesList,
    required this.currentIndex,
    required this.totalCount,
    required this.mediaType,
    required this.onReloadPressed,
    this.onWatchlistPressed,
    this.isInWatchlist = false,
    this.isWatched = false,
    this.watchedRating,
    this.onWatchedPressed,
    this.onNotInterestedPressed,
    this.isNotInterested = false,
    this.isRentOnly = false,
    this.isBuyOnly = false,
    this.onProviderTap,
  });

  @override
  Widget build(BuildContext context) {
    final genres = genreIds?.map((id) => genreNames[id]).whereType<String>().take(3).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: MoviePosterWidget(poster: posterPath),
        ),
        const SizedBox(height: 12),
        if (imdbRating != null || genres.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (imdbRating != null) _ImdbBadge(rating: imdbRating!),
                ...genres.map((g) => _GenreChip(label: g)),
              ],
            ),
          ),
        if (imdbRating != null || genres.isNotEmpty) const SizedBox(height: 8),
        if (overview != null && overview!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              overview!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
            ),
          ),
        if (overview != null && overview!.isNotEmpty) const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamingInfoWidget(
                watchProviders: watchProviders,
                servicesList: servicesList,
                isRentOnly: isRentOnly,
                isBuyOnly: isBuyOnly,
                onTap: onProviderTap,
              ),
              const SizedBox(width: 8),
              ActionButtons(
                showReloadButton: currentIndex == totalCount - 1,
                onReloadPressed: onReloadPressed,
                onWatchlistPressed: onWatchlistPressed,
                isInWatchlist: isInWatchlist,
                onWatchedPressed: onWatchedPressed,
                onNotInterestedPressed: onNotInterestedPressed,
                isNotInterested: isNotInterested,
                isWatched: isWatched,
                watchedRating: watchedRating,
                mediaType: mediaType,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ImdbBadge extends StatelessWidget {
  final String rating;
  const _ImdbBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C518),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'IMDb',
            style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 5),
          Text(
            rating,
            style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  const _GenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
