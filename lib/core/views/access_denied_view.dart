import 'dart:async';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  // Rate limiting
  int _failedAttempts = 0;
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;
  static const int _maxAttempts = 5;
  static const int _lockoutDurationSeconds = 60;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  bool get _isLockedOut => _lockoutSecondsRemaining > 0;

  void _startLockout() {
    _lockoutSecondsRemaining = _lockoutDurationSeconds;
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockoutSecondsRemaining--;
        if (_lockoutSecondsRemaining <= 0) {
          _failedAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _showLoginDialog() async {
    _emailController.clear();
    _passwordController.clear();
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
                  Text('Mentor Login'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sign in with your mentor account credentials:',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) =>
                        FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) async {
                      if (!_isLockedOut) {
                        await _handleLogin(setDialogState);
                      }
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_isLockedOut) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer,
                              color: Colors.orange.shade800, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Too many failed attempts. Try again in ${_lockoutSecondsRemaining}s.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (_isLoggingIn || _isLockedOut)
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
                      : const Text('Sign In'),
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
    if (_isLockedOut) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setDialogState(() {
        _errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    setDialogState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    final error = await ref
        .read(mentorAuthControllerProvider.notifier)
        .login(email, password);

    if (error == null) {
      // Success
      if (mounted) {
        Navigator.of(context).pop();
        context.go('/programs');
      }
    } else {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _startLockout();
      }
      setDialogState(() {
        _isLoggingIn = false;
        _errorMessage = error;
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
              label: const Text('Sign Out',
                  style: TextStyle(color: Colors.white70)),
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
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
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
                                label:
                                    const Text('Go to Programs Dashboard'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(mentorAuthControllerProvider
                                          .notifier)
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
                                const Icon(Icons.school,
                                    color: Colors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Are you a Student?\nPlease open the direct contract signing link provided by your mentor.',
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
                            'Are you a Program Creator / Mentor?',
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
                            icon: const Icon(Icons.login),
                            label: const Text('Mentor Sign In'),
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
