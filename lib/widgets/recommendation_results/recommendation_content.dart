import 'package:flutter/material.dart';
import 'package:watch_next/widgets/recommendation_results/action_buttons.dart';
import 'package:watch_next/widgets/recommendation_results/navigation_buttons.dart';
import 'package:watch_next/widgets/recommendation_results/streaming_info_widget.dart';
import 'package:watch_next/widgets/shared/movie_poster_widget.dart';

class RecommendationContent extends StatelessWidget {
  final String posterPath;
  final List<int>? watchProviders;
  final Future<dynamic> servicesList;
  final int currentIndex;
  final int totalCount;
  final int mediaType;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onInfoPressed;
  final VoidCallback onReloadPressed;
  final VoidCallback? onWatchlistPressed;
  final bool isInWatchlist;

  const RecommendationContent({
    super.key,
    required this.posterPath,
    required this.watchProviders,
    required this.servicesList,
    required this.currentIndex,
    required this.totalCount,
    required this.mediaType,
    required this.onPrevious,
    required this.onNext,
    required this.onInfoPressed,
    required this.onReloadPressed,
    this.onWatchlistPressed,
    this.isInWatchlist = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: MoviePosterWidget(poster: posterPath),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamingInfoWidget(
              watchProviders: watchProviders,
              servicesList: servicesList,
            ),
            const SizedBox(width: 16),
            ActionButtons(
              showReloadButton: currentIndex == totalCount - 1,
              onReloadPressed: onReloadPressed,
              onWatchlistPressed: onWatchlistPressed,
              isInWatchlist: isInWatchlist,
              mediaType: mediaType,
            ),
          ],
        ),
        const SizedBox(height: 12),
        NavigationButtons(
          currentIndex: currentIndex,
          totalCount: totalCount,
          onPrevious: onPrevious,
          onNext: onNext,
          onInfoPressed: onInfoPressed,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
