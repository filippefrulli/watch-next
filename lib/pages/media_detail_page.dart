import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/objects/streaming_service.dart';

class MediaDetailPage extends StatefulWidget {
  final int mediaId;
  final String title;
  final bool isMovie;
  final String? posterPath;

  const MediaDetailPage({
    super.key,
    required this.mediaId,
    required this.title,
    required this.isMovie,
    this.posterPath,
  });

  @override
  State<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<MediaDetailPage> {
  final WatchlistService _watchlistService = WatchlistService();
  bool _isLoading = true;
  bool _isInWatchlist = false;
  List<StreamingService> _streamingProviders = [];
  List<StreamingService> _rentProviders = [];
  List<StreamingService> _buyProviders = [];
  List<int> _userServiceIds = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load user's streaming service IDs and check watchlist status
      _userServiceIds = await DatabaseService.getStreamingServicesIds();
      final inWatchlist = await _watchlistService.isInWatchlist(widget.mediaId);

      // Fetch categorized watch providers
      final categorizedProviders = await HttpService().getCategorizedWatchProviders(
        widget.mediaId,
        widget.isMovie,
      );

      setState(() {
        _isInWatchlist = inWatchlist;
        _streamingProviders = categorizedProviders.streaming;
        _rentProviders = categorizedProviders.rent;
        _buyProviders = categorizedProviders.buy;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'failed_load_streaming'.tr();
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    try {
      if (_isInWatchlist) {
        await _watchlistService.removeFromWatchlist(widget.mediaId);
        if (mounted) {
          setState(() => _isInWatchlist = false);
        }
        UserActionService.logWatchlistRemove(
          mediaId: widget.mediaId,
          title: widget.title,
          type: widget.isMovie ? 'movie' : 'show',
        );
      } else {
        await _watchlistService.addToWatchlist(
          mediaId: widget.mediaId,
          title: widget.title,
          isMovie: widget.isMovie,
          posterPath: widget.posterPath,
        );
        if (mounted) {
          setState(() => _isInWatchlist = true);
          FirebaseAnalytics.instance.logEvent(
            name: 'watchlist_added',
            parameters: <String, Object>{
              'source': 'media_detail',
              'type': widget.isMovie ? 'movie' : 'show',
            },
          );
        }
        UserActionService.logWatchlistAdd(
          mediaId: widget.mediaId,
          title: widget.title,
          type: widget.isMovie ? 'movie' : 'show',
          source: 'media_detail',
        );
      }
    } catch (e) {
      // Handle errors if necessary
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              'loading'.tr(),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text('retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Poster
            _buildPoster(),
            const SizedBox(height: 24),
            // Watchlist button
            _buildWatchlistButton(),
            const SizedBox(height: 32),
            // Streaming providers section
            _buildStreamingProvidersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistButton() {
    return SizedBox(
      width: 250,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleWatchlist,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _isInWatchlist ? Colors.orange.withValues(alpha: 0.15) : Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isInWatchlist ? Colors.orange : Theme.of(context).colorScheme.outline,
                width: _isInWatchlist ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                  color: _isInWatchlist ? Colors.orange : Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _isInWatchlist ? 'remove_from_watchlist'.tr() : 'add_to_watchlist'.tr(),
                  style: TextStyle(
                    color: _isInWatchlist ? Colors.orange : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (widget.posterPath == null) {
      return Container(
        width: 250,
        height: 375,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.movie_outlined,
          color: Colors.grey[600],
          size: 80,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: 'https://image.tmdb.org/t/p/w500${widget.posterPath}',
        width: 250,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: 250,
          height: 375,
          color: Theme.of(context).colorScheme.tertiary,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 250,
          height: 375,
          color: Theme.of(context).colorScheme.tertiary,
          child: Icon(
            Icons.error_outline,
            color: Colors.grey[600],
            size: 64,
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingProvidersSection() {
    final hasAnyContent = _streamingProviders.isNotEmpty || _rentProviders.isNotEmpty || _buyProviders.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'availability'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 16),
        if (!hasAnyContent)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'not_available_region'.tr(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Streaming section
          if (_streamingProviders.isNotEmpty) ...[
            _buildSectionHeader('stream'.tr(), Icons.play_circle_outline, Colors.green),
            const SizedBox(height: 12),
            ..._streamingProviders.map(
              (provider) {
                final isSubscribed = _userServiceIds.contains(provider.providerId);
                return _buildProviderCard(provider, isSubscribed);
              },
            ),
            const SizedBox(height: 24),
          ],

          // Rent section
          if (_rentProviders.isNotEmpty) ...[
            _buildSectionHeader('rent'.tr(), Icons.schedule, Colors.orange),
            const SizedBox(height: 12),
            ..._rentProviders.map(
              (provider) {
                return _buildProviderCard(provider, false, showCheckmark: false);
              },
            ),
            const SizedBox(height: 24),
          ],

          // Buy section
          if (_buyProviders.isNotEmpty) ...[
            _buildSectionHeader('buy'.tr(), Icons.shopping_cart_outlined, Colors.blue),
            const SizedBox(height: 12),
            ..._buyProviders.map(
              (provider) {
                return _buildProviderCard(provider, false, showCheckmark: false);
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(StreamingService provider, bool isSubscribed, {bool showCheckmark = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscribed ? Colors.green : Theme.of(context).colorScheme.outline,
          width: isSubscribed ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Provider logo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: provider.logoPath != null
                ? CachedNetworkImage(
                    imageUrl: 'https://image.tmdb.org/t/p/original${provider.logoPath}',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: Theme.of(context).colorScheme.tertiary,
                      child: Icon(
                        Icons.tv,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Theme.of(context).colorScheme.tertiary,
                    child: Icon(
                      Icons.tv,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Provider name
          Expanded(
            child: Text(
              provider.providerName ?? 'unknown'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          // Checkmark if subscribed
          if (showCheckmark && isSubscribed)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
