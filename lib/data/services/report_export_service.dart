import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/data/models/attendance_record_model.dart';
import 'package:smart_attendance/data/models/attendance_session_model.dart';

enum ReportExportFormat { pdf, excel }

class AttendanceReportData {
  const AttendanceReportData({
    required this.generatedAt,
    required this.title,
    required this.summaryRows,
    required this.sessionRows,
    required this.recordRows,
  });

  final DateTime generatedAt;
  final String title;
  final List<List<String>> summaryRows;
  final List<List<String>> sessionRows;
  final List<List<String>> recordRows;
}

class ReportExportService {
  ReportExportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

  Future<AttendanceReportData> buildAdminReport() async {
    final students = await _count(AppConstants.studentsCollection);
    final lecturers = await _count(AppConstants.lecturersCollection);
    final courses = await _count(AppConstants.coursesCollection);
    final sessions = await _fetchAllSessions();
    final records = await _fetchAllRecords();

    return AttendanceReportData(
      generatedAt: DateTime.now(),
      title: 'AttendPro — Admin Report',
      summaryRows: [
        ['Metric', 'Value'],
        ['Students', '$students'],
        ['Lecturers', '$lecturers'],
        ['Courses', '$courses'],
        ['Sessions', '${sessions.length}'],
        ['Attendance records', '${records.length}'],
      ],
      sessionRows: _sessionRows(sessions),
      recordRows: _recordRows(records),
    );
  }

  Future<AttendanceReportData> buildLecturerReport(String lecturerId) async {
    final sessionsSnap = await _firestore
        .collection(AppConstants.sessionsCollection)
        .where('lecturerId', isEqualTo: lecturerId)
        .get();
    final sessions = sessionsSnap.docs
        .map((d) => AttendanceSessionModel.fromFirestore(d))
        .toList();

    final sessionIds = sessions.map((s) => s.id).toSet();
    final allRecords = await _fetchAllRecords();
    final records = allRecords
        .where((r) => sessionIds.contains(r.sessionId))
        .toList();

    var present = 0, late = 0, absent = 0;
    for (final r in records) {
      switch (r.status.name) {
        case 'present':
          present++;
        case 'late':
          late++;
        case 'absent':
          absent++;
      }
    }

    return AttendanceReportData(
      generatedAt: DateTime.now(),
      title: 'AttendPro — Lecturer Report',
      summaryRows: [
        ['Metric', 'Value'],
        ['Sessions', '${sessions.length}'],
        ['Records', '${records.length}'],
        ['Present', '$present'],
        ['Late', '$late'],
        ['Absent', '$absent'],
      ],
      sessionRows: _sessionRows(sessions),
      recordRows: _recordRows(records),
    );
  }

  Future<void> shareReport({
    required AttendanceReportData data,
    required ReportExportFormat format,
  }) async {
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(data.generatedAt);
    if (format == ReportExportFormat.excel) {
      final bytes = _buildExcel(data);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'attendance_report_$timestamp.xlsx',
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          subject: data.title,
        ),
      );
    } else {
      final bytes = await _buildPdf(data);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'attendance_report_$timestamp.pdf',
              mimeType: 'application/pdf',
            ),
          ],
          subject: data.title,
        ),
      );
    }
  }

  Future<int> _count(String collection) async {
    final snap = await _firestore.collection(collection).count().get();
    return snap.count ?? 0;
  }

  Future<List<AttendanceSessionModel>> _fetchAllSessions() async {
    final snap = await _firestore
        .collection(AppConstants.sessionsCollection)
        .orderBy('startTime', descending: true)
        .limit(500)
        .get();
    return snap.docs
        .map((d) => AttendanceSessionModel.fromFirestore(d))
        .toList();
  }

  Future<List<AttendanceRecordModel>> _fetchAllRecords() async {
    final snap = await _firestore
        .collection(AppConstants.recordsCollection)
        .orderBy('timestamp', descending: true)
        .limit(1000)
        .get();
    return snap.docs
        .map((d) => AttendanceRecordModel.fromFirestore(d))
        .toList();
  }

  List<List<String>> _sessionRows(List<AttendanceSessionModel> sessions) {
    return [
      ['Session ID', 'Course', 'Lecturer', 'Start', 'End', 'Active'],
      ...sessions.map(
        (s) => [
          s.id,
          s.courseId,
          s.lecturerId,
          _dateFmt.format(s.startTime),
          _dateFmt.format(s.endTime),
          s.isActive ? 'Yes' : 'No',
        ],
      ),
    ];
  }

  List<List<String>> _recordRows(List<AttendanceRecordModel> records) {
    return [
      ['Record ID', 'Student', 'Session', 'Status', 'Time'],
      ...records.map(
        (r) => [
          r.id,
          r.studentId,
          r.sessionId,
          r.status.label,
          _dateFmt.format(r.timestamp),
        ],
      ),
    ];
  }

  Uint8List _buildExcel(AttendanceReportData data) {
    final excel = Excel.createExcel();
    _writeSheet(excel, 'Summary', data.summaryRows, removeDefault: true);
    _writeSheet(excel, 'Sessions', data.sessionRows);
    _writeSheet(excel, 'Attendance', data.recordRows);
    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  void _writeSheet(
    Excel excel,
    String name,
    List<List<String>> rows, {
    bool removeDefault = false,
  }) {
    final sheet = excel[name];
    if (removeDefault) {
      excel.delete('Sheet1');
    }
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            .value = TextCellValue(
          rows[r][c],
        );
      }
    }
  }

  Future<Uint8List> _buildPdf(AttendanceReportData data) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              data.title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Generated: ${_dateFmt.format(data.generatedAt)}'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(data: data.summaryRows),
          pw.SizedBox(height: 16),
          pw.Text(
            'Sessions (up to 500)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            data: data.sessionRows.take(50).toList(),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Attendance records (up to 1000)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            data: data.recordRows.take(80).toList(),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
