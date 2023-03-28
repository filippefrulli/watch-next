import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';

class RecommandationResultsPage extends StatefulWidget {
  const RecommandationResultsPage({Key? key}) : super(key: key);

  @override
  State<RecommandationResultsPage> createState() => _RecommandationResultsPageState();
}

int currentIndex = -1;

class _RecommandationResultsPageState extends State<RecommandationResultsPage> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: pageBody(),
      ),
    );
  }

  Widget pageBody() {
    return Container(
      child: Center(
        child: Text('here is your results'),
      ),
    );
  }
}
