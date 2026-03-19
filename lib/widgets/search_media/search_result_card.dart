import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:watch_next/pages/person_detail_page.dart';
import 'package:watch_next/services/feedback_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/widgets/feedback_dialog.dart';

class SearchResultCard extends StatefulWidget {
  final MultiSearchResult result;

  const SearchResultCard({
    super.key,
    required this.result,
  });

  @override
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard> {
  final WatchlistService _watchlistService = WatchlistService();
  bool _isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    _checkIfInWatchlist();
  }

  Future<void> _checkIfInWatchlist() async {
    final inWatchlist = await _watchlistService.isInWatchlist(widget.result.id);
    if (mounted) {
      setState(() => _isInWatchlist = inWatchlist);
    }
  }

  Future<void> _toggleWatchlist() async {
    try {
      if (_isInWatchlist) {
        await _watchlistService.removeFromWatchlist(widget.result.id);
        if (mounted) {
          setState(() => _isInWatchlist = false);
        }
        // Track watchlist remove
        UserActionService.logWatchlistRemove(
          mediaId: widget.result.id,
          title: widget.result.displayTitle,
          type: widget.result.isMovie ? 'movie' : 'show',
        );
      } else {
        await _watchlistService.addToWatchlist(
          mediaId: widget.result.id,
          title: widget.result.displayTitle,
          isMovie: widget.result.isMovie,
          posterPath: widget.result.posterPath,
        );
        if (mounted) {
          setState(() => _isInWatchlist = true);
          FirebaseAnalytics.instance.logEvent(
            name: 'watchlist_added',
            parameters: <String, Object>{
              'source': 'search',
              'type': widget.result.isMovie ? 'movie' : 'show',
            },
          );
        }
        // Track watchlist add
        UserActionService.logWatchlistAdd(
          mediaId: widget.result.id,
          title: widget.result.displayTitle,
          type: widget.result.isMovie ? 'movie' : 'show',
          source: 'search',
        );
      }
    } catch (e) {
      // Handle errors if necessary
    }
  }

  Future<void> _onCardTap() async {
    final result = widget.result;

    if (result.isPerson) {
      UserActionService.logPersonTapped(
        personId: result.id,
        personName: result.displayTitle,
        role: result.knownForDepartment ?? 'unknown',
      );
      if (!mounted || !context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PersonDetailPage(
            personId: result.id,
            personName: result.displayTitle,
            profilePath: result.profilePath,
          ),
        ),
      );
      return;
    }

    FirebaseAnalytics.instance.logEvent(
      name: 'search_result_clicked',
      parameters: <String, Object>{
        'type': result.isMovie ? 'movie' : 'show',
      },
    );

    // Track search result selected
    UserActionService.logSearchResultSelected(
      mediaId: result.id,
      title: result.displayTitle,
      type: result.isMovie ? 'movie' : 'show',
      positionInList: 0, // Position not available in this context
    );

    await FeedbackService.incrementSuccessfulQuery();

    if (!mounted || !context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailPage(
          mediaId: widget.result.id,
          title: widget.result.displayTitle,
          isMovie: widget.result.isMovie,
          posterPath: widget.result.posterPath,
        ),
      ),
    );

    final shouldShow = await FeedbackService.shouldShowFeedbackDialog();
    if (shouldShow && mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const FeedbackDialog(),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _onCardTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPoster(result),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfo(result)),
                    ],
                  ),
                ),
              ),
            ),
            if (!result.isPerson)
              IconButton(
                icon: Icon(
                  _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                  color: _isInWatchlist ? Colors.orange : Colors.grey[400],
                ),
                onPressed: _toggleWatchlist,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(MultiSearchResult result) {
    final imagePath = result.isPerson ? result.profilePath : result.posterPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(result.isPerson ? 30 : 8),
      child: imagePath != null
          ? Image.network(
              'https://image.tmdb.org/t/p/w200$imagePath',
              width: 60,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderPoster(result.isPerson);
              },
            )
          : _buildPlaceholderPoster(result.isPerson),
    );
  }

  Widget _buildPlaceholderPoster(bool isPerson) {
    return Container(
      width: 60,
      height: 90,
      color: Theme.of(context).colorScheme.tertiary,
      child: Icon(
        isPerson ? Icons.person_outline : Icons.movie_outlined,
        color: Colors.grey[600],
        size: 32,
      ),
    );
  }

  Widget _buildInfo(MultiSearchResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.displayTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: result.isPerson ? Colors.purple : (result.isMovie ? Colors.orange : Colors.blue),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                result.isPerson
                    ? (result.knownForDepartment ?? 'person'.tr())
                    : (result.isMovie ? 'movie'.tr() : 'tv_show'.tr()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (result.year.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                result.year,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        if (result.voteAverage != null && result.voteAverage! > 0) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                result.voteAverage!.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
