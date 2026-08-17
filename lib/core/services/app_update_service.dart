import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _defaultVersion = '1.0.10';
  static const String _dismissedKey = 'dismissed_update_version';
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

  /// Checks if a version update banner was previously dismissed by the user.
  static Future<bool> isVersionDismissed(String latestVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_dismissedKey);
      return saved == latestVersion;
    } catch (_) {
      return false;
    }
  }

  /// Saves a dismissed version string to SharedPreferences.
  static Future<void> saveDismissedVersion(String latestVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedKey, latestVersion);
    } catch (e) {
      debugPrint('Error saving dismissed version: $e');
    }
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
        final rawTag = data['tag_name'] as String? ?? '';
        final tagName = rawTag.replaceAll('v', '').trim();
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

        final fullTag = rawTag.isNotEmpty ? rawTag : 'v$tagName';
        final isDismissed = await isVersionDismissed(fullTag);
        final hasUpdate = !isDismissed && isVersionHigher(tagName, currentVer);

        return AppUpdateInfo(
          latestVersion: fullTag,
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

  @visibleForTesting
  static bool isVersionHigher(String latest, String current) {
    try {
      final lClean = latest.replaceAll('v', '').trim();
      final cClean = current.replaceAll('v', '').trim();

      final lSem = lClean.split('+')[0].split('-')[0];
      final cSem = cClean.split('+')[0].split('-')[0];

      final lParts = lSem.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = cSem.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> launchUpdate(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (_) {
      try {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('Could not launch update URL $url: $e');
        return false;
      }
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

  void _dismissBanner() async {
    if (_updateInfo != null) {
      await AppUpdateService.saveDismissedVersion(_updateInfo!.latestVersion);
    }
    if (mounted) {
      setState(() {
        _dismissed = true;
      });
    }
  }

  void _handleUpdateClick() async {
    if (_updateInfo == null) return;

    if (kIsWeb) {
      AppUpdateService.launchUpdate(_updateInfo!.releaseUrl);
      return;
    }

    int progress = 0;
    String statusMessage = 'Downloading update package...';
    bool isFailed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            icon: const Icon(Icons.system_update_rounded, size: 40, color: Colors.deepPurple),
            title: Text('Updating to ${_updateInfo!.latestVersion}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isFailed) ...[
                  LinearProgressIndicator(
                    value: progress > 0 ? progress / 100.0 : null,
                    color: Colors.deepPurple,
                    backgroundColor: Colors.deepPurple.shade50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$progress%',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ] else ...[
                  const Text(
                    'Direct in-app download was interrupted. Tap "Open Release Page" to download manually.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.deepOrange),
                  ),
                ],
              ],
            ),
            actions: [
              if (isFailed)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    AppUpdateService.launchUpdate(_updateInfo!.releaseUrl);
                  },
                  child: const Text('Open Release Page'),
                ),
              if (!isFailed)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Cancel'),
                ),
            ],
          );
        },
      ),
    );

    try {
      OtaUpdate().execute(
        _updateInfo!.apkDownloadUrl,
        destinationFilename: 'agreemint_update.apk',
      ).listen((OtaEvent event) {
        if (!mounted) return;
        if (event.status == OtaStatus.DOWNLOADING) {
          final p = int.tryParse(event.value ?? '0') ?? 0;
          progress = p;
          statusMessage = 'Downloading update package... ($progress%)';
        } else if (event.status == OtaStatus.INSTALLING) {
          progress = 100;
          statusMessage = 'Launching Android Package Installer...';
        } else if (event.status == OtaStatus.ALREADY_RUNNING_ERROR ||
            event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR ||
            event.status == OtaStatus.INTERNAL_ERROR ||
            event.status == OtaStatus.DOWNLOAD_ERROR) {
          isFailed = true;
          statusMessage = 'Direct download failed: ${event.status}';
        }
      }, onError: (e) {
        isFailed = true;
        statusMessage = 'Error during update: $e';
      });
    } catch (e) {
      AppUpdateService.launchUpdate(_updateInfo!.apkDownloadUrl);
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
            onPressed: _dismissBanner,
          ),
        ],
      ),
    );
  }
}

