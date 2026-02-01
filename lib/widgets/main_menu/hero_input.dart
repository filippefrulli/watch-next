import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HeroInput extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey textFieldKey;
  final bool isLongEnough;
  final bool enableLoading;
  final VoidCallback? onGoPressed;

  const HeroInput({
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLongEnough ? Colors.orange : Colors.orange.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(isLongEnough ? 0.25 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            key: textFieldKey,
            autofocus: false,
            showCursor: true,
            maxLines: 4,
            minLines: 3,
            controller: controller,
            cursorColor: Colors.orange,
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontSize: 16,
                  height: 1.5,
                ),
            decoration: InputDecoration(
              hintText: "hero_hint".tr(),
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                height: 1.5,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              border: InputBorder.none,
            ),
          ),
          // GO button row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _GoButton(
                  isLongEnough: isLongEnough,
                  enableLoading: enableLoading,
                  onPressed: onGoPressed,
                ),
              ],
            ),
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
    final isReady = isLongEnough && !enableLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 48,
      decoration: BoxDecoration(
        gradient: isReady
            ? LinearGradient(
                colors: [Colors.orange, Colors.orange[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isReady ? null : Colors.grey[700],
        borderRadius: BorderRadius.circular(14),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isReady ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: enableLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "go".tr(),
                          style: TextStyle(
                            color: isReady ? Colors.white : Colors.grey[400],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: isReady ? Colors.white : Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
