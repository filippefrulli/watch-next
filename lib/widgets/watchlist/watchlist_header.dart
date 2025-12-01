import 'package:flutter/material.dart';

class WatchlistHeader extends StatelessWidget {
  final bool isImporting;
  final bool isRefreshing;
  final VoidCallback onImportTap;
  final VoidCallback onRefreshTap;

  const WatchlistHeader({
    super.key,
    required this.isImporting,
    required this.isRefreshing,
    required this.onImportTap,
    required this.onRefreshTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildImportButton(context),
          const SizedBox(width: 12),
          _buildRefreshButton(context),
        ],
      ),
    );
  }

  Widget _buildImportButton(BuildContext context) {
    return Container(
      height: 40,
      width: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isImporting ? null : onImportTap,
          child: Icon(
            Icons.arrow_upward_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isRefreshing ? null : onRefreshTap,
          child: isRefreshing
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 20,
                ),
        ),
      ),
    );
  }
}
