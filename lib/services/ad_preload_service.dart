import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:watch_next/utils/secrets.dart';

/// Singleton that preloads a NativeAd as early as possible (e.g. when the
/// user starts typing a query) so it is already ready when
/// RecommendationLoadingPage is shown.
class AdPreloadService {
  AdPreloadService._();
  static final AdPreloadService instance = AdPreloadService._();

  NativeAd? _ad;
  bool _isLoaded = false;
  bool _isLoading = false;

  // Cached colours — set once when preload is triggered from a BuildContext
  Color? _bgColor;

  bool get isLoaded => _isLoaded;

  /// Call this as early as possible (e.g. when user starts typing).
  /// Safe to call multiple times — will no-op if already loading/loaded.
  void preload(BuildContext context) {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    _bgColor = Theme.of(context).colorScheme.primary;
    _buildAndLoad();
  }

  /// Consume the preloaded ad. Returns the ad and marks it as consumed so the
  /// next call to [preload] will load a fresh one.
  NativeAd? consume() {
    final ad = _ad;
    _ad = null;
    _isLoaded = false;
    _isLoading = false;
    return ad;
  }

  void _buildAndLoad() {
    final adUnitId = Platform.isAndroid ? androidAd : iosAd;
    _ad = NativeAd(
      adUnitId: adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _isLoaded = true;
          _isLoading = false;
          debugPrint('✅ AdPreloadService: ad ready');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ AdPreloadService: failed ${error.code} – ${error.message}');
          ad.dispose();
          _ad = null;
          _isLoaded = false;
          _isLoading = false;
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: _bgColor ?? Colors.black,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: Colors.orange,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.orange,
          backgroundColor: _bgColor ?? Colors.black,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: _bgColor ?? Colors.black,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey.shade400,
          backgroundColor: _bgColor ?? Colors.black,
          style: NativeTemplateFontStyle.normal,
          size: 13.0,
        ),
      ),
    )..load();
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
    _isLoading = false;
  }
}
