import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:watch_next/services/feedback_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/widgets/feedback_dialog.dart';

class SearchMediaPage extends StatefulWidget {
  const SearchMediaPage({super.key});

  @override
  State<SearchMediaPage> createState() => _SearchMediaPageState();
}

class _SearchMediaPageState extends State<SearchMediaPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<MultiSearchResult> _searchResults = [];
  String _errorMessage = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'media_search',
        parameters: <String, Object>{
          'query': query,
        },
      );

      final results = await HttpService().multiSearch(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'search_error'.tr();
      });

      FirebaseAnalytics.instance.logEvent(
        name: 'search_error',
        parameters: <String, Object>{
          'error': e.toString(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'search_for_media'.tr(),
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _errorMessage = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    // Debounce search - wait for user to stop typing
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _performSearch(value);
                      }
                    });
                  },
                  onSubmitted: _performSearch,
                ),
              ),
            ),

            // Results area
            Expanded(
              child: _buildResultsArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              'searching'.tr(),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_outlined,
                color: Colors.grey[700],
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                'search_media_description'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                ),
              )
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                color: Colors.grey[700],
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'no_results_found'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'try_something_else'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Display search results in a list
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultCard(result);
      },
    );
  }

  Widget _buildSearchResultCard(MultiSearchResult result) {
    return _SearchResultCard(result: result);
  }
}

class _SearchResultCard extends StatefulWidget {
  final MultiSearchResult result;

  const _SearchResultCard({required this.result});

  @override
  State<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<_SearchResultCard> {
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
          Fluttertoast.showToast(
            msg: 'removed_from_watchlist'.tr(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            textColor: Colors.white,
          );
        }
      } else {
        await _watchlistService.addToWatchlist(
          mediaId: widget.result.id,
          title: widget.result.displayTitle,
          isMovie: widget.result.isMovie,
          posterPath: widget.result.posterPath,
          context: context,
        );
        if (mounted) {
          setState(() => _isInWatchlist = true);
          Fluttertoast.showToast(
            msg: 'added_to_watchlist'.tr(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
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
                onTap: () async {
                  FirebaseAnalytics.instance.logEvent(
                    name: 'search_result_tapped',
                    parameters: <String, Object>{
                      'id': result.id,
                      'title': result.displayTitle,
                      'media_type': result.mediaType,
                    },
                  );

                  // Increment successful query counter for feedback system
                  await FeedbackService.incrementSuccessfulQuery();

                  // Navigate to detail page and check for feedback dialog when returning
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaDetailPage(
                        mediaId: result.id,
                        title: result.displayTitle,
                        isMovie: result.isMovie,
                        posterPath: result.posterPath,
                      ),
                    ),
                  );

                  // After returning from detail page, check if we should show feedback dialog
                  if (mounted) {
                    final shouldShow = await FeedbackService.shouldShowFeedbackDialog();
                    if (shouldShow && mounted) {
                      // Show dialog after user returns to search screen
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const FeedbackDialog(),
                          );
                        }
                      });
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: result.posterPath != null
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w200${result.posterPath}',
                                width: 60,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderPoster();
                                },
                              )
                            : _buildPlaceholderPoster(),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              result.displayTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Media type badge and year
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: result.isMovie ? Colors.orange : Colors.blue,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    result.isMovie ? 'movie'.tr() : 'tv_show'.tr(),
                                    style: TextStyle(
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
                                  Icon(
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Watchlist button
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

  Widget _buildPlaceholderPoster() {
    return Container(
      width: 60,
      height: 90,
      color: Theme.of(context).colorScheme.tertiary,
      child: Icon(
        Icons.movie_outlined,
        color: Colors.grey[600],
        size: 32,
      ),
    );
  }
}
