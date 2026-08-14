import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/app_update_service.dart';
import '../services/notification_service.dart';
import '../../features/payments/controllers/payment_controller.dart';

class AppShellView extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellView({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingState = ref.watch(globalPendingPaymentsControllerProvider);

    // Trigger Android / local push notification check when pending data arrives
    pendingState.whenData((payments) {
      NotificationService.checkAndNotifyOverduePayments(payments);
    });

    final overdueCount = pendingState.maybeWhen(
      data: (payments) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        return payments.where((p) {
          final due = DateTime(p.dueDate.year, p.dueDate.month, p.dueDate.day);
          return due.isBefore(today);
        }).length;
      },
      orElse: () => 0,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const UpdateCheckBanner(),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: overdueCount > 0
                ? Badge(
                    label: Text('$overdueCount'),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.payments_outlined),
                  )
                : const Icon(Icons.payments_outlined),
            selectedIcon: overdueCount > 0
                ? Badge(
                    label: Text('$overdueCount'),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.payments),
                  )
                : const Icon(Icons.payments),
            label: 'Pending',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
