import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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
          _buildImportButton(),
          const SizedBox(width: 12),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildImportButton() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isImporting ? null : onImportTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_upward_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'import'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
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
          onTap: isRefreshing ? null : onRefreshTap,
          child: isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
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
    );
  }
}
