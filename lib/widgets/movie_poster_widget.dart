import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MoviePosterWidget extends StatelessWidget {
  // make these final
  final String poster;

  // constructor
  const MoviePosterWidget({Key? key, required this.poster}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: poster,
      placeholderBuilder: (context, size, child) {
        return ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(15),
          ),
          child: Container(
            color: Theme.of(context).primaryColor,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(15),
        ),
        child: CachedNetworkImage(
          fit: BoxFit.fitHeight,
          imageUrl: "http://image.tmdb.org/t/p/original//$poster",
          placeholder: (context, url) => Container(
            color: const Color.fromRGBO(11, 14, 23, 1),
          ),
          errorWidget: (context, url, error) => Expanded(
            child: Container(
              color: Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }
}
