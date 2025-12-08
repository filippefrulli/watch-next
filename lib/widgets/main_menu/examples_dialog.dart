import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ExamplesDialog extends StatelessWidget {
  final bool isMovie;

  const ExamplesDialog({
    super.key,
    required this.isMovie,
  });

  static void show(BuildContext context, {required bool isMovie}) {
    showDialog(
      context: context,
      builder: (_) => ExamplesDialog(isMovie: isMovie),
    );
  }

  @override
  Widget build(BuildContext context) {
    final examples = isMovie
        ? [
            "example_1".tr(),
            "example_2".tr(),
            "example_3".tr(),
            "example_4".tr(),
            "example_5".tr(),
          ]
        : [
            "example_show_1".tr(),
            "example_show_2".tr(),
            "example_show_3".tr(),
            "example_show_4".tr(),
            "example_show_5".tr(),
          ];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: examples.map((text) => _ExampleItem(text: text)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "need_inspiration".tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleItem extends StatelessWidget {
  final String text;

  const _ExampleItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.orange,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExamplesButton extends StatelessWidget {
  final bool isMovie;

  const ExamplesButton({
    super.key,
    required this.isMovie,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.grey[500],
          borderRadius: BorderRadius.circular(15),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.help_outline_rounded,
            color: Colors.black,
            size: 26,
          ),
          onPressed: () => ExamplesDialog.show(context, isMovie: isMovie),
        ),
      ),
    );
  }
}
