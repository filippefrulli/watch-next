import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReleaseFilter { any, recent, old }

enum ReviewFilter { any, positive, great }

enum PopularityFilter { any, veryPopular, hidden }

// Movie-specific
enum DurationFilter { any, normal, long }

// TV Show-specific
enum CompletionFilter { any, finished, ongoing }

enum SeasonCountFilter { any, short, long }

class QuerySettings {
  final ReleaseFilter releaseFilter;
  final ReviewFilter reviewFilter;
  final PopularityFilter popularityFilter;
  // Movie-specific
  final DurationFilter durationFilter;
  // TV Show-specific
  final CompletionFilter completionFilter;
  final SeasonCountFilter seasonCountFilter;

  const QuerySettings({
    this.releaseFilter = ReleaseFilter.any,
    this.reviewFilter = ReviewFilter.any,
    this.popularityFilter = PopularityFilter.any,
    this.durationFilter = DurationFilter.any,
    this.completionFilter = CompletionFilter.any,
    this.seasonCountFilter = SeasonCountFilter.any,
  });

  QuerySettings copyWith({
    ReleaseFilter? releaseFilter,
    ReviewFilter? reviewFilter,
    PopularityFilter? popularityFilter,
    DurationFilter? durationFilter,
    CompletionFilter? completionFilter,
    SeasonCountFilter? seasonCountFilter,
  }) {
    return QuerySettings(
      releaseFilter: releaseFilter ?? this.releaseFilter,
      reviewFilter: reviewFilter ?? this.reviewFilter,
      popularityFilter: popularityFilter ?? this.popularityFilter,
      durationFilter: durationFilter ?? this.durationFilter,
      completionFilter: completionFilter ?? this.completionFilter,
      seasonCountFilter: seasonCountFilter ?? this.seasonCountFilter,
    );
  }

  /// Convert settings to prompt text to append to user query
  /// [isMovie] determines whether to use movie or TV show specific filters
  String toPromptSuffix({required bool isMovie}) {
    final parts = <String>[];

    switch (releaseFilter) {
      case ReleaseFilter.recent:
        parts.add('released in the last 5 years');
        break;
      case ReleaseFilter.old:
        parts.add('released before 2010, classic');
        break;
      case ReleaseFilter.any:
        break;
    }

    switch (reviewFilter) {
      case ReviewFilter.positive:
        parts.add('with positive reviews');
        break;
      case ReviewFilter.great:
        parts.add('with great reviews and high ratings');
        break;
      case ReviewFilter.any:
        break;
    }

    switch (popularityFilter) {
      case PopularityFilter.veryPopular:
        parts.add('very popular and well-known');
        break;
      case PopularityFilter.hidden:
        parts.add('hidden gem, not very popular');
        break;
      case PopularityFilter.any:
        break;
    }

    // Movie-specific filters
    if (isMovie) {
      switch (durationFilter) {
        case DurationFilter.normal:
          parts.add('shorter than 2 hours');
          break;
        case DurationFilter.long:
          parts.add('longer than 2 hours');
          break;
        case DurationFilter.any:
          break;
      }
    } else {
      // TV Show-specific filters
      switch (completionFilter) {
        case CompletionFilter.finished:
          parts.add('that has finished airing');
          break;
        case CompletionFilter.ongoing:
          parts.add('that is still ongoing');
          break;
        case CompletionFilter.any:
          break;
      }

      switch (seasonCountFilter) {
        case SeasonCountFilter.short:
          parts.add('with up to 3 seasons');
          break;
        case SeasonCountFilter.long:
          parts.add('with 4 or more seasons');
          break;
        case SeasonCountFilter.any:
          break;
      }
    }

    if (parts.isEmpty) return '';
    return ', ${parts.join(', ')}';
  }

  bool get hasActiveFilters =>
      releaseFilter != ReleaseFilter.any ||
      reviewFilter != ReviewFilter.any ||
      popularityFilter != PopularityFilter.any ||
      durationFilter != DurationFilter.any ||
      completionFilter != CompletionFilter.any ||
      seasonCountFilter != SeasonCountFilter.any;
}

