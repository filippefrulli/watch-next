import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingStateWidget extends StatelessWidget {
  final bool nativeAdIsLoaded;
  final NativeAd? nativeAd;
  final bool askingGpt;
  final bool fetchingMovieInfo;
  final bool filtering;

  const LoadingStateWidget({
    super.key,
    required this.nativeAdIsLoaded,
    required this.nativeAd,
    required this.askingGpt,
    required this.fetchingMovieInfo,
    required this.filtering,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        if (nativeAdIsLoaded)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[800]!,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 320,
                      minHeight: 320,
                      maxWidth: 380,
                      maxHeight: 380,
                    ),
                    child: AdWidget(ad: nativeAd!),
                  ),
                ),
                Text(
                  'Advertisement',
                  style: TextStyle(color: Colors.grey[200], fontSize: 14),
                ),
              ],
            ),
          ),
        const SizedBox(height: 32),
        LoadingAnimationWidget.threeArchedCircle(
          color: Colors.orange,
          size: 50,
        ),
        const SizedBox(height: 24),
        if (askingGpt)
          Text(
            "generating".tr(),
            style: Theme.of(context).textTheme.displaySmall,
          ),
        if (fetchingMovieInfo)
          Text(
            "fetching".tr(),
            style: Theme.of(context).textTheme.displaySmall,
          ),
        if (filtering)
          Text(
            "filtering".tr(),
            style: Theme.of(context).textTheme.displaySmall,
          ),
        const Spacer(),
      ],
    );
  }
}
