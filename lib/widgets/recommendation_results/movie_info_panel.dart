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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(width: 50, height: 5, color: Colors.grey[800]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container()),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(
              overview,
              maxLines: 17,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(
              "tmdb_score".tr() + (tmdbRating?.toStringAsFixed(1) ?? ''),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.grey[800]),
            const SizedBox(height: 8),
            TrailerListWidget(
              trailerList: trailerList,
              trailerImages: trailerImages,
              onTrailerTap: onTrailerTap,
            ),
          ],
        ),
      ),
    );
  }
}
