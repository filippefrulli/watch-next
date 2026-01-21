import 'package:flutter/material.dart';
import 'package:watch_next/utils/constants.dart';

class PrivacyPolicy extends StatelessWidget {
  // constructor
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(
          Icons.chevron_left,
          color: Colors.black,
          size: 32,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(privacyPolicy, style: Theme.of(context).textTheme.displaySmall),
        ),
      ),
    );
  }
}