class QuerySettingsService {
  static const String _releaseFilterKey = 'query_release_filter';
  static const String _reviewFilterKey = 'query_review_filter';
  static const String _popularityFilterKey = 'query_popularity_filter';
  static const String _durationFilterKey = 'query_duration_filter';
  static const String _completionFilterKey = 'query_completion_filter';
  static const String _seasonCountFilterKey = 'query_season_count_filter';

  static Future<QuerySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final releaseIndex = prefs.getInt(_releaseFilterKey) ?? 0;
    final reviewIndex = prefs.getInt(_reviewFilterKey) ?? 0;
    final popularityIndex = prefs.getInt(_popularityFilterKey) ?? 0;
    final durationIndex = prefs.getInt(_durationFilterKey) ?? 0;
    final completionIndex = prefs.getInt(_completionFilterKey) ?? 0;
    final seasonCountIndex = prefs.getInt(_seasonCountFilterKey) ?? 0;

    return QuerySettings(
      releaseFilter: ReleaseFilter.values[releaseIndex],
      reviewFilter: ReviewFilter.values[reviewIndex],
      popularityFilter: PopularityFilter.values[popularityIndex],
      durationFilter: DurationFilter.values[durationIndex],
      completionFilter: CompletionFilter.values[completionIndex],
      seasonCountFilter: SeasonCountFilter.values[seasonCountIndex],
    );
  }

  static Future<void> save(QuerySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_releaseFilterKey, settings.releaseFilter.index);
    await prefs.setInt(_reviewFilterKey, settings.reviewFilter.index);
    await prefs.setInt(_popularityFilterKey, settings.popularityFilter.index);
    await prefs.setInt(_durationFilterKey, settings.durationFilter.index);
    await prefs.setInt(_completionFilterKey, settings.completionFilter.index);
    await prefs.setInt(_seasonCountFilterKey, settings.seasonCountFilter.index);
  }
}

class QuerySettingsPanel extends StatefulWidget {
  final QuerySettings initialSettings;
  final ValueChanged<QuerySettings> onSettingsChanged;
  final bool isMovie;

  const QuerySettingsPanel({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
    required this.isMovie,
  });

  static Future<void> show(
    BuildContext context, {
    required QuerySettings initialSettings,
    required ValueChanged<QuerySettings> onSettingsChanged,
    required bool isMovie,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuerySettingsPanel(
        initialSettings: initialSettings,
        onSettingsChanged: onSettingsChanged,
        isMovie: isMovie,
      ),
    );
  }

  @override
  State<QuerySettingsPanel> createState() => _QuerySettingsPanelState();
}

