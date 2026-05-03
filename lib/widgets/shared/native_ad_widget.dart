import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:watch_next/services/native_ad_pool.dart';
import 'package:watch_next/services/purchase_service.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/pages/settings_page.dart';
import 'package:watch_next/utils/app_colors.dart';

class NativeAdWidget extends StatefulWidget {
  final bool showRemoveAdsLink;
  const NativeAdWidget({super.key, this.showRemoveAdsLink = true});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted || PurchaseService.adsRemoved) return;
    _loadStarted = true;

    // Try the pre-loaded pool first so the ad shows instantly.
    final pooled = NativeAdPool.instance.consume();
    if (pooled != null) {
      _nativeAd = pooled;
      setState(() => _isLoaded = true);
      return;
    }

    // Pool was empty — load on demand as fallback.
    final bgColor = Theme.of(context).colorScheme.primary;
    _nativeAd = NativeAd(
      adUnitId: Platform.isAndroid ? androidAd : iosAd,
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _nativeAd = null;
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: bgColor,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: AppColors.defaults.accent,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.defaults.accent,
          backgroundColor: bgColor,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: bgColor,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: bgColor,
          style: NativeTemplateFontStyle.normal,
          size: 13.0,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PurchaseService.adsRemovedNotifier,
      builder: (context, adsRemoved, _) {
        if (adsRemoved || !_isLoaded || _nativeAd == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[600]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ad',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sponsored',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 320,
                decoration: BoxDecoration(
                  border: Border.all(color: context.appColors.surface),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AdWidget(ad: _nativeAd!),
                ),
              ),
              if (widget.showRemoveAdsLink) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                  child: Text(
                    'Remove ads',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
