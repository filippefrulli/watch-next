import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ExamplesDialog extends StatelessWidget {
  final bool isMovie;

  const ExamplesDialog({
    super.key,
    required this.isMovie,
  });

  static void show(BuildContext context, {required bool isMovie}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: Colors.orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "need_inspiration".tr().split('\n').first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey[800], height: 1),
              // Examples list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: examples.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ExampleItem(
                    number: index + 1,
                    text: examples[index],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExampleItem extends StatelessWidget {
  final int number;
  final String text;

  const _ExampleItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w400,
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
