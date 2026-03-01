import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/objects/person_details.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:watch_next/services/http_service.dart';

class PersonDetailPage extends StatefulWidget {
  final int personId;
  final String personName;
  final String? profilePath;

  const PersonDetailPage({
    super.key,
    required this.personId,
    required this.personName,
    this.profilePath,
  });

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  PersonDetails? _person;
  List<PersonCredit> _movieCredits = [];
  List<PersonCredit> _showCredits = [];
  String _selectedFilter = 'all'; // 'all', 'movies', 'shows'

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final details = await HttpService().fetchPersonDetails(widget.personId);
      final credits = await HttpService().fetchPersonCredits(widget.personId);

      // Deduplicate and sort cast credits by date descending
      final seenCastIds = <int>{};
      final castCredits = credits.cast.where((c) => c.posterPath != null && seenCastIds.add(c.id ?? -1)).toList()
        ..sort((a, b) => (b.displayDate).compareTo(a.displayDate));

      // Deduplicate and sort crew credits (directing only for directors) by date descending
      final seenCrewIds = <int>{};
      final crewCredits = credits.crew.where((c) => c.posterPath != null && seenCrewIds.add(c.id ?? -1)).toList()
        ..sort((a, b) => (b.displayDate).compareTo(a.displayDate));

      // If known for directing, show directing credits; otherwise use cast credits
      final bool isDirector = details.knownForDepartment == 'Directing';
      final allCredits = isDirector ? crewCredits : castCredits;

      if (mounted) {
        setState(() {
          _person = details;
          _movieCredits = allCredits.where((c) => c.isMovie).toList();
          _showCredits = allCredits.where((c) => !c.isMovie).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PersonCredit> get _filteredCredits {
    switch (_selectedFilter) {
      case 'movies':
        return _movieCredits;
      case 'shows':
        return _showCredits;
      default:
        return [..._movieCredits, ..._showCredits]..sort((a, b) => b.displayDate.compareTo(a.displayDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'loading'.tr(),
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _buildProfileHeader()),
        if (_person?.biography != null && _person!.biography!.isNotEmpty) SliverToBoxAdapter(child: _buildBiography()),
        SliverToBoxAdapter(child: _buildFilterChips()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'person_filmography'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        _buildFilmographyGrid(),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.personName,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildProfileHeader() {
    final person = _person;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.profilePath != null
                ? CachedNetworkImage(
                    imageUrl: 'https://image.tmdb.org/t/p/w185${widget.profilePath}',
                    width: 140,
                    height: 210,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _profilePlaceholder(),
                    errorWidget: (_, __, ___) => _profilePlaceholder(),
                  )
                : _profilePlaceholder(),
          ),
          const SizedBox(width: 16),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.personName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (person?.birthday != null) ...[
                  const SizedBox(height: 12),
                  _infoRow(Icons.cake_outlined, _formatDate(person!.birthday!)),
                ],
                const SizedBox(height: 12),
                _statBadge('${_movieCredits.length}', 'person_movies'.tr()),
                const SizedBox(height: 8),
                _statBadge('${_showCredits.length}', 'person_shows'.tr()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilePlaceholder() {
    return Container(
      width: 140,
      height: 210,
      color: Theme.of(context).colorScheme.tertiary,
      child: Icon(Icons.person, color: Colors.grey[600], size: 48),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[500], size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(color: Colors.grey[400], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _statBadge(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBiography() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: _ExpandableBiography(biography: _person!.biography!),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          _filterChip('all', 'person_filter_all'.tr()),
          const SizedBox(width: 8),
          _filterChip('movies', 'person_filter_movies'.tr()),
          const SizedBox(width: 8),
          _filterChip('shows', 'person_filter_shows'.tr()),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withValues(alpha: 0.15) : Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[700]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.grey[400],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilmographyGrid() {
    final credits = _filteredCredits;

    if (credits.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'person_no_credits'.tr(),
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildCreditCard(credits[index]),
          childCount: credits.length,
        ),
      ),
    );
  }

  Widget _buildCreditCard(PersonCredit credit) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaDetailPage(
              mediaId: credit.id!,
              title: credit.displayTitle,
              isMovie: credit.isMovie,
              posterPath: credit.posterPath,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: credit.posterPath != null
                  ? CachedNetworkImage(
                      imageUrl: 'https://image.tmdb.org/t/p/w185${credit.posterPath}',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _posterPlaceholder(),
                      errorWidget: (_, __, ___) => _posterPlaceholder(),
                    )
                  : _posterPlaceholder(),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            credit.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          if (credit.displayDate.length >= 4)
            Text(
              credit.displayDate.substring(0, 4),
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.tertiary,
      child: Icon(Icons.movie_outlined, color: Colors.grey[700], size: 32),
    );
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
      }
    } catch (_) {}
    return date;
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

// Expandable biography widget
class _ExpandableBiography extends StatefulWidget {
  final String biography;
  const _ExpandableBiography({required this.biography});

  @override
  State<_ExpandableBiography> createState() => _ExpandableBiographyState();
}

class _ExpandableBiographyState extends State<_ExpandableBiography> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'person_biography'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.biography,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'person_show_less'.tr() : 'person_show_more'.tr(),
            style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
