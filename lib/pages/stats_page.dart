import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/services/watched_service.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final WatchedService _watchedService = WatchedService();
  bool _isLoading = true;
  bool _isChartLoading = false;

  // 'all', 'movies', 'tv'
  String _typeFilter = 'all';

  int _totalCount = 0;
  int _movieCount = 0;
  int _showCount = 0;
  Map<int, int> _ratingDistribution = {};
  Map<String, int> _genreBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  bool? get _isMovieFilter => _typeFilter == 'movies'
      ? true
      : _typeFilter == 'tv'
          ? false
          : null;

  Future<void> _loadStats() async {
    final results = await Future.wait([
      _watchedService.getTotalCount(),
      _watchedService.getTypeBreakdown(),
      _watchedService.getRatingDistribution(),
      _watchedService.getGenreBreakdown(),
    ]);

    if (mounted) {
      setState(() {
        _totalCount = results[0] as int;
        final breakdown = results[1] as Map<String, int>;
        _movieCount = breakdown['movies'] ?? 0;
        _showCount = breakdown['shows'] ?? 0;
        _ratingDistribution = results[2] as Map<int, int>;
        _genreBreakdown = results[3] as Map<String, int>;
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _typeFilter = filter;
      _isChartLoading = true;
    });
    final isMovie = _isMovieFilter;
    final results = await Future.wait([
      _watchedService.getRatingDistribution(isMovie: isMovie),
      _watchedService.getGenreBreakdown(isMovie: isMovie),
    ]);
    if (mounted) {
      setState(() {
        _ratingDistribution = results[0] as Map<int, int>;
        _genreBreakdown = results[1] as Map<String, int>;
        _isChartLoading = false;
      });
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'stats'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _totalCount == 0
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _typeFilter == value;
    return GestureDetector(
      onTap: () => _applyFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.withValues(alpha: 0.15) : Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.orange : Theme.of(context).colorScheme.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.orange : Colors.white,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(child: _buildStatCard('stats_total'.tr(), '$_totalCount', Icons.check_circle_outline)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('movies'.tr(), '$_movieCount', Icons.movie_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('tv_shows'.tr(), '$_showCount', Icons.tv_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          // Type filter chips
          Row(
            children: [
              _filterChip('all', 'all'.tr()),
              const SizedBox(width: 8),
              _filterChip('movies', 'movies'.tr()),
              const SizedBox(width: 8),
              _filterChip('tv', 'tv_shows'.tr()),
            ],
          ),
          // Charts (or loading spinner while re-fetching)
          if (_isChartLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: Colors.orange)),
            )
          else ...[
            // Genre breakdown
            if (_genreBreakdown.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'stats_top_genres'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              _buildGenreBreakdown(),
            ],
            // Rating distribution
            if (_ratingDistribution.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'stats_rating_distribution'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              _buildRatingDistribution(),
            ],
          ], // end else
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenreBreakdown() {
    final maxCount = _genreBreakdown.values.fold(0, (a, b) => a > b ? a : b);
    // Show top 10 genres
    final entries = _genreBreakdown.entries.take(10).toList();

    return Column(
      children: entries.map((e) {
        final fraction = maxCount > 0 ? e.value / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  e.key,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 22, color: Theme.of(context).colorScheme.tertiary),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 24,
                child: Text(
                  '${e.value}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingDistribution() {
    final maxCount = _ratingDistribution.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: List.generate(10, (i) {
        final rating = 10 - i;
        final count = _ratingDistribution[rating] ?? 0;
        final fraction = maxCount > 0 ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$rating',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 22,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 28,
                child: Text(
                  '$count',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'stats_empty'.tr(),
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ],
      ),
    );
  }
}
