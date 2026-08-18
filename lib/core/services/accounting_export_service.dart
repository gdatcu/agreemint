import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'frankfurter_service.dart';

class AccountingRecord {
  final String paymentDate;
  final String clientName;
  final String clientType;
  final String cuiCif;
  final String regCom;
  final String programName;
  final String installmentInfo;
  final double amountPaid;
  final String currency;
  final double amountPaidInRon;
  final String paymentMethod;
  final String soloInvoiceNumber;
  final String soloInvoiceUrl;
  final String receiptUrl;

  const AccountingRecord({
    required this.paymentDate,
    required this.clientName,
    required this.clientType,
    required this.cuiCif,
    required this.regCom,
    required this.programName,
    required this.installmentInfo,
    required this.amountPaid,
    required this.currency,
    required this.amountPaidInRon,
    required this.paymentMethod,
    required this.soloInvoiceNumber,
    required this.soloInvoiceUrl,
    required this.receiptUrl,
  });
}

class AccountingExportService {
  /// Fetches paid/partial payment records for accounting export
  static Future<List<AccountingRecord>> fetchAccountingRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final client = Supabase.instance.client;
    final liveEurRate = await FrankfurterService.getEurToRonRate();

    final response = await client
        .from('payments')
        .select(
            'amount_paid, paid_at, due_date, status, payment_method, installment_number, receipt_url, solo_invoice_url, solo_invoice_number, enrollments(programs(name, currency), students(name, client_type, cui, reg_com), contracts(status))')
        .or('status.eq.Paid,status.eq.Partial');

    final List<AccountingRecord> records = [];

    for (final row in response as List<dynamic>) {
      final enrollmentRaw = row['enrollments'];
      Map<String, dynamic>? enrollmentJson;
      if (enrollmentRaw is Map<String, dynamic>) {
        enrollmentJson = enrollmentRaw;
      } else if (enrollmentRaw is List && enrollmentRaw.isNotEmpty) {
        enrollmentJson = enrollmentRaw.first as Map<String, dynamic>?;
      }

      if (enrollmentJson == null) continue;

      // Filter out refunded/retired contracts
      final contractRaw = enrollmentJson['contracts'];
      Map<String, dynamic>? contractJson;
      if (contractRaw is Map<String, dynamic>) {
        contractJson = contractRaw;
      } else if (contractRaw is List && contractRaw.isNotEmpty) {
        contractJson = contractRaw.first as Map<String, dynamic>?;
      }

      final contractStatus = contractJson?['status'] as String?;
      if (contractStatus == 'Refunded' ||
          contractStatus == 'Cancelled' ||
          contractStatus == 'Retired' ||
          contractStatus == 'Withdrawn' ||
          contractStatus == 'Archived') {
        continue;
      }

      final payDateStr = (row['paid_at'] as String?) ?? (row['due_date'] as String?);
      if (payDateStr == null || payDateStr.isEmpty) continue;

      final payDate = DateTime.tryParse(payDateStr);
      if (payDate != null) {
        if (startDate != null && payDate.isBefore(startDate)) continue;
        if (endDate != null && payDate.isAfter(endDate)) continue;
      }

      // Student info
      final studentRaw = enrollmentJson['students'];
      Map<String, dynamic>? studentJson;
      if (studentRaw is Map<String, dynamic>) {
        studentJson = studentRaw;
      } else if (studentRaw is List && studentRaw.isNotEmpty) {
        studentJson = studentRaw.first as Map<String, dynamic>?;
      }

      final clientName = (studentJson?['name'] as String?) ?? 'Client Incognito';
      final clientType = (studentJson?['client_type'] as String?) ?? 'PF';
      final cuiCif = (studentJson?['cui'] as String?) ?? '-';
      final regCom = (studentJson?['reg_com'] as String?) ?? '-';

      // Program info
      final programRaw = enrollmentJson['programs'];
      Map<String, dynamic>? programJson;
      if (programRaw is Map<String, dynamic>) {
        programJson = programRaw;
      } else if (programRaw is List && programRaw.isNotEmpty) {
        programJson = programRaw.first as Map<String, dynamic>?;
      }

      final programName = (programJson?['name'] as String?) ?? 'Program Mentorat';
      final currency = (programJson?['currency'] as String? ?? 'RON').toUpperCase();

      final amountPaid = (row['amount_paid'] as num?)?.toDouble() ?? 0.0;
      final amountInRon = currency == 'EUR' ? amountPaid * liveEurRate : amountPaid;

      final instNum = (row['installment_number'] as num?)?.toInt() ?? 1;
      final paymentMethod = (row['payment_method'] as String?) ?? 'Transfer Bancar';
      final soloNum = (row['solo_invoice_number'] as String?) ?? '-';
      final soloUrl = (row['solo_invoice_url'] as String?) ?? '';
      final receiptUrl = (row['receipt_url'] as String?) ?? '';

      records.add(AccountingRecord(
        paymentDate: payDateStr.length >= 10 ? payDateStr.substring(0, 10) : payDateStr,
        clientName: clientName,
        clientType: clientType,
        cuiCif: cuiCif,
        regCom: regCom,
        programName: programName,
        installmentInfo: 'Transa $instNum',
        amountPaid: amountPaid,
        currency: currency,
        amountPaidInRon: amountInRon,
        paymentMethod: paymentMethod,
        soloInvoiceNumber: soloNum,
        soloInvoiceUrl: soloUrl,
        receiptUrl: receiptUrl,
      ));
    }

