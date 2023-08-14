import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NoInternet extends StatelessWidget {
  const NoInternet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "no_internet".tr(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
