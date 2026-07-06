import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Decides whether the running build is too old to keep using the app.
///
/// The minimum supported build number is published in Remote Config under
/// [_minBuildKey]. This is the force-upgrade gate that lets us retire old
/// builds — e.g. those that still call the third-party APIs directly with
/// now-rotated keys (see [backend_service]).
class VersionGateService {
  static const String _minBuildKey = 'min_required_build';

  /// True when the current build is older than the minimum required build.
  ///
  /// Fails **open** (returns false) on any error — a network hiccup, a missing
  /// config value, or an unparseable build number must never lock a user out.
  static Future<bool> isUpdateRequired() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        // Debug builds refetch every launch so config changes (e.g. bumping
        // min_required_build to test the gate) take effect without a reinstall.
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 6),
      ));
      // Default 0 means "no minimum" until we set a value in the console.
      await rc.setDefaults({_minBuildKey: 0});
      await rc.fetchAndActivate();

      final minBuild = rc.getInt(_minBuildKey);
      if (minBuild <= 0) return false;

      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;
      // If we can't determine our own build, don't block.
      if (currentBuild == 0) return false;

      return currentBuild < minBuild;
    } catch (_) {
      return false;
    }
  }
}
