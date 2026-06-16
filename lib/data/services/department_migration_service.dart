import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';

/// Backfills a `departmentId` field onto every department document that is
/// currently missing it. The `departmentId` value equals the document's own
/// Firestore auto-generated document ID.
///
/// Run once from the AdminDepartmentsScreen after deploying this build.
/// Safe to run multiple times — already-backfilled documents are skipped.
///
/// Usage:
///   final service = DepartmentMigrationService();
///   final report = await service.run();
///   print(report.summary());
class DepartmentMigrationService {
  DepartmentMigrationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<DepartmentMigrationReport> run() async {
    developer.log('DeptMigration: starting', name: 'DeptMigration');

    // ── PART 1: Fetch all department documents ─────────────────────────────
    final snap =
        await _db.collection(AppConstants.departmentsCollection).get();

    developer.log(
      'DeptMigration: fetched ${snap.docs.length} department documents',
      name: 'DeptMigration',
    );

    for (final doc in snap.docs) {
      final data = doc.data();
      final existingField = data['departmentId'];
      developer.log(
        'DeptMigration [READ] id=${doc.id} fields=${data.keys.toList()} '
        'departmentId=${existingField ?? "<missing>"}',
        name: 'DeptMigration',
      );
    }

    // ── PART 2: Identify documents missing the field ───────────────────────
    final alreadyHasField = <DeptMigrationEntry>[];
    final missingField = <DeptMigrationEntry>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').trim();
      final storedId = data['departmentId'] as String?;

      final entry = DeptMigrationEntry(
        docId: doc.id,
        name: name,
        storedDepartmentId: storedId,
        allFieldKeys: data.keys.toList(),
      );

      if (storedId != null && storedId == doc.id) {
        alreadyHasField.add(entry);
        developer.log(
          'DeptMigration [SKIP] ${doc.id} — departmentId already correct',
          name: 'DeptMigration',
        );
      } else {
        missingField.add(entry);
        final reason = storedId == null
            ? 'field absent'
            : 'field present but value "$storedId" != doc id "${doc.id}"';
        developer.log(
          'DeptMigration [NEEDS UPDATE] ${doc.id} ("$name") — $reason',
          name: 'DeptMigration',
        );
      }
    }

    developer.log(
      'DeptMigration: ${alreadyHasField.length} already correct, '
      '${missingField.length} need update',
      name: 'DeptMigration',
    );

    // ── PART 3: Write departmentId to each missing document ────────────────
    final writeResults = <DeptMigrationWriteResult>[];

    for (final entry in missingField) {
      try {
        await _db
            .collection(AppConstants.departmentsCollection)
            .doc(entry.docId)
            .update({'departmentId': entry.docId});

        writeResults.add(DeptMigrationWriteResult(
          docId: entry.docId,
          name: entry.name,
          success: true,
        ));
        developer.log(
          'DeptMigration [WRITE OK] ${entry.docId} ("${entry.name}")',
          name: 'DeptMigration',
        );
      } catch (e, st) {
        writeResults.add(DeptMigrationWriteResult(
          docId: entry.docId,
          name: entry.name,
          success: false,
          error: '$e',
        ));
        developer.log(
          'DeptMigration [WRITE FAIL] ${entry.docId} ("${entry.name}"): $e',
          name: 'DeptMigration',
          error: e,
          stackTrace: st,
        );
        // Do not rethrow — continue processing remaining documents.
      }
    }

    // ── PART 4: Re-fetch and verify every document ─────────────────────────
    final verifySnap =
        await _db.collection(AppConstants.departmentsCollection).get();

    final verified = <DeptMigrationVerifyEntry>[];

    for (final doc in verifySnap.docs) {
      final data = doc.data();
      final storedId = data['departmentId'] as String?;
      final name = (data['name'] as String? ?? '').trim();

      final fieldPresent = storedId != null;
      final matches = storedId == doc.id;
      final fieldKeys = data.keys.toList();

      // Check that the original fields still exist (no extra fields were
      // added or removed beyond departmentId).
      final originalEntry = snap.docs
          .where((d) => d.id == doc.id)
          .map((d) => d.data().keys.toSet())
          .firstOrNull;
      final noFieldsLost =
          originalEntry == null || originalEntry.every(fieldKeys.contains);

      verified.add(DeptMigrationVerifyEntry(
        docId: doc.id,
        name: name,
        storedDepartmentId: storedId,
        fieldPresent: fieldPresent,
        matches: matches,
        noFieldsLost: noFieldsLost,
        currentFieldKeys: fieldKeys,
      ));

      if (fieldPresent && matches && noFieldsLost) {
        developer.log(
          'DeptMigration [VERIFY OK] ${doc.id} ("$name") — departmentId="$storedId"',
          name: 'DeptMigration',
        );
      } else {
        developer.log(
          'DeptMigration [VERIFY FAIL] ${doc.id} ("$name") — '
          'fieldPresent=$fieldPresent matches=$matches noFieldsLost=$noFieldsLost '
          'storedId=${storedId ?? "<null>"}',
          name: 'DeptMigration',
        );
      }
    }

