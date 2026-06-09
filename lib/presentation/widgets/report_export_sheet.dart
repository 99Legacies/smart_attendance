import 'package:flutter/material.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/data/services/report_export_service.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';

Future<void> showReportExportSheet(
  BuildContext context, {
  required UserRole role,
  required String userId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _ReportExportSheet(role: role, userId: userId),
  );
}

class _ReportExportSheet extends StatefulWidget {
  const _ReportExportSheet({required this.role, required this.userId});

  final UserRole role;
  final String userId;

  @override
  State<_ReportExportSheet> createState() => _ReportExportSheetState();
}

class _ReportExportSheetState extends State<_ReportExportSheet> {
  bool _loading = false;

  Future<void> _export(ReportExportFormat format) async {
    setState(() => _loading = true);
    try {
      final service = ReportExportService();
      final data = widget.role == UserRole.admin
          ? await service.buildAdminReport()
          : await service.buildLecturerReport(widget.userId);
      await service.shareReport(data: data, format: format);
      if (!mounted) return;
      Navigator.pop(context);
      SnackbarUtils.showSuccess(context, 'Report ready to share');
    } on AppException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Export report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Generate attendance summary, sessions, and records.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            FilledButton.icon(
              onPressed: () => _export(ReportExportFormat.excel),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Export as Excel (.xlsx)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _export(ReportExportFormat.pdf),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Export as PDF'),
            ),
          ],
        ],
      ),
    );
  }
}
