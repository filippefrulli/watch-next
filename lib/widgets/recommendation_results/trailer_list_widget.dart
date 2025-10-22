import 'package:cached_network_image/cached_network_image.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/objects/trailer.dart';

class TrailerListWidget extends StatelessWidget {
  final List<TrailerResults> trailerList;
  final List<String> trailerImages;
  final Function(String) onTrailerTap;

  const TrailerListWidget({
    super.key,
    required this.trailerList,
    required this.trailerImages,
    required this.onTrailerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (trailerList.isEmpty || trailerImages.isEmpty) {
      return Container();
    }

    return DelayedDisplay(
      child: SizedBox(
        height: 142,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: trailerList.length,
          itemBuilder: (context, index) {
            final trailerUrl = trailerList[index].key ?? '';
            final title = trailerList[index].name ?? '';
            final thumbnail = trailerImages[index];

            return TextButton(
              onPressed: () => onTrailerTap(trailerUrl),
              child: SizedBox(
                width: 150,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                      height: 86,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 21 / 9,
                          child: CachedNetworkImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