    records.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return records;
  }

  /// Converts accounting records into a CSV string with header
  static String generateCsvContent(List<AccountingRecord> records) {
    final buffer = StringBuffer();

    // CSV Header (Romanian Accounting & ANAF Standard)
    buffer.writeln(
        'Data Platii,Nume Client / Firma,Tip Client,CUI / CIF,Reg. Com.,Program Mentorat,Transa,Suma Platita,Moneda,Echivalent RON,Metoda Plata,Numar Factura SOLO,URL Factura SOLO,URL Chitanta');

    for (final r in records) {
      final safeName = _escapeCsv(r.clientName);
      final safeProgram = _escapeCsv(r.programName);
      final safeCui = _escapeCsv(r.cuiCif);
      final safeRegCom = _escapeCsv(r.regCom);
      final safeSoloNum = _escapeCsv(r.soloInvoiceNumber);
      final safeMethod = _escapeCsv(r.paymentMethod);

      buffer.writeln(
          '${r.paymentDate},$safeName,${r.clientType},$safeCui,$safeRegCom,$safeProgram,${r.installmentInfo},${r.amountPaid.toStringAsFixed(2)},${r.currency},${r.amountPaidInRon.toStringAsFixed(2)},$safeMethod,$safeSoloNum,${r.soloInvoiceUrl},${r.receiptUrl}');
    }

    return buffer.toString();
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Triggers CSV file export on Web (direct download) or Mobile (share sheet)
  static Future<void> exportAndShareCsv(List<AccountingRecord> records,
      {String filename = 'Agreemint_Accounting_Export.csv'}) async {
    final csvContent = generateCsvContent(records);

    if (kIsWeb) {
      final encodedUri = Uri.encodeComponent(csvContent);
      final Uri dataUri =
          Uri.parse('data:text/csv;charset=utf-8,%EF%BB%BF$encodedUri');
      await launchUrl(dataUri);
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      // Write with UTF-8 BOM byte sequence so Excel opens Romanian diacritics natively
      final bomBytes = [0xEF, 0xBB, 0xBF];
      final contentBytes = utf8.encode(csvContent);
      await file.writeAsBytes([...bomBytes, ...contentBytes]);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Export Contabilitate Agreemint',
      );
    }
  }
}