class _QuerySettingsPanelState extends State<QuerySettingsPanel> {
  late QuerySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _updateSettings(QuerySettings newSettings) {
    setState(() => _settings = newSettings);
    widget.onSettingsChanged(newSettings);
    QuerySettingsService.save(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReleaseSection(context),
                  const SizedBox(height: 24),
                  _buildReviewSection(context),
                  const SizedBox(height: 24),
                  _buildPopularitySection(context),
                  const SizedBox(height: 24),
                  if (widget.isMovie)
                    _buildDurationSection(context)
                  else ...[
                    _buildCompletionSection(context),
                    const SizedBox(height: 24),
                    _buildSeasonCountSection(context),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'query_settings'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_settings.hasActiveFilters)
            TextButton(
              onPressed: () {
                _updateSettings(const QuerySettings());
              },
              child: Text(
                'reset'.tr(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReleaseSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'release_period'.tr(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFilterChip(
              label: 'any'.tr(),
              isSelected: _settings.releaseFilter == ReleaseFilter.any,
              onTap: () => _updateSettings(
                _settings.copyWith(releaseFilter: ReleaseFilter.any),
              ),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'recent'.tr(),
              isSelected: _settings.releaseFilter == ReleaseFilter.recent,
              onTap: () => _updateSettings(
                _settings.copyWith(releaseFilter: ReleaseFilter.recent),
              ),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'classic'.tr(),
              isSelected: _settings.releaseFilter == ReleaseFilter.old,
              onTap: () => _updateSettings(
                _settings.copyWith(releaseFilter: ReleaseFilter.old),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reviews'.tr(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFilterChip(
              label: 'any'.tr(),
              isSelected: _settings.reviewFilter == ReviewFilter.any,
              onTap: () => _updateSettings(
                _settings.copyWith(reviewFilter: ReviewFilter.any),
              ),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'positive'.tr(),
              isSelected: _settings.reviewFilter == ReviewFilter.positive,
              onTap: () => _updateSettings(
                _settings.copyWith(reviewFilter: ReviewFilter.positive),
              ),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'great'.tr(),
              isSelected: _settings.reviewFilter == ReviewFilter.great,
              onTap: () => _updateSettings(
                _settings.copyWith(reviewFilter: ReviewFilter.great),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPopularitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'popularity'.tr(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'any'.tr(),
              isSelected: _settings.popularityFilter == PopularityFilter.any,
              onTap: () => _updateSettings(
                _settings.copyWith(popularityFilter: PopularityFilter.any),
              ),
            ),
            _buildFilterChip(
              label: 'very_popular'.tr(),
              isSelected: _settings.popularityFilter == PopularityFilter.veryPopular,
              onTap: () => _updateSettings(
                _settings.copyWith(popularityFilter: PopularityFilter.veryPopular),
              ),
            ),
            _buildFilterChip(
              label: 'hidden_gem'.tr(),
              isSelected: _settings.popularityFilter == PopularityFilter.hidden,
              onTap: () => _updateSettings(
                _settings.copyWith(popularityFilter: PopularityFilter.hidden),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Movie-specific section
  Widget _buildDurationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'duration'.tr(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'any'.tr(),
              isSelected: _settings.durationFilter == DurationFilter.any,
              onTap: () => _updateSettings(
                _settings.copyWith(durationFilter: DurationFilter.any),
              ),
            ),
            _buildFilterChip(
              label: 'duration_normal'.tr(),
              isSelected: _settings.durationFilter == DurationFilter.normal,
              onTap: () => _updateSettings(
                _settings.copyWith(durationFilter: DurationFilter.normal),
              ),
            ),
            _buildFilterChip(
              label: 'duration_long'.tr(),
              isSelected: _settings.durationFilter == DurationFilter.long,
              onTap: () => _updateSettings(
                _settings.copyWith(durationFilter: DurationFilter.long),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TV Show-specific sections
  Widget _buildCompletionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'completion_status'.tr(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'any'.tr(),
              isSelected: _settings.completionFilter == CompletionFilter.any,
              onTap: () => _updateSettings(
                _settings.copyWith(completionFilter: CompletionFilter.any),
              ),
            ),
            _buildFilterChip(
              label: 'finished'.tr(),
              isSelected: _settings.completionFilter == CompletionFilter.finished,
              onTap: () => _updateSettings(
                _settings.copyWith(completionFilter: CompletionFilter.finished),
              ),
            ),
            _buildFilterChip(
              label: 'ongoing'.tr(),
              isSelected: _settings.completionFilter == CompletionFilter.ongoing,
              onTap: () => _updateSettings(
                _settings.copyWith(completionFilter: CompletionFilter.ongoing),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeasonCountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'season_count'.tr(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'any'.tr(),
              isSelected: _settings.seasonCountFilter == SeasonCountFilter.any,
              onTap: () => _updateSettings(
                _settings.copyWith(seasonCountFilter: SeasonCountFilter.any),
              ),
            ),
            _buildFilterChip(
              label: 'seasons_short'.tr(),
              isSelected: _settings.seasonCountFilter == SeasonCountFilter.short,
              onTap: () => _updateSettings(
                _settings.copyWith(seasonCountFilter: SeasonCountFilter.short),
              ),
            ),
            _buildFilterChip(
              label: 'seasons_long'.tr(),
              isSelected: _settings.seasonCountFilter == SeasonCountFilter.long,
              onTap: () => _updateSettings(
                _settings.copyWith(seasonCountFilter: SeasonCountFilter.long),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withValues(alpha: 0.2) : Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class QuerySettingsButton extends StatelessWidget {
  final QuerySettings settings;
  final ValueChanged<QuerySettings> onSettingsChanged;
  final bool isMovie;

  const QuerySettingsButton({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.isMovie,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.grey[500],
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.black,
              size: 26,
            ),
            onPressed: () => QuerySettingsPanel.show(
              context,
              initialSettings: settings,
              onSettingsChanged: onSettingsChanged,
              isMovie: isMovie,
            ),
          ),
        ),
        if (settings.hasActiveFilters)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.orange[800],
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
