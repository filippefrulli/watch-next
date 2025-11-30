import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/imdb_import_service.dart';
import 'package:watch_next/services/letterboxd_import_service.dart';
import 'package:watch_next/widgets/watchlist/import_source_dialog.dart';
import 'package:watch_next/widgets/watchlist/import_instructions_dialog.dart';
import 'package:watch_next/widgets/watchlist/import_progress_dialog.dart';
import 'package:watch_next/widgets/watchlist/import_results_dialog.dart';
import 'package:watch_next/widgets/watchlist/watchlist_item_card.dart';
import 'package:watch_next/widgets/watchlist/watchlist_filters.dart';
import 'package:watch_next/widgets/watchlist/watchlist_empty_state.dart';
import 'package:watch_next/widgets/watchlist/watchlist_header.dart';
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
  final LetterboxdImportService _letterboxdImportService = LetterboxdImportService();
  List<int> _userServiceIds = [];
  bool _isRefreshing = false;
  bool _isImporting = false;
  List<WatchlistItem> _currentItems = [];
  bool _showOnlyAvailable = false;
  String _mediaTypeFilter = 'all';

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
            WatchlistHeader(
              isImporting: _isImporting,
              isRefreshing: _isRefreshing,
              onImportTap: _showImportSourceDialog,
              onRefreshTap: _refreshAllAvailability,
            ),
            const SizedBox(height: 16),
            WatchlistFilters(
              mediaTypeFilter: _mediaTypeFilter,
              showOnlyAvailable: _showOnlyAvailable,
              onMediaTypeChanged: (value) {
                setState(() {
                  _mediaTypeFilter = value;
                });
              },
              onAvailabilityToggled: () {
                setState(() {
                  _showOnlyAvailable = !_showOnlyAvailable;
                });
              },
            ),
            Expanded(
              child: _buildWatchlistContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistContent() {
    return StreamBuilder<List<WatchlistItem>>(
      stream: _watchlistService.getWatchlist(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
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

        final filteredItems = allItems.where((item) {
          if (_showOnlyAvailable && !item.isAvailable(_userServiceIds)) {
            return false;
          }
          if (_mediaTypeFilter == 'movies' && !item.isMovie) {
            return false;
          }
          if (_mediaTypeFilter == 'tv' && item.isMovie) {
            return false;
          }
          return true;
        }).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _currentItems = allItems;
          }
        });

        if (allItems.isEmpty) {
          return const WatchlistEmptyState();
        }

        if (filteredItems.isEmpty) {
          return const WatchlistNoResultsState();
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
              return WatchlistItemCard(
                item: filteredItems[index],
                userServiceIds: _userServiceIds,
                onRemove: () async {
                  await _watchlistService.removeFromWatchlist(filteredItems[index].mediaId);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showImportSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportSourceDialog(
        onSourceSelected: _showImportInstructionsDialog,
      ),
    );
  }

  void _showImportInstructionsDialog(String source) {
    showDialog(
      context: context,
      builder: (context) => ImportInstructionsDialog(
        source: source,
        onSelectFile: () => _importFromSource(source),
      ),
    );
  }

  Future<void> _importFromSource(String source) async {
    switch (source) {
      case 'imdb':
        await _importFromImdb();
        break;
      case 'letterboxd':
        await _importFromLetterboxd();
        break;
    }
  }

  Future<void> _importFromImdb() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      setState(() {
        _isImporting = true;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ImportProgressDialog(),
        );
      }

      final file = result.files.single;
      final (successCount, skippedCount, failedCount) = await _importService.importFromCsv(File(file.path!));

      if (mounted) {
        Navigator.of(context).pop();

        showDialog(
          context: context,
          builder: (context) => ImportResultsDialog(
            successCount: successCount,
            skippedCount: skippedCount,
            failedCount: failedCount,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

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

  Future<void> _importFromLetterboxd() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      setState(() {
        _isImporting = true;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ImportProgressDialog(),
        );
      }

      final file = result.files.single;
      final (successCount, skippedCount, failedCount) = await _letterboxdImportService.importFromCsv(File(file.path!));

      if (mounted) {
        Navigator.of(context).pop();

        showDialog(
          context: context,
          builder: (context) => ImportResultsDialog(
            successCount: successCount,
            skippedCount: skippedCount,
            failedCount: failedCount,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            title: Text(
              'error_occurred'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              'letterboxd_import_error'.tr(),
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
}
