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
      data: (version) => Container(
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
      orElse: () => const SizedBox.shrink(),
    );
  }
}
