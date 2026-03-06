import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows a dialog to pick an integer rating 1–10 and an optional watch date.
/// Returns a [RatingResult] if the user confirms, or null if cancelled.
class RatingDialog extends StatefulWidget {
  final String title;
  final int? initialRating;
  final DateTime? initialDate;

  const RatingDialog({
    super.key,
    required this.title,
    this.initialRating,
    this.initialDate,
  });

  static Future<RatingResult?> show(
    BuildContext context, {
    required String title,
    int? initialRating,
    DateTime? initialDate,
  }) {
    return showDialog<RatingResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        title: title,
        initialRating: initialRating,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int? _rating;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _date = widget.initialDate ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: Colors.orange,
            onPrimary: Colors.black,
            surface: Theme.of(context).colorScheme.tertiary,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.tertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'rate_title'.tr(),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMDb-style star row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (i) {
              final value = i + 1;
              final filled = _rating != null && value <= _rating!;
              return GestureDetector(
                onTap: () => setState(() => _rating = value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? Colors.orange : Colors.grey[600],
                    size: 28,
                  ),
                ),
              );
            }),
          ),
          // Rating label
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _rating == null
                  ? Text(
                      'your_rating'.tr(),
                      key: const ValueKey('empty'),
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    )
                  : Text(
                      '$_rating / 10',
                      key: ValueKey(_rating),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          // Date watched picker
          Text(
            'date_watched'.tr(),
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[700]!, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Colors.orange, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('d MMM yyyy').format(_date),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_outlined, color: Colors.grey[500], size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _rating == null
              ? null
              : () => Navigator.of(context).pop(RatingResult(rating: _rating!, dateWatched: _date)),
          child: Text(
            'confirm'.tr(),
            style: TextStyle(
              color: _rating == null ? Colors.grey[600] : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class RatingResult {
  final int rating;
  final DateTime dateWatched;

  const RatingResult({required this.rating, required this.dateWatched});
}
