import 'package:flutter/material.dart';

class DividerWidget extends StatelessWidget {
  // make these final
  final double padding;
  final double height;

  // constructor
  const DividerWidget({super.key, required this.padding, required this.height});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: padding,
        right: padding,
      ),
      child: Divider(
        height: height,
        color: Colors.grey[700],
      ),
    );
  }
}
