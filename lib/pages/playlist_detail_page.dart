import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/objects/playlist.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/playlist_service.dart';
import 'package:watch_next/services/user_action_service.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final PlaylistService _playlistService = PlaylistService();
  List<LoadedPlaylistItem> _items = [];
  List<int> _userServiceIds = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load user's streaming services
      _userServiceIds = await DatabaseService.getStreamingServicesIds();

      // Load playlist items with details
      final items = await _playlistService.loadPlaylistItems(widget.playlist);

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: CustomScrollView(
        slivers: [
          // App bar with playlist info
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            expandedHeight: 160,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
              title: Text(
                widget.playlist.getLocalizedTitle(context.locale.languageCode),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.orange.withOpacity(0.3),
                      Theme.of(context).colorScheme.primary,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Description
          if (widget.playlist.description != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  widget.playlist.description!,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          // Content
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.grey[600], size: 48),
              const SizedBox(height: 16),
              Text(
                'error_occurred'.tr(),
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadData,
                child: Text('retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'no_items'.tr(),
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _PlaylistItemCard(
            item: _items[index],
            userServiceIds: _userServiceIds,
            onTap: () => _openItem(_items[index]),
          ),
          childCount: _items.length,
        ),
      ),
    );
  }

  void _openItem(LoadedPlaylistItem item) {
    // Track playlist item selected
    UserActionService.logPlaylistItemSelected(
      playlistId: widget.playlist.id,
      mediaId: item.tmdbId,
      title: item.title,
      type: item.isMovie ? 'movie' : 'show',
      positionInList: _items.indexOf(item),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaDetailPage(
          mediaId: item.tmdbId,
          title: item.title,
          isMovie: item.isMovie,
          posterPath: item.posterPath,
        ),
      ),
    );
  }
}

class _PlaylistItemCard extends StatelessWidget {
  final LoadedPlaylistItem item;
  final List<int> userServiceIds;
  final VoidCallback onTap;

  const _PlaylistItemCard({
    required this.item,
    required this.userServiceIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.isAvailableOnStreaming(userServiceIds);
    final hasRentOrBuy = item.rentProviderIds.isNotEmpty || item.buyProviderIds.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.posterPath != null
                        ? CachedNetworkImage(
                            imageUrl: 'https://image.tmdb.org/t/p/w342${item.posterPath}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.orange,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: Icon(Icons.movie, color: Colors.grey[600], size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: Icon(Icons.movie, color: Colors.grey[600], size: 40),
                          ),
                  ),
                ),
                // Availability badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? Colors.green.withOpacity(0.9)
                          : (hasRentOrBuy ? Colors.orange.withOpacity(0.9) : Colors.grey.withOpacity(0.9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAvailable ? 'stream'.tr() : (hasRentOrBuy ? 'rent_buy'.tr() : 'not_available'.tr()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Rating
          if (item.voteAverage != null && item.voteAverage! > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  item.voteAverage!.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
