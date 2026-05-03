import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:watch_next/pages/settings_page.dart';
import 'package:watch_next/pages/stats_page.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/services/watched_service.dart';
import 'package:watch_next/widgets/watched/rating_dialog.dart';
import 'package:watch_next/widgets/shared/confirm_dialog.dart';
import 'package:watch_next/utils/app_colors.dart';

class WatchedPage extends StatefulWidget {
  const WatchedPage({super.key});

  @override
  State<WatchedPage> createState() => _WatchedPageState();
}

class _WatchedPageState extends State<WatchedPage> {
  final WatchedService _watchedService = WatchedService();

  List<WatchedItem> _allItems = [];
  List<WatchedItem> _filteredItems = [];
  bool _isLoading = true;

  // Filters
  String _typeFilter = 'all'; // 'all', 'movies', 'tv'
  int _minRating = 1;
  int _maxRating = 10;
  String _sortBy = 'date_watched'; // 'date_watched', 'rating', 'title'

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _watchedService.getWatchedList();
    if (mounted) {
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    var filtered = _allItems.where((item) {
      if (_typeFilter == 'movies' && !item.isMovie) return false;
      if (_typeFilter == 'tv' && item.isMovie) return false;
      if (item.rating < _minRating || item.rating > _maxRating) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          return b.rating.compareTo(a.rating);
        case 'title':
          return a.title.compareTo(b.title);
        default:
          return b.dateWatched.compareTo(a.dateWatched);
      }
    });

    setState(() => _filteredItems = filtered);
  }

  Future<void> _deleteItem(WatchedItem item) async {
    await _watchedService.removeFromWatched(item.mediaId);
    UserActionService.logWatchedRemove(
      mediaId: item.mediaId,
      title: item.title,
      type: item.isMovie ? 'movie' : 'show',
    );
    await _loadItems();
  }

  Future<void> _editItem(WatchedItem item) async {
    final result = await RatingDialog.show(
      context,
      title: item.title,
      initialRating: item.rating,
      initialDate: item.dateWatched,
    );
    if (result == null) return;
    await _watchedService.updateWatchedItem(
      item.mediaId,
      rating: result.rating,
      dateWatched: result.dateWatched,
    );
    if (result.rating != item.rating) {
      UserActionService.logWatchedEdit(mediaId: item.mediaId, title: item.title, field: 'rating');
    }
    if (result.dateWatched != item.dateWatched) {
      UserActionService.logWatchedEdit(mediaId: item.mediaId, title: item.title, field: 'date');
    }
    await _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: context.appColors.accent))
                  : _allItems.isEmpty
                      ? _buildEmptyState()
                      : _filteredItems.isEmpty
                          ? _buildNoResultsState()
                          : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'watched'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Stats button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                UserActionService.logStatsViewed();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, color: context.appColors.accent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'stats'.tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type + sort row
          Row(
            children: [
              // Type chips
              _filterChip('all', 'all'.tr()),
              const SizedBox(width: 8),
              _filterChip('movies', 'movies'.tr()),
              const SizedBox(width: 8),
              _filterChip('tv', 'tv_shows'.tr()),
              const Spacer(),
              // Sort dropdown
              _buildSortButton(),
            ],
          ),
          const SizedBox(height: 12),
          // Rating range row
          Row(
            children: [
              Icon(Icons.star, color: context.appColors.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                '$_minRating–$_maxRating',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Text('rating_filter'.tr(), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const Spacer(),
              SizedBox(
                width: 180,
                child: RangeSlider(
                  values: RangeValues(_minRating.toDouble(), _maxRating.toDouble()),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: context.appColors.accent,
                  inactiveColor: context.appColors.inactive,
                  onChanged: (values) {
                    setState(() {
                      _minRating = values.start.round();
                      _maxRating = values.end.round();
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _typeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _typeFilter = value);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.appColors.accent.withValues(alpha: 0.2) : Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? context.appColors.accent : Theme.of(context).colorScheme.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? context.appColors.accent : Colors.white,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    final labels = {
      'date_watched': 'sort_date'.tr(),
      'rating': 'sort_rating'.tr(),
      'title': 'sort_title'.tr(),
    };
    return PopupMenuButton<String>(
      color: Theme.of(context).colorScheme.tertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        setState(() => _sortBy = v);
        _applyFilters();
      },
      itemBuilder: (_) => labels.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    if (_sortBy == e.key) Icon(Icons.check, color: context.appColors.accent, size: 14),
                    if (_sortBy != e.key) const SizedBox(width: 14),
                    const SizedBox(width: 8),
                    Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(labels[_sortBy]!, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildCard(_filteredItems[index]);
      },
    );
  }

  Widget _buildCard(WatchedItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 150),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MediaDetailPage(
                    mediaId: item.mediaId,
                    title: item.title,
                    isMovie: item.isMovie,
                    posterPath: item.posterPath,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Poster
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: item.posterPath != null
                                ? CachedNetworkImage(
                                    imageUrl: 'https://image.tmdb.org/t/p/w200${item.posterPath}',
                                    fit: BoxFit.fill,
                                    placeholder: (_, __) => Container(
                                      color: Theme.of(context).colorScheme.primary,
                                      child: Icon(Icons.movie_outlined, color: Colors.grey[600], size: 24),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: Theme.of(context).colorScheme.primary,
                                      child: Icon(Icons.movie_outlined, color: Colors.grey[600], size: 24),
                                    ),
                                  )
                                : Container(
                                    color: Colors.black26,
                                    child: Icon(Icons.movie_outlined, color: Colors.grey[600], size: 24),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 12, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.isMovie ? 'movie'.tr() : 'tv_show'.tr(),
                                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('d MMM yyyy').format(item.dateWatched),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildRatingStars(item.rating),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: Colors.grey[400],
                          onPressed: () => _editItem(item),
                          tooltip: 'edit'.tr(),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _confirmDelete(item),
                          tooltip: 'remove'.tr(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: [
        Icon(Icons.star, color: context.appColors.accent, size: 16),
        const SizedBox(width: 4),
        Text(
          '$rating/10',
          style: TextStyle(
            color: context.appColors.accent,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(WatchedItem item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'remove_from_watched'.tr(),
      subtitle: item.title,
      confirmLabel: 'remove'.tr(),
      cancelLabel: 'cancel'.tr(),
    );
    if (confirmed) await _deleteItem(item);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check, size: 64, color: context.appColors.inactive),
          const SizedBox(height: 16),
          Text(
            'watched_empty'.tr(),
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'watched_empty_subtitle'.tr(),
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Text(
        'no_filter_results'.tr(),
        style: TextStyle(color: Colors.grey[500], fontSize: 15),
      ),
    );
  }
}
