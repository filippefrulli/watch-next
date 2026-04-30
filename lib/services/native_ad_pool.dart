import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:watch_next/services/purchase_service.dart';
import 'package:watch_next/utils/secrets.dart';

// Pre-loads a pool of NativeAds at app start so they are ready instantly when
// a page with an ad is opened. The app is dark-only so the background colour
// is hardcoded instead of requiring a BuildContext during preload.
class NativeAdPool {
  NativeAdPool._();
  static final NativeAdPool instance = NativeAdPool._();

  static const int _poolSize = 3;
  static const Color _bgColor = Color(0xFF0E0E0E);

  final List<NativeAd> _ready = [];
  int _loading = 0;

  void init() {
    if (PurchaseService.adsRemoved) return;
    _refill();
  }

  /// Returns a loaded ad immediately, or null if none is ready yet.
  /// Triggers a refill after consumption.
  NativeAd? consume() {
    if (_ready.isEmpty) return null;
    final ad = _ready.removeAt(0);
    _refill();
    return ad;
  }

  void _refill() {
    final needed = _poolSize - _ready.length - _loading;
    for (var i = 0; i < needed; i++) {
      _loadOne();
    }
  }

  void _loadOne() {
    if (PurchaseService.adsRemoved) return;
    _loading++;
    NativeAd(
      adUnitId: Platform.isAndroid ? androidAd : iosAd,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _loading--;
          _ready.add(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, _) {
          _loading--;
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: _bgColor,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: Colors.orange,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.orange,
          backgroundColor: _bgColor,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: _bgColor,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: _bgColor,
          style: NativeTemplateFontStyle.normal,
          size: 13.0,
        ),
      ),
    )..load();
  }

  void dispose() {
    for (final ad in _ready) {
      ad.dispose();
    }
    _ready.clear();
  }
}
