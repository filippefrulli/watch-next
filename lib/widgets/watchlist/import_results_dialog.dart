import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ImportResultsDialog extends StatelessWidget {
  final int successCount;
  final int skippedCount;
  final int failedCount;

  const ImportResultsDialog({
    super.key,
    required this.successCount,
    required this.skippedCount,
    required this.failedCount,
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
        'import_complete'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultRow(
            Icons.check_circle,
            Colors.green,
            'Added $successCount items',
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            Icons.info,
            Colors.orange,
            'Skipped $skippedCount (already in watchlist)',
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            Icons.error_outline,
            Colors.red,
            'Failed $failedCount',
          ),
        ],
      ),
      actions: [
        Container(
          width: double.infinity,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.orange[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Text(
                  'ok'.tr().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
