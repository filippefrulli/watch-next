import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/widgets/recommendation_results/trailer_list_widget.dart';

class MovieInfoPanel extends StatelessWidget {
  final String title;
  final String overview;
  final double? tmdbRating;
  final List<TrailerResults> trailerList;
  final List<String> trailerImages;
  final Function(String) onTrailerTap;

  const MovieInfoPanel({
    super.key,
    required this.title,
    required this.overview,
    required this.tmdbRating,
    required this.trailerList,
    required this.trailerImages,
    required this.onTrailerTap,
  });

  @override
  Widget build(BuildContext context) {
    return DelayedDisplay(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromRGBO(11, 14, 23, 1),
              Colors.grey[900]!.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Column(
          children: [
            // Drag handle - stays at top, not scrollable
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Container()),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: Text(
                              title,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                            ),
                          ),
                          Expanded(child: Container()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.orange.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        overview,
                        maxLines: 17,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "tmdb_score".tr(),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontSize: 14,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (tmdbRating?.toStringAsFixed(1) ?? ''),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: Colors.grey[800]),
                      const SizedBox(height: 8),
                      TrailerListWidget(
                        trailerList: trailerList,
                        trailerImages: trailerImages,
                        onTrailerTap: onTrailerTap,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
