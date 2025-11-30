import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ImportInstructionsDialog extends StatelessWidget {
  final String source;
  final VoidCallback onSelectFile;

  const ImportInstructionsDialog({
    super.key,
    required this.source,
    required this.onSelectFile,
  });

  @override
  Widget build(BuildContext context) {
    final instructions = _getImportInstructions(source);
    final sourceInfo = _getSourceInfo(source);

    return AlertDialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: sourceInfo['color'].withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              sourceInfo['icon'],
              color: sourceInfo['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            sourceInfo['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < instructions.length; i++) ...[
            _buildInstructionStep(i + 1, instructions[i], sourceInfo['color']),
            if (i < instructions.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!, width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(),
                    child: Center(
                      child: Text(
                        'cancel'.tr(),
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 48,
                margin: const EdgeInsets.only(left: 8),
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
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectFile();
                    },
                    child: Center(
                      child: Text(
                        'select_file'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _getImportInstructions(String source) {
    switch (source) {
      case 'imdb':
        return [
          'imdb_step_1'.tr(),
          'imdb_step_2'.tr(),
          'imdb_step_3'.tr(),
        ];
      case 'letterboxd':
        return [
          'letterboxd_step_1'.tr(),
          'letterboxd_step_2'.tr(),
          'letterboxd_step_3'.tr(),
        ];
      default:
        return [];
    }
  }

  Map<String, dynamic> _getSourceInfo(String source) {
    switch (source) {
      case 'imdb':
        return {'name': 'IMDb', 'icon': Icons.movie, 'color': Colors.amber};
      case 'letterboxd':
        return {'name': 'Letterboxd', 'icon': Icons.local_movies, 'color': Colors.green};
      default:
        return {'name': '', 'icon': Icons.help, 'color': Colors.grey};
    }
  }

  Widget _buildInstructionStep(int stepNumber, String instruction, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              instruction,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
