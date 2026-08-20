import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_update_service.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  final version = await AppUpdateService.getCurrentVersion();
  return version.startsWith('v') ? version : 'v$version';
});

class AppVersionChip extends ConsumerWidget {
  const AppVersionChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);

    return versionAsync.maybeWhen(
      data: (version) => InkWell(
        onTap: () => _showUpdateDialog(context, version),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(180),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(100),
              width: 1,
            ),
          ),
          child: Text(
            version,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  void _showUpdateDialog(BuildContext context, String currentVersion) async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<AppUpdateInfo?>(
              future: AppUpdateService.checkForUpdates(),
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final info = snapshot.data;
                final hasUpdate = info?.hasUpdate ?? false;

                return AlertDialog(
                  title: Row(
                    children: [
                      const Icon(Icons.system_update_rounded,
                          color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('Agreemint App ($currentVersion)'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading) ...[
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Checking GitHub for updates...',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ] else if (hasUpdate && info != null) ...[
                        Text(
                          '🚀 New Version Available: ${info.latestVersion}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        if (info.releaseNotes.isNotEmpty) ...[
                          const Text('Release Notes:',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha(120),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SingleChildScrollView(
                              child: Text(info.releaseNotes,
                                  style: const TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const Text(
                          '💡 Note for Android updates: If your app was originally installed from GitHub release, tapping Update will replace it in-place smoothly.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('You are on the latest version!'),
                          ],
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    if (hasUpdate && info != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Update Now'),
                        onPressed: () {
                          final targetUrl = info.apkDownloadUrl.isNotEmpty
                              ? info.apkDownloadUrl
                              : info.releaseUrl;
                          AppUpdateService.launchUpdate(targetUrl);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
