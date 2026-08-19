import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import '../views/app_shell_view.dart';
import '../views/access_denied_view.dart';
import '../auth/mentor_auth_controller.dart';
import '../../features/programs/views/programs_view.dart';
import '../../features/programs/models/program_model.dart';
import '../../features/programs/controllers/program_controller.dart';
import '../../features/students/views/enrolled_students_view.dart';
import '../../features/students/models/enrollment_model.dart';
import '../../features/contracts/views/contract_signing_view.dart';
import '../../features/contracts/views/client_web_signature_view.dart';
import '../../features/payments/views/pending_dashboard_view.dart';
import '../../features/payments/views/payment_tracker_view.dart';
import '../../features/analytics/views/analytics_view.dart';
import '../../features/prospects/views/prospects_view.dart';
import '../../features/documents/views/doc_gateway_view.dart';
import '../../features/settings/views/business_settings_view.dart';

part 'app_router.g.dart';

/// Wrapper widget that fetches a [ProgramModel] by ID from Supabase when the
/// router cannot recover it from [GoRouterState.extra] (e.g. on a browser
/// reload or direct deep-link navigation).
class _ProgramLoader extends ConsumerWidget {
  final String programId;
  const _ProgramLoader({required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(programByIdProvider(programId));
    return programAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Failed to load program: $err')),
      ),
      data: (program) {
        if (program == null) {
          // Program ID not found – navigate back to the programs list.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/programs');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return EnrolledStudentsView(program: program);
      },
    );
  }
}

// Route constants for contracts
class AppRouter {
  static const String contractIdParam = 'contractId';
  static const String homeRoute = '/programs';
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(mentorAuthControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/programs',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isPublic = loc.startsWith('/sign/') || loc.startsWith('/view-doc') || loc == '/access-denied';
      if (isPublic) return null;

      final isAuth = authState.value ?? false;
      if (!isAuth) {
        return '/access-denied';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellView(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Programs
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/programs',
                builder: (context, state) => const ProgramsView(),
                routes: [
                  GoRoute(
                    path: ':programId/students',
                    builder: (context, state) {
                      final extra = state.extra;
                      final programId =
                          state.pathParameters['programId'] ?? '';
                      ProgramModel? program;
                      if (extra is ProgramModel) {
                        program = extra;
                      } else if (extra is Map) {
                        program = ProgramModel.fromJson(
                            Map<String, dynamic>.from(extra));
                      }

                      if (program == null) {
                        // extra not available (e.g. browser reload) –
                        // fetch the program from Supabase by path ID.
                        return _ProgramLoader(programId: programId);
                      }
                      return EnrolledStudentsView(program: program);
                    },
                    routes: [
                      GoRoute(
                        path: 'contract',
                        builder: (context, state) {
                          final extra = state.extra;
                          final programId =
                              state.pathParameters['programId'] ?? '';
                          EnrollmentModel? enrollment;
                          if (extra is EnrollmentModel) {
                            enrollment = extra;
                          } else if (extra is Map) {
                            enrollment = EnrollmentModel.fromJson(
                                Map<String, dynamic>.from(extra));
                          }

                          if (enrollment == null) {
                            // Redirect back to students list when enrollment
                            // is not in state (e.g. browser reload).
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              context.go(
                                  '/programs/$programId/students');
                            });
                            return const Scaffold(
                              body:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }
                          return ContractSigningView(enrollment: enrollment);
                        },
                      ),
                      GoRoute(
                        path: 'payments',
                        builder: (context, state) {
                          final extra = state.extra;
                          final programId =
                              state.pathParameters['programId'] ?? '';
                          EnrollmentModel? enrollment;
                          if (extra is EnrollmentModel) {
                            enrollment = extra;
                          } else if (extra is Map) {
                            enrollment = EnrollmentModel.fromJson(
                                Map<String, dynamic>.from(extra));
                          }

                          if (enrollment == null) {
                            // Redirect back to students list when enrollment
                            // is not in state (e.g. browser reload).
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              context.go(
                                  '/programs/$programId/students');
                            });
                            return const Scaffold(
                              body:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }
                          return PaymentTrackerView(enrollment: enrollment);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Pending Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payments',
                builder: (context, state) => const PendingDashboardView(),
              ),
            ],
          ),
          // Branch 3: Prospects / Follow-ups (Index 2)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/prospects',
                builder: (context, state) => const ProspectsView(),
              ),
            ],
          ),
          // Branch 4: Analytics (Index 3)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsView(),
              ),
            ],
          ),
        ],
      ),
      // Root-level route for client web signing (Standalone, no App Shell)
      GoRoute(
        path: '/sign/:contractId',
        builder: (context, state) {
          final contractId = state.pathParameters['contractId'];
          if (contractId == null) {
            return const Scaffold(
              body: Center(child: Text('Missing contract ID')),
            );
          }
          return ClientWebSignatureView(contractId: contractId);
        },
      ),
      // Root-level route for Access Denied / Mentor Authorization
      GoRoute(
        path: '/access-denied',
        builder: (context, state) => const AccessDeniedView(),
      ),
      // Root-level route for PIN Secure Document Gateway
      GoRoute(
        path: '/view-doc',
        builder: (context, state) {
          final pdfUrl = state.uri.queryParameters['url'] ?? '';
          final pin = state.uri.queryParameters['pin'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Document Securizat';
          return DocGatewayView(
            pdfUrl: pdfUrl,
            expectedPin: pin,
            docTitle: title,
          );
        },
      ),
      // Root-level route for Business & Contract Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const BusinessSettingsView(),
      ),
    ],
  );
}
