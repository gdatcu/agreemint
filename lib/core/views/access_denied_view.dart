import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/mentor_auth_controller.dart';

class AccessDeniedView extends ConsumerStatefulWidget {
  const AccessDeniedView({super.key});

  @override
  ConsumerState<AccessDeniedView> createState() => _AccessDeniedViewState();
}

class _AccessDeniedViewState extends ConsumerState<AccessDeniedView> {
  final _passcodeController = TextEditingController();
  bool _isLoggingIn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _showLoginDialog() async {
    _passcodeController.clear();
    _errorMessage = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Mentor Authentication'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your security passcode to unlock management features:',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passcodeController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mentor Security Passcode',
                      hintText: 'ex: qualiadept',
                      errorText: _errorMessage,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) async {
                      await _handleLogin(setDialogState);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoggingIn
                      ? null
                      : () async {
                          await _handleLogin(setDialogState);
                        },
                  child: _isLoggingIn
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unlock Dashboard'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogin(
      void Function(void Function()) setDialogState) async {
    setDialogState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(mentorAuthControllerProvider.notifier)
        .login(_passcodeController.text);

    if (success) {
      if (mounted) {
        Navigator.of(context).pop();
        context.go('/programs');
      }
    } else {
      setDialogState(() {
        _isLoggingIn = false;
        _errorMessage = 'Invalid passcode. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(mentorAuthControllerProvider);
    final isAuth = authState.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QualiAdept Portal'),
        centerTitle: true,
        actions: [
          if (isAuth)
            TextButton.icon(
              onPressed: () {
                ref.read(mentorAuthControllerProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout, color: Colors.white70),
              label: const Text('Sign Out', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: isAuth
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              size: 64,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Mentor Session Active',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You are currently signed in as Mentor. You have full authorized access to management tools, student records, and program settings.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => context.go('/programs'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                ),
                                icon: const Icon(Icons.dashboard),
                                label: const Text('Go to Programs Dashboard'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(
                                          mentorAuthControllerProvider.notifier)
                                      .logout();
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_person_outlined,
                              size: 64,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Portal Access Notice',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This web portal is designed for student contract review & electronic signing.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Section 1: For Students
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.school, color: Colors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Are you a Student?\nPlease open the direct contract signing link provided by your mentor (e.g. apps.qualiadept.eu/agreemint/#/sign/<contract_id>).',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Section 2: For Mentors/Admins
                          Text(
                            'Are you the Program Creator / Mentor?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showLoginDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                            ),
                            icon: const Icon(Icons.key),
                            label: const Text('Mentor Passcode Login'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
