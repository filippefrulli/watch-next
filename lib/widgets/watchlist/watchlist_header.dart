import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/pages/settings_page.dart';
import 'package:watch_next/utils/app_colors.dart';

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'watchlist'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _IconButton(
            icon: Icons.arrow_upward_rounded,
            isLoading: isImporting,
            onTap: isImporting ? null : onImportTap,
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.refresh_rounded,
            isLoading: isRefreshing,
            onTap: isRefreshing ? null : onRefreshTap,
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.settings_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _IconButton({
    required this.icon,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface2,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: context.appColors.border, width: 1),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(icon, color: Colors.white, size: 19),
          ),
        ),
      ),
    );
  }
}
