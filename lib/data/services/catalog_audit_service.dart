import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';

/// Audits and repairs department / course data integrity in Firestore.
///
/// Run once from an admin-only UI button or the Flutter debug console after
/// deploying the `FirestoreDepartmentDropdown(returnId: true)` fix.
///
/// What it does:
///   1. Validates every department document.
///   2. Validates every course document and cross-references departmentId values
///      against the real department IDs.
///   3. Where a course's allowedDepartmentIds / departmentId contains a
///      department *name* instead of a Firestore document ID (the old bug),
///      it replaces the name with the matching ID and writes the fix back.
///   4. Returns a [CatalogAuditReport] describing what was found and fixed.
class CatalogAuditService {
  CatalogAuditService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<CatalogAuditReport> runAudit({bool applyFixes = false}) async {
    developer.log('CatalogAudit: starting audit (applyFixes=$applyFixes)',
        name: 'CatalogAudit');

    // ── Step 1: Load all departments ────────────────────────────────────────
    final deptSnap =
        await _db.collection(AppConstants.departmentsCollection).get();

    final Map<String, String> idToName = {}; // docId → name
    final Map<String, String> nameToId = {}; // name  → docId
    final List<DepartmentAuditEntry> deptEntries = [];

    for (final doc in deptSnap.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').trim();

      final issues = <String>[];
      if (name.isEmpty) issues.add('name is empty or missing');

      deptEntries.add(DepartmentAuditEntry(
        id: doc.id,
        name: name,
        issues: issues,
      ));

      if (issues.isEmpty) {
        idToName[doc.id] = name;
        if (nameToId.containsKey(name)) {
          // Duplicate name — flag both
          issues.add('duplicate name "$name" shared with doc ${nameToId[name]}');
        } else {
          nameToId[name] = doc.id;
        }
      }
    }

    developer.log(
        'CatalogAudit: ${deptEntries.length} departments, '
        '${deptEntries.where((d) => d.issues.isNotEmpty).length} with issues',
        name: 'CatalogAudit');

    // ── Step 2: Load all courses ─────────────────────────────────────────────
    final courseSnap =
        await _db.collection(AppConstants.coursesCollection).get();

    final List<CourseAuditEntry> courseEntries = [];
    int fixedCount = 0;

    for (final doc in courseSnap.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').trim();
      final rawDeptId = data['departmentId'] as String? ?? '';
      final rawAllowed =
          List<String>.from(data['allowedDepartmentIds'] as List? ?? []);

      final issues = <String>[];
      final fixes = <String>[];

      // ── Missing name ────────────────────────────────────────────────────
      if (name.isEmpty) issues.add('name is empty or missing');

      // ── Resolve allowedDepartmentIds ────────────────────────────────────
      // The old bug stored department NAMES here; correct value is the Firestore doc ID.
      List<String> repairedAllowed = [];
      bool needsUpdate = false;

      if (rawAllowed.isEmpty && rawDeptId.isNotEmpty) {
        // Legacy scalar-only record (no array field); synthesise the array.
        rawAllowed.add(rawDeptId);
      }

      for (final entry in rawAllowed) {
        if (idToName.containsKey(entry)) {
          // Already a valid ID — keep as-is.
          repairedAllowed.add(entry);
        } else if (nameToId.containsKey(entry)) {
          // It's a department NAME — swap it for the correct ID.
          final correctId = nameToId[entry]!;
          repairedAllowed.add(correctId);
          fixes.add('allowedDepartmentIds: replaced name "$entry" → id "$correctId"');
          needsUpdate = true;
        } else {
          // Neither a known ID nor a known name — orphaned.
          repairedAllowed.add(entry);
          issues.add('allowedDepartmentIds contains unknown value "$entry" '
              '(not a valid department ID or name)');
        }
      }

      // ── Resolve scalar departmentId ─────────────────────────────────────
      String repairedDeptId = rawDeptId;
      if (rawDeptId.isNotEmpty && !idToName.containsKey(rawDeptId)) {
        if (nameToId.containsKey(rawDeptId)) {
          repairedDeptId = nameToId[rawDeptId]!;
          fixes.add('departmentId: replaced name "$rawDeptId" → id "$repairedDeptId"');
          needsUpdate = true;
        } else {
          issues.add('departmentId "$rawDeptId" is not a valid department ID or name');
        }
      }

      // ── Missing allowedDepartmentIds entirely ───────────────────────────
      final bool missingArray = (data['allowedDepartmentIds'] as List?)?.isEmpty ?? true;
      if (missingArray && repairedDeptId.isNotEmpty) {
        repairedAllowed = [repairedDeptId];
        fixes.add('allowedDepartmentIds: synthesised from scalar departmentId');
        needsUpdate = true;
      }

      // ── Apply fix ───────────────────────────────────────────────────────
      if (needsUpdate && applyFixes) {
        try {
          await doc.reference.update({
            'departmentId': repairedDeptId,
            'allowedDepartmentIds': repairedAllowed,
          });
          fixedCount++;
          developer.log('CatalogAudit: fixed course ${doc.id} — $fixes',
              name: 'CatalogAudit');
        } catch (e) {
          issues.add('fix write failed: $e');
        }
      }

      courseEntries.add(CourseAuditEntry(
        id: doc.id,
        name: name,
        rawDepartmentId: rawDeptId,
        rawAllowedDepartmentIds: rawAllowed,
        repairedDepartmentId: repairedDeptId,
        repairedAllowedDepartmentIds: repairedAllowed,
        issues: issues,
        fixes: fixes,
        wasFixed: needsUpdate && applyFixes && issues.isEmpty,
      ));
    }

    // ── Step 3: Build per-department course counts ───────────────────────────
    final Map<String, int> courseCountByDept = {
      for (final id in idToName.keys) id: 0,
    };
    for (final c in courseEntries) {
      for (final deptId in c.repairedAllowedDepartmentIds) {
        if (courseCountByDept.containsKey(deptId)) {
          courseCountByDept[deptId] = courseCountByDept[deptId]! + 1;
        }
      }
    }

    final report = CatalogAuditReport(
      departments: deptEntries,
      courses: courseEntries,
      courseCountByDepartmentId: courseCountByDept,
      fixesApplied: applyFixes,
      fixedCourseCount: fixedCount,
    );

    developer.log(report.summary(), name: 'CatalogAudit');
    return report;
  }
}

