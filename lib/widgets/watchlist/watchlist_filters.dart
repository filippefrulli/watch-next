import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class WatchlistFilters extends StatelessWidget {
  final String mediaTypeFilter;
  final bool showOnlyAvailable;
  final Function(String) onMediaTypeChanged;
  final VoidCallback onAvailabilityToggled;

  const WatchlistFilters({
    super.key,
    required this.mediaTypeFilter,
    required this.showOnlyAvailable,
    required this.onMediaTypeChanged,
    required this.onAvailabilityToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildMediaTypeDropdown(context),
              ),
              const SizedBox(width: 12),
              _buildAvailableToggle(context),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMediaTypeDropdown(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.tertiary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMediaTypeMenu(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                size: 16,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getMediaTypeLabel(),
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableToggle(BuildContext context) {
    return GestureDetector(
      onTap: onAvailabilityToggled,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'available_only'.tr(),
            style: TextStyle(
              color: showOnlyAvailable ? Colors.orange : Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Switch(
            value: showOnlyAvailable,
            onChanged: (_) => onAvailabilityToggled(),
            activeColor: Colors.orange,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  IconData _getMediaTypeIcon() {
    switch (mediaTypeFilter) {
      case 'movies':
        return Icons.movie;
      case 'tv':
        return Icons.tv;
      default:
        return Icons.video_library;
    }
  }

  String _getMediaTypeLabel() {
    switch (mediaTypeFilter) {
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
      color: Theme.of(context).colorScheme.tertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      items: [
        _buildMenuItem('all', Icons.video_library, 'all'.tr()),
        _buildMenuItem('movies', Icons.movie, 'movies'.tr()),
        _buildMenuItem('tv', Icons.tv, 'tv_shows'.tr()),
      ],
    ).then((value) {
      if (value != null) {
        onMediaTypeChanged(value);
      }
    });
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String label) {
    final isSelected = mediaTypeFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.orange : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.grey[300],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(
              Icons.check,
              size: 18,
              color: Colors.orange,
            ),
        ],
      ),
    );
  }
}
