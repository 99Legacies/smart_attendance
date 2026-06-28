import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/absence_request.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/department.dart';
import 'package:smart_attendance/domain/entities/student.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key, required this.studentUid});

  final String studentUid;

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  final _reasonController = TextEditingController();
  String? _selectedCourseId;
  Uint8List? _fileBytes;
  String? _fileName;
  bool _submitting = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;

    // Reject images over 100KB to stay within Firestore document limits
    if (bytes.lengthInBytes > 100 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image is too large. Please choose an image under 100KB.',
          ),
        ),
      );
      return;
    }

    setState(() => _uploadingPhoto = true);
    try {
      // Encode to base64 and store in Firestore users + students collections
      final base64Image = base64Encode(bytes);
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.update(
        firestore
            .collection(AppConstants.usersCollection)
            .doc(widget.studentUid),
        {'photoBase64': base64Image},
      );
      batch.update(
        firestore
            .collection(AppConstants.studentsCollection)
            .doc(widget.studentUid),
        {'photoBase64': base64Image},
      );
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update photo: $e')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitAbsence() async {
    if (_selectedCourseId == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a course and enter a reason')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final student = await ref
          .read(catalogRepositoryProvider)
          .getStudent(widget.studentUid);
      final courses = await ref.read(catalogRepositoryProvider).getCourses();
      String courseName = _selectedCourseId!;
      for (final c in courses) {
        if (c.id == _selectedCourseId) {
          courseName = c.courseCode != null
              ? '${c.courseCode} — ${c.name}'
              : c.name;
          break;
        }
      }

      await ref
          .read(absenceRepositoryProvider)
          .submitRequest(
            studentId: widget.studentUid,
            studentName: student?.name ?? 'Student',
            courseId: _selectedCourseId!,
            courseName: courseName,
            reason: _reasonController.text,
            fileBytes: _fileBytes,
            fileName: _fileName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absence request submitted')),
      );
      _reasonController.clear();
      setState(() {
        _fileBytes = null;
        _fileName = null;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit request. Check your connection and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(_studentProvider(widget.studentUid));
    final departmentsAsync = ref.watch(_departmentsProvider);
    final coursesAsync = ref.watch(_allCoursesProvider);
    final absenceAsync = ref.watch(_studentAbsenceProvider(widget.studentUid));
    // Watch live photo from Firestore
    final photoAsync = ref.watch(_studentPhotoProvider(widget.studentUid));

    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Text('Profile not found.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile photo section
              Center(
                child: Stack(
                  children: [
                    photoAsync.when(
                      data: (base64) => CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        backgroundImage: base64 != null
                            ? MemoryImage(base64Decode(base64))
                            : null,
                        child: base64 == null
                            ? Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 36),
                              )
                            : null,
                      ),
                      loading: () => const CircleAvatar(
                        radius: 48,
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, _) => CircleAvatar(
                        radius: 48,
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploadingPhoto ? null : _pickProfilePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _uploadingPhoto
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Tap camera to update photo (max 100KB)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    _row('Name', student.name),
                    _row('Student ID', student.studentId),
                    _row('Email', student.email),
                    departmentsAsync.when(
                      data: (deps) {
                        Department? dept;
                        for (final d in deps) {
                          if (d.id == student.departmentId) {
                            dept = d;
                            break;
                          }
                        }
                        return _row(
                          'Department',
                          dept?.name ?? student.departmentId,
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, st) =>
                          _row('Department', student.departmentId),
                    ),
                    coursesAsync.when(
                      data: (courses) {
                        final names = courses
                            .where((c) => student.courseIds.contains(c.id))
                            .map((c) => c.name)
                            .join(', ');
                        return _row('Courses', names.isEmpty ? '-' : names);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Absence',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    coursesAsync.when(
                      data: (courses) {
                        final enrolled = courses
                            .where((c) => student.courseIds.contains(c.id))
                            .toList();
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedCourseId,
                          decoration: const InputDecoration(
                            labelText: 'Course',
                          ),
                          items: enrolled
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCourseId = v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text(
                        'Could not load courses. Please try again.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Reason'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_fileName ?? 'Attach file (optional)'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submitAbsence,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Request'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My absence requests',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    absenceAsync.when(
                      data: (requests) {
                        if (requests.isEmpty) {
                          return const Text('No requests yet.');
                        }
                        return Column(
                          children: requests
                              .map(
                                (r) => ListTile(
                                  title: Text(r.courseName ?? r.courseId),
                                  subtitle: Text(
                                    '${r.status.name.toUpperCase()}'
                                    '${r.lecturerFeedback != null ? '\n${r.lecturerFeedback}' : ''}',
                                  ),
                                  isThreeLine: r.lecturerFeedback != null,
                                  leading: Icon(
                                    r.status == AbsenceRequestStatus.approved
                                        ? Icons.check_circle
                                        : r.status ==
                                              AbsenceRequestStatus.rejected
                                        ? Icons.cancel
                                        : Icons.pending,
                                    color:
                                        r.status ==
                                            AbsenceRequestStatus.approved
                                        ? Colors.green
                                        : r.status ==
                                              AbsenceRequestStatus.rejected
                                        ? Colors.red
                                        : Colors.orange,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text(
                        'Could not load absence requests.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_outlined, size: 48),
              SizedBox(height: 12),
              Text('Could not load your profile.'),
              SizedBox(height: 4),
              Text('Please check your connection and try again.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

final _studentProvider = FutureProvider.family<Student?, String>((ref, uid) {
  return ref.read(catalogRepositoryProvider).getStudent(uid).timeout(
    const Duration(seconds: 8),
    onTimeout: () => null,
  );
});

final _departmentsProvider = StreamProvider<List<Department>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchDepartments();
});

final _allCoursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchCourses();
});

final _studentAbsenceProvider =
    StreamProvider.family<List<AbsenceRequest>, String>((ref, studentId) {
      return ref
          .watch(absenceRepositoryProvider)
          .watchRequestsForStudent(studentId);
    });

// Watches the student's photo live from Firestore
final _studentPhotoProvider = StreamProvider.family<String?, String>((
  ref,
  uid,
) {
  return FirebaseFirestore.instance
      .collection(AppConstants.studentsCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => doc.data()?['photoBase64'] as String?);
});
