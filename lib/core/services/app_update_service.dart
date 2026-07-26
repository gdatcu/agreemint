import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String releaseUrl;
  final bool hasUpdate;
  final String currentVersion;

  AppUpdateInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.releaseUrl,
    required this.hasUpdate,
    required this.currentVersion,
  });
}

class AppUpdateService {
  static const String _defaultVersion = '1.0.8';
  static const String _githubApiUrl =
      'https://api.github.com/repos/gdatcu/agreemint/releases/latest';

  /// Gets current installed app version dynamically.
  static Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty && info.version != '0.0.0') {
        return info.version;
      }
    } catch (e) {
      debugPrint('Error reading package info: $e');
    }
    return _defaultVersion;
  }

  /// Checks GitHub Releases API for new version availability.
  static Future<AppUpdateInfo?> checkForUpdates() async {
    try {
      final currentVer = await getCurrentVersion();
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

        final hasUpdate = _isVersionHigher(tagName, currentVer);

        return AppUpdateInfo(
          latestVersion: data['tag_name'] as String? ?? 'v$tagName',
          releaseNotes: releaseNotes,
          apkDownloadUrl: apkUrl,
          releaseUrl: htmlUrl,
          hasUpdate: hasUpdate,
          currentVersion: currentVer,
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

  void _handleUpdateClick() {
    if (_updateInfo == null) return;

    if (kIsWeb) {
      AppUpdateService.launchUpdate(_updateInfo!.releaseUrl);
    } else {
      AppUpdateService.launchUpdate(_updateInfo!.apkDownloadUrl);

      // Show clear guidance dialog for Android installation
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.download_for_offline, size: 40, color: Colors.deepPurple),
          title: Text('Updating to ${_updateInfo!.latestVersion}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. The APK is downloading in your mobile browser.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('2. When complete, open your Downloads or tap the notification to install.'),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Text(
                '⚠️ Debug Build Note:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              SizedBox(height: 4),
              Text(
                'If you previously installed the app via terminal (flutter run debug mode), Android will block the update due to signature mismatch.\n\nPlease uninstall the debug app first if installation fails.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK, Got It'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _updateInfo == null || !_updateInfo!.hasUpdate) {
      return const SizedBox.shrink();
    }

    final isWeb = kIsWeb;
    final buttonLabel = isWeb ? 'View Release' : 'Update APK';

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
            onPressed: _handleUpdateClick,
            child: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
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
