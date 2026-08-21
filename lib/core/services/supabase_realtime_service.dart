import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/payments/controllers/payment_controller.dart';
import '../../features/prospects/controllers/prospect_controller.dart';

class SupabaseRealtimeService {
  static RealtimeChannel? _contractsChannel;
  static bool _isListening = false;

  /// Initializes live real-time postgres subscription on the `contracts` table.
  /// Automatically refreshes active Riverpod providers and shows in-app toast when a contract is signed.
  static void initialize(BuildContext context, WidgetRef ref) {
    if (_isListening) return;

    try {
      final client = Supabase.instance.client;
      _contractsChannel = client.channel('public:contracts').onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'contracts',
        callback: (payload) {
          final newRecord = payload.newRecord;
          final oldRecord = payload.oldRecord;

          // Check if contract became signed / received signed_pdf_url
          final wasSigned = oldRecord['signed_pdf_url'] != null || oldRecord['status'] == 'FullySigned';
          final isSigned = newRecord['signed_pdf_url'] != null || newRecord['status'] == 'FullySigned';

          if (!wasSigned && isSigned) {
            final contractNum = newRecord['contract_number'] ?? '';
            
            // 1. Invalidate Riverpod providers to refresh payments & prospects live
            ref.invalidate(globalPendingPaymentsControllerProvider);
            ref.invalidate(prospectsControllerProvider);
            
            // 2. Display live green notification toast on mentor screen
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '🎉 Contract ${contractNum.isNotEmpty ? '#$contractNum' : ''} a fost semnat de cursant în timp real!',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 6),
                ),
              );
            }
          }
        },
      );

      _contractsChannel?.subscribe();
      _isListening = true;
    } catch (e) {
      debugPrint('Failed to initialize Supabase Realtime listener: $e');
    }
  }

  /// Disconnects the realtime channel listener.
  static void dispose() {
    if (_contractsChannel != null) {
      Supabase.instance.client.removeChannel(_contractsChannel!);
      _contractsChannel = null;
      _isListening = false;
    }
  }
}
