import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MoviePosterWidget extends StatelessWidget {
  // make these final
  final String poster;

  // constructor
  const MoviePosterWidget({super.key, required this.poster});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 360,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(25)),
          child: CachedNetworkImage(
            fit: BoxFit.contain,
            imageUrl: "https://image.tmdb.org/t/p/original//$poster",
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(11, 14, 23, 1),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }
}
