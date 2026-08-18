import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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
        bool hasApkAsset = false;
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            if (asset is Map<String, dynamic> &&
                (asset['name'] as String? ?? '').toLowerCase().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String? ?? htmlUrl;
              hasApkAsset = true;
              break;
            }
          }
        }

        final fullTag = rawTag.isNotEmpty ? rawTag : 'v$tagName';
        final isDismissed = await isVersionDismissed(fullTag);
        final isHigher = isVersionHigher(tagName, currentVer);
        final hasUpdate = !isDismissed && isHigher && (kIsWeb || hasApkAsset);

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

    if (kIsWeb || !_updateInfo!.apkDownloadUrl.toLowerCase().endsWith('.apk')) {
      AppUpdateService.launchUpdate(_updateInfo!.releaseUrl);
      return;
    }

    int progress = 0;
    String statusMessage = 'Connecting to download server...';
    bool isFailed = false;
    bool isComplete = false;
    bool isCancelled = false;
    http.Client? client;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            icon: Icon(
              isComplete ? Icons.check_circle_outline : Icons.system_update_rounded,
              size: 40,
              color: isComplete ? Colors.green : Colors.deepPurple,
            ),
            title: Text(isComplete ? 'Download Complete' : 'Updating to ${_updateInfo!.latestVersion}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isFailed && !isComplete) ...[
                  LinearProgressIndicator(
                    value: progress > 0 ? progress / 100.0 : null,
                    color: Colors.deepPurple,
                    backgroundColor: Colors.deepPurple.shade50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$progress%',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ] else if (isComplete) ...[
                  const Text(
                    'Update downloaded! Launching Android Package Installer...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green),
                  ),
                ] else ...[
                  Text(
                    statusMessage.isNotEmpty
                        ? statusMessage
                        : 'Direct in-app download was interrupted. Tap "Open Release Page" to download manually.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.deepOrange),
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
              if (!isComplete)
                TextButton(
                  onPressed: () {
                    isCancelled = true;
                    client?.close();
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
      client = http.Client();
      final request = http.Request('GET', Uri.parse(_updateInfo!.apkDownloadUrl));
      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        final extDir =
            await getExternalStorageDirectory() ?? await getTemporaryDirectory();
        final filePath = '${extDir.path}/agreemint_update.apk';
        final file = File(filePath);
        final sink = file.openWrite();

        await for (final chunk in response.stream) {
          if (isCancelled) {
            await sink.close();
            if (await file.exists()) await file.delete();
            return;
          }
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            final p = ((receivedBytes / totalBytes) * 100).clamp(0, 100).toInt();
            final mbReceived = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
            final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
            progress = p;
            statusMessage = 'Downloading: $mbReceived MB / $mbTotal MB ($p%)';
          } else {
            final mbReceived = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
            statusMessage = 'Downloaded $mbReceived MB...';
          }
        }

        await sink.flush();
        await sink.close();

        if (!isCancelled) {
          isComplete = true;
          statusMessage = 'Triggering Android Installer...';
          const platform = MethodChannel('com.example.agreemint/installer');
          await platform.invokeMethod('installApk', {'filePath': filePath});
        }
      } else {
        isFailed = true;
        statusMessage = 'Download failed with status: ${response.statusCode}';
      }
    } catch (e) {
      if (!isCancelled) {
        isFailed = true;
        statusMessage = 'Download interrupted: $e';
      }
    } finally {
      client?.close();
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

