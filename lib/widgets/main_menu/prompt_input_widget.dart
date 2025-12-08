import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PromptInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey textFieldKey;
  final bool isLongEnough;
  final bool enableLoading;
  final VoidCallback? onGoPressed;

  const PromptInputWidget({
    super.key,
    required this.controller,
    required this.textFieldKey,
    required this.isLongEnough,
    required this.enableLoading,
    required this.onGoPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: textFieldKey,
              autofocus: false,
              showCursor: true,
              maxLines: 4,
              minLines: 1,
              controller: controller,
              cursorColor: Colors.orange,
              style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    fontSize: 15,
                    height: 1.4,
                  ),
              decoration: InputDecoration(
                hintText: "hint".tr(),
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.tertiary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _GoButton(
            isLongEnough: isLongEnough,
            enableLoading: enableLoading,
            onPressed: onGoPressed,
          ),
        ],
      ),
    );
  }
}

class _GoButton extends StatelessWidget {
  final bool isLongEnough;
  final bool enableLoading;
  final VoidCallback? onPressed;

  const _GoButton({
    required this.isLongEnough,
    required this.enableLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        gradient: isLongEnough && !enableLoading
            ? LinearGradient(
                colors: [Colors.orange, Colors.orange[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enableLoading
            ? Colors.orange.withValues(alpha: 0.7)
            : (isLongEnough ? null : Theme.of(context).colorScheme.tertiary),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isLongEnough && !enableLoading
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLongEnough && !enableLoading ? onPressed : null,
          child: Center(
            child: enableLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.arrow_forward_rounded,
                    size: 24,
                    color: isLongEnough ? Colors.white : Colors.grey[600],
                  ),
          ),
        ),
      ),
    );
  }
}
