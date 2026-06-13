import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:watch_next/utils/secrets.dart';

/// Handles sharing a recommended title out of the app. Every share carries the
/// title's poster, a short promo line and a store link, turning a good
/// recommendation into an organic acquisition channel.
class ShareService {
  /// The platform-appropriate store URL for the app.
  static String get storeUrl => Platform.isIOS ? appStoreUrl : playStoreUrl;

  /// Shares a title with its poster image (when available) and [message].
  ///
  /// Downloads the poster to a temporary file so the share sheet shows a rich
  /// preview. Falls back to a text-only share if the image can't be fetched.
  static Future<void> shareMedia({
    required String title,
    String? posterPath,
    required String message,
  }) async {
    final files = <XFile>[];
    try {
      if (posterPath != null && posterPath.isNotEmpty) {
        final response = await http
            .get(Uri.parse('https://image.tmdb.org/t/p/w500$posterPath'))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/watch_next_share.jpg');
          await file.writeAsBytes(response.bodyBytes);
          files.add(XFile(file.path, mimeType: 'image/jpeg'));
        }
      }
    } catch (e) {
      log('Error preparing share image: $e');
    }

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: title,
        files: files.isEmpty ? null : files,
      ),
    );
  }
}