// ─── Result models ─────────────────────────────────────────────────────────────

class DepartmentAuditEntry {
  const DepartmentAuditEntry({
    required this.id,
    required this.name,
    required this.issues,
  });

  final String id;
  final String name;
  final List<String> issues;

  bool get isValid => issues.isEmpty;
}

class CourseAuditEntry {
  const CourseAuditEntry({
    required this.id,
    required this.name,
    required this.rawDepartmentId,
    required this.rawAllowedDepartmentIds,
    required this.repairedDepartmentId,
    required this.repairedAllowedDepartmentIds,
    required this.issues,
    required this.fixes,
    required this.wasFixed,
  });

  final String id;
  final String name;
  final String rawDepartmentId;
  final List<String> rawAllowedDepartmentIds;
  final String repairedDepartmentId;
  final List<String> repairedAllowedDepartmentIds;
  final List<String> issues;
  final List<String> fixes;
  final bool wasFixed;

  bool get isValid => issues.isEmpty;
  bool get needsRepair => fixes.isNotEmpty;
  bool get isOrphaned =>
      repairedAllowedDepartmentIds.isEmpty && repairedDepartmentId.isEmpty;
}

class CatalogAuditReport {
  const CatalogAuditReport({
    required this.departments,
    required this.courses,
    required this.courseCountByDepartmentId,
    required this.fixesApplied,
    required this.fixedCourseCount,
  });

  final List<DepartmentAuditEntry> departments;
  final List<CourseAuditEntry> courses;

  /// Maps department Firestore doc ID → number of courses assigned to it.
  final Map<String, int> courseCountByDepartmentId;
  final bool fixesApplied;
  final int fixedCourseCount;

  int get validDepartments => departments.where((d) => d.isValid).length;
  int get invalidDepartments => departments.where((d) => !d.isValid).length;
  int get validCourses => courses.where((c) => c.isValid).length;
  int get orphanedCourses => courses.where((c) => c.isOrphaned).length;
  int get corruptedCourses => courses.where((c) => c.needsRepair).length;
  List<DepartmentAuditEntry> get emptyDepartments =>
      departments.where((d) => (courseCountByDepartmentId[d.id] ?? 0) == 0).toList();

  String summary() {
    final buf = StringBuffer();
    buf.writeln('═══════════ CATALOG AUDIT REPORT ═══════════');
    buf.writeln('Departments : ${departments.length} total | '
        '$validDepartments valid | $invalidDepartments invalid');
    buf.writeln('Courses     : ${courses.length} total | '
        '$validCourses valid | $corruptedCourses corrupted | $orphanedCourses orphaned');
    buf.writeln('Empty depts : ${emptyDepartments.length} '
        '(${emptyDepartments.map((d) => d.name).join(', ')})');

    if (invalidDepartments > 0) {
      buf.writeln('\n── Invalid departments ──');
      for (final d in departments.where((d) => !d.isValid)) {
        buf.writeln('  [${d.id}] "${d.name}": ${d.issues.join('; ')}');
      }
    }

    if (corruptedCourses > 0 || orphanedCourses > 0) {
      buf.writeln('\n── Problem courses ──');
      for (final c in courses.where((c) => !c.isValid || c.needsRepair)) {
        buf.writeln('  [${c.id}] "${c.name}"');
        if (c.fixes.isNotEmpty) buf.writeln('    Fixes: ${c.fixes.join('; ')}');
        if (c.issues.isNotEmpty) buf.writeln('    Issues: ${c.issues.join('; ')}');
        buf.writeln('    wasFixed: ${c.wasFixed}');
      }
    }

    buf.writeln('\n── Course counts per department ──');
    for (final entry in courseCountByDepartmentId.entries) {
      buf.writeln('  ${entry.key}: ${entry.value} course(s)');
    }

    if (fixesApplied) {
      buf.writeln('\nFixes applied: $fixedCourseCount course(s) updated in Firestore.');
    } else {
      buf.writeln('\nDry-run mode — no Firestore writes made.');
      buf.writeln('Call runAudit(applyFixes: true) to apply repairs.');
    }
    buf.writeln('═════════════════════════════════════════════');
    return buf.toString();
  }
}
