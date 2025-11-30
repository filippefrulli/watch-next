import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ImportSourceDialog extends StatelessWidget {
  final Function(String) onSourceSelected;

  const ImportSourceDialog({
    super.key,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      title: Text(
        'import_from'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImportSourceOption(
            context,
            'IMDb',
            'imdb',
            Icons.movie,
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildImportSourceOption(
            context,
            'Letterboxd',
            'letterboxd',
            Icons.local_movies,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildImportSourceOption(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Material(
      color: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          onSourceSelected(value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
