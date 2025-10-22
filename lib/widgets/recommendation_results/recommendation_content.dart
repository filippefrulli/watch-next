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
  final VoidCallback onAccept;
  final VoidCallback onInfoPressed;
  final VoidCallback onReloadPressed;

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
    required this.onAccept,
    required this.onInfoPressed,
    required this.onReloadPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Expanded(
            flex: 20,
            child: Container(
              color: const Color.fromRGBO(11, 14, 23, 1),
              child: MoviePosterWidget(poster: posterPath),
            ),
          ),
          Expanded(flex: 1, child: Container()),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(child: Container()),
                StreamingInfoWidget(
                  watchProviders: watchProviders,
                  servicesList: servicesList,
                ),
                Expanded(child: Container()),
                ActionButtons(
                  showReloadButton: currentIndex == totalCount - 1,
                  onInfoPressed: onInfoPressed,
                  onReloadPressed: onReloadPressed,
                  mediaType: mediaType,
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
          Expanded(flex: 1, child: Container()),
          Expanded(
            flex: 2,
            child: NavigationButtons(
              currentIndex: currentIndex,
              totalCount: totalCount,
              onPrevious: onPrevious,
              onNext: onNext,
              onAccept: onAccept,
            ),
          ),
          Expanded(flex: 1, child: Container()),
        ],
      ),
    );
  }
}
