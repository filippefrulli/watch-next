import 'package:flutter/material.dart';

class DividerWidget extends StatelessWidget {
  // make these final
  final double padding;
  final double height;

  // constructor
  const DividerWidget({Key? key, required this.padding, required this.height}) : super(key: key);

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