    final report = DepartmentMigrationReport(
      totalDocuments: snap.docs.length,
      alreadyCorrect: alreadyHasField,
      neededUpdate: missingField,
      writeResults: writeResults,
      verifyEntries: verified,
    );

    developer.log(report.summary(), name: 'DeptMigration');
    return report;
  }
}

// ─── Value types (all public — exposed through DepartmentMigrationReport) ──

class DeptMigrationEntry {
  const DeptMigrationEntry({
    required this.docId,
    required this.name,
    required this.storedDepartmentId,
    required this.allFieldKeys,
  });
  final String docId;
  final String name;
  final String? storedDepartmentId;
  final List<String> allFieldKeys;
}

class DeptMigrationWriteResult {
  const DeptMigrationWriteResult({
    required this.docId,
    required this.name,
    required this.success,
    this.error,
  });
  final String docId;
  final String name;
  final bool success;
  final String? error;
}

class DeptMigrationVerifyEntry {
  const DeptMigrationVerifyEntry({
    required this.docId,
    required this.name,
    required this.storedDepartmentId,
    required this.fieldPresent,
    required this.matches,
    required this.noFieldsLost,
    required this.currentFieldKeys,
  });
  final String docId;
  final String name;
  final String? storedDepartmentId;
  final bool fieldPresent;
  final bool matches;
  final bool noFieldsLost;
  final List<String> currentFieldKeys;
  bool get fullyValid => fieldPresent && matches && noFieldsLost;
}

// ─── Public report ─────────────────────────────────────────────────────────

class DepartmentMigrationReport {
  const DepartmentMigrationReport({
    required this.totalDocuments,
    required this.alreadyCorrect,
    required this.neededUpdate,
    required this.writeResults,
    required this.verifyEntries,
  });

  final int totalDocuments;
  final List<DeptMigrationEntry> alreadyCorrect;
  final List<DeptMigrationEntry> neededUpdate;
  final List<DeptMigrationWriteResult> writeResults;
  final List<DeptMigrationVerifyEntry> verifyEntries;

  int get successfulWrites =>
      writeResults.where((r) => r.success).length;
  int get failedWrites =>
      writeResults.where((r) => !r.success).length;
  int get verifiedOk =>
      verifyEntries.where((v) => v.fullyValid).length;
  int get verifyFailed =>
      verifyEntries.where((v) => !v.fullyValid).length;
  bool get allPassed => verifyFailed == 0;

  String summary() {
    final buf = StringBuffer();
    buf.writeln('═══════════ DEPARTMENT MIGRATION REPORT ═══════════');
    buf.writeln('Total documents  : $totalDocuments');
    buf.writeln('Already correct  : ${alreadyCorrect.length}');
    buf.writeln('Needed update    : ${neededUpdate.length}');
    buf.writeln('Writes succeeded : $successfulWrites');
    buf.writeln('Writes failed    : $failedWrites');
    buf.writeln('Verify passed    : $verifiedOk / ${verifyEntries.length}');

    if (failedWrites > 0) {
      buf.writeln('\n── Write failures ──');
      for (final r in writeResults.where((r) => !r.success)) {
        buf.writeln('  [${r.docId}] "${r.name}": ${r.error}');
      }
    }

    if (verifyFailed > 0) {
      buf.writeln('\n── Verification failures ──');
      for (final v in verifyEntries.where((v) => !v.fullyValid)) {
        buf.writeln(
          '  [${v.docId}] "${v.name}" — '
          'fieldPresent=${v.fieldPresent} matches=${v.matches} '
          'noFieldsLost=${v.noFieldsLost} '
          'storedId=${v.storedDepartmentId ?? "<null>"}',
        );
      }
    } else {
      buf.writeln('\nAll documents verified — every departmentId field is '
          'present and matches its Firestore document ID.');
    }

    buf.writeln('═══════════════════════════════════════════════════');
    return buf.toString();
  }
}
