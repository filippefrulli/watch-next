import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            "error_occurred".tr(),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              "Try Again",
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
