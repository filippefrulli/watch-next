import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/widgets/recommendation_results/trailer_list_widget.dart';

class MovieInfoPanel extends StatefulWidget {
  final int mediaId;
  final String title;
  final String overview;
  final double? tmdbRating;
  final bool isMovie;
  final String? posterPath;
  final List<TrailerResults> trailerList;
  final List<String> trailerImages;
  final Function(String) onTrailerTap;

  const MovieInfoPanel({
    super.key,
    required this.mediaId,
    required this.title,
    required this.overview,
    required this.tmdbRating,
    required this.isMovie,
    this.posterPath,
    required this.trailerList,
    required this.trailerImages,
    required this.onTrailerTap,
  });

  @override
  State<MovieInfoPanel> createState() => _MovieInfoPanelState();
}

class _MovieInfoPanelState extends State<MovieInfoPanel> {
  final WatchlistService _watchlistService = WatchlistService();
  bool _isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    _checkIfInWatchlist();
  }

  @override
  void didUpdateWidget(MovieInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _checkIfInWatchlist();
    }
  }

  Future<void> _checkIfInWatchlist() async {
    final inWatchlist = await _watchlistService.isInWatchlist(widget.mediaId);
    if (mounted) {
      setState(() {
        _isInWatchlist = inWatchlist;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    try {
      if (_isInWatchlist) {
        await _watchlistService.removeFromWatchlist(widget.mediaId);
        if (mounted) {
          setState(() => _isInWatchlist = false);
          Fluttertoast.showToast(
            msg: 'removed_from_watchlist'.tr(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.grey[850],
            textColor: Colors.white,
          );
        }
      } else {
        await _watchlistService.addToWatchlist(
          mediaId: widget.mediaId,
          title: widget.title,
          isMovie: widget.isMovie,
          posterPath: widget.posterPath,
        );
        if (mounted) {
          setState(() => _isInWatchlist = true);
          Fluttertoast.showToast(
            msg: 'added_to_watchlist'.tr(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.grey[850],
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      print('Error toggling watchlist: $e');
    }
  }

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
                              widget.title,
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
                      const SizedBox(height: 12),
                      // Watchlist button
                      Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _toggleWatchlist,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _isInWatchlist ? Colors.orange.withOpacity(0.2) : Colors.grey[850],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isInWatchlist ? Colors.orange : Colors.grey[700]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                                    color: _isInWatchlist ? Colors.orange : Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isInWatchlist ? 'remove_from_watchlist'.tr() : 'add_to_watchlist'.tr(),
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          fontSize: 14,
                                          color: _isInWatchlist ? Colors.orange : Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                        widget.overview,
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
                              (widget.tmdbRating?.toStringAsFixed(1) ?? ''),
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
                        trailerList: widget.trailerList,
                        trailerImages: widget.trailerImages,
                        onTrailerTap: widget.onTrailerTap,
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
