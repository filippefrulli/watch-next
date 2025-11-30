import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/imdb_import_service.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:file_picker/file_picker.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final WatchlistService _watchlistService = WatchlistService();
  final HttpService _httpService = HttpService();
  final ImdbImportService _importService = ImdbImportService();
  List<int> _userServiceIds = [];
  bool _isRefreshing = false;
  bool _isImporting = false;
  List<WatchlistItem> _currentItems = [];
  bool _showOnlyAvailable = false;
  String _mediaTypeFilter = 'all'; // 'all', 'movies', 'tv'

  @override
  void initState() {
    super.initState();
    _loadUserServices();
  }

  Future<void> _loadUserServices() async {
    final services = await DatabaseService.getStreamingServicesIds();
    setState(() {
      _userServiceIds = services;
    });
  }

  Future<void> _refreshAllAvailability() async {
    if (_isRefreshing || _currentItems.isEmpty) return;

    setState(() {
      _isRefreshing = true;
    });

    for (var item in _currentItems) {
      await _refreshAvailability(item);
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshAvailability(WatchlistItem item) async {
    try {
      final providers = await _httpService.getCategorizedWatchProviders(
        item.mediaId,
        item.isMovie,
      );

      // Convert CategorizedWatchProviders to Map<String, List<int>>
      final availabilityMap = {
        'streaming': providers.streaming.map((s) => s.providerId).whereType<int>().toList(),
        'rent': providers.rent.map((s) => s.providerId).whereType<int>().toList(),
        'buy': providers.buy.map((s) => s.providerId).whereType<int>().toList(),
      };

      await _watchlistService.updateAvailability(
        mediaId: item.mediaId,
        availability: availabilityMap,
      );
    } catch (e) {
      print('Error refreshing availability: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: StreamBuilder<List<WatchlistItem>>(
                stream: _watchlistService.getWatchlist(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'error_loading_watchlist'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final allItems = snapshot.data ?? [];

                  // Apply filters
                  final filteredItems = allItems.where((item) {
                    // Filter by availability
                    if (_showOnlyAvailable && !item.isAvailable(_userServiceIds)) {
                      return false;
                    }

                    // Filter by media type
                    if (_mediaTypeFilter == 'movies' && !item.isMovie) {
                      return false;
                    }
                    if (_mediaTypeFilter == 'tv' && item.isMovie) {
                      return false;
                    }

                    return true;
                  }).toList();

                  // Store current items for refresh
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _currentItems = allItems;
                    }
                  });

                  if (allItems.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (filteredItems.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      for (var item in allItems) {
                        await _refreshAvailability(item);
                      }
                    },
                    backgroundColor: Colors.grey[850],
                    color: Colors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildWatchlistItem(filteredItems[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'watchlist'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isImporting ? null : _importFromImdb,
                child: const Icon(
                  Icons.upload_file,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isRefreshing ? null : _refreshAllAvailability,
                child: _isRefreshing
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromImdb() async {
    try {
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      setState(() {
        _isImporting = true;
      });

      // Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'importing_watchlist'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few moments...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final file = result.files.single;
      final (successCount, skippedCount, failedCount) = await _importService.importFromCsv(File(file.path!));

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog

        // Show results
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
            title: Text(
              'import_complete'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultRow(
                  Icons.check_circle,
                  Colors.green,
                  'Added $successCount items',
                ),
                const SizedBox(height: 12),
                _buildResultRow(
                  Icons.info,
                  Colors.orange,
                  'Skipped $skippedCount (already in watchlist)',
                ),
                const SizedBox(height: 12),
                _buildResultRow(
                  Icons.error_outline,
                  Colors.red,
                  'Failed $failedCount',
                ),
              ],
            ),
            actions: [
              Container(
                width: double.infinity,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.orange[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(),
                    child: Center(
                      child: Text(
                        'ok'.tr().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog if open

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            title: Text(
              'error_occurred'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              'import_error'.tr(),
              style: TextStyle(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'ok'.tr(),
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Widget _buildResultRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'watchlist_empty'.tr(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'watchlist_empty_hint'.tr(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No items match your filters',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              // Media type dropdown
              Expanded(
                flex: 2,
                child: Material(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showMediaTypeMenu(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getMediaTypeIcon(),
                            size: 18,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getMediaTypeLabel(),
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Availability filter
              Expanded(
                flex: 2,
                child: _buildFilterChip(
                  label: 'available_only'.tr(),
                  isSelected: _showOnlyAvailable,
                  icon: Icons.check_circle,
                  onTap: () {
                    setState(() {
                      _showOnlyAvailable = !_showOnlyAvailable;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getMediaTypeIcon() {
    switch (_mediaTypeFilter) {
      case 'movies':
        return Icons.movie;
      case 'tv':
        return Icons.tv;
      default:
        return Icons.video_library;
    }
  }

  String _getMediaTypeLabel() {
    switch (_mediaTypeFilter) {
      case 'movies':
        return 'movies'.tr();
      case 'tv':
        return 'tv_shows'.tr();
      default:
        return 'all'.tr();
    }
  }

  void _showMediaTypeMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(16, 200, 16, 0),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'all',
          child: Row(
            children: [
              Icon(
                Icons.video_library,
                size: 18,
                color: _mediaTypeFilter == 'all' ? Colors.orange : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Text(
                'all'.tr(),
                style: TextStyle(
                  color: _mediaTypeFilter == 'all' ? Colors.orange : Colors.grey[300],
                  fontWeight: _mediaTypeFilter == 'all' ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (_mediaTypeFilter == 'all')
                const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.orange,
                ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'movies',
          child: Row(
            children: [
              Icon(
                Icons.movie,
                size: 18,
                color: _mediaTypeFilter == 'movies' ? Colors.orange : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Text(
                'movies'.tr(),
                style: TextStyle(
                  color: _mediaTypeFilter == 'movies' ? Colors.orange : Colors.grey[300],
                  fontWeight: _mediaTypeFilter == 'movies' ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (_mediaTypeFilter == 'movies')
                const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.orange,
                ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'tv',
          child: Row(
            children: [
              Icon(
                Icons.tv,
                size: 18,
                color: _mediaTypeFilter == 'tv' ? Colors.orange : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Text(
                'tv_shows'.tr(),
                style: TextStyle(
                  color: _mediaTypeFilter == 'tv' ? Colors.orange : Colors.grey[300],
                  fontWeight: _mediaTypeFilter == 'tv' ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (_mediaTypeFilter == 'tv')
                const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.orange,
                ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _mediaTypeFilter = value;
        });
      }
    });
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.grey[850],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.grey[700]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.orange : Colors.grey[400],
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.orange : Colors.grey[300],
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistItem(WatchlistItem item) {
    final isAvailable = item.isAvailable(_userServiceIds);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MediaDetailPage(
                  mediaId: item.mediaId,
                  title: item.title,
                  isMovie: item.isMovie,
                  posterPath: item.posterPath,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl: 'https://image.tmdb.org/t/p/w200${item.posterPath}',
                          width: 60,
                          height: 90,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 90,
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 90,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.movie,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Title and availability
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.isMovie ? 'movie'.tr() : 'tv_show'.tr(),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAvailable ? Colors.green : Colors.grey[600]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvailable ? Icons.check_circle : Icons.info,
                                  size: 14,
                                  color: isAvailable ? Colors.green : Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAvailable ? 'available'.tr() : 'not_available'.tr(),
                                  style: TextStyle(
                                    color: isAvailable ? Colors.green : Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Remove button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.grey[400],
                  onPressed: () async {
                    await _watchlistService.removeFromWatchlist(item.mediaId);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
