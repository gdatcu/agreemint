import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String releaseUrl;
  final bool hasUpdate;

  AppUpdateInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.releaseUrl,
    required this.hasUpdate,
  });
}

class AppUpdateService {
  static const String currentVersion = '1.0.0';
  static const String _githubApiUrl =
      'https://api.github.com/repos/gdatcu/agreemint/releases/latest';

  /// Checks GitHub Releases API for new version availability.
  static Future<AppUpdateInfo?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String? ?? '').replaceAll('v', '');
        final releaseNotes = data['body'] as String? ?? '';
        final htmlUrl = data['html_url'] as String? ?? '';

        String apkUrl = htmlUrl;
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            if (asset is Map<String, dynamic> &&
                (asset['name'] as String? ?? '').endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String? ?? htmlUrl;
              break;
            }
          }
        }

        final hasUpdate = _isVersionHigher(tagName, currentVersion);

        return AppUpdateInfo(
          latestVersion: data['tag_name'] as String? ?? 'v$tagName',
          releaseNotes: releaseNotes,
          apkDownloadUrl: apkUrl,
          releaseUrl: htmlUrl,
          hasUpdate: hasUpdate,
        );
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
    return null;
  }

  static bool _isVersionHigher(String latest, String current) {
    try {
      final lParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> launchUpdate(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}

class UpdateCheckBanner extends ConsumerStatefulWidget {
  const UpdateCheckBanner({super.key});

  @override
  ConsumerState<UpdateCheckBanner> createState() => _UpdateCheckBannerState();
}

class _UpdateCheckBannerState extends ConsumerState<UpdateCheckBanner> {
  AppUpdateInfo? _updateInfo;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() async {
    final info = await AppUpdateService.checkForUpdates();
    if (mounted && info != null && info.hasUpdate) {
      setState(() {
        _updateInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _updateInfo == null || !_updateInfo!.hasUpdate) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.deepPurple.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'New Update Available (${_updateInfo!.latestVersion})!',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () =>
                AppUpdateService.launchUpdate(_updateInfo!.apkDownloadUrl),
            child: const Text('Update APK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}
