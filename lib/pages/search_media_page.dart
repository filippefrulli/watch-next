import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/widgets/search_media/search_bar_widget.dart';
import 'package:watch_next/widgets/search_media/search_empty_state.dart';
import 'package:watch_next/widgets/search_media/search_result_card.dart';

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
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        _performSearch(value);
      }
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(
              controller: _searchController,
              onClear: _onClearSearch,
              onChanged: _onSearchChanged,
              onSubmitted: _performSearch,
            ),
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
      return const SearchLoadingState();
    }

    if (_errorMessage.isNotEmpty) {
      return SearchErrorState(errorMessage: _errorMessage);
    }

    if (_searchController.text.isEmpty) {
      return const SearchEmptyState();
    }

    if (_searchResults.isEmpty) {
      return const SearchNoResultsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return SearchResultCard(result: _searchResults[index]);
      },
    );
  }
}
