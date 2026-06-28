import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/department.dart';
import 'package:smart_attendance/domain/entities/lecturer.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class LecturerProfileScreen extends ConsumerStatefulWidget {
  const LecturerProfileScreen({super.key, required this.lecturerId});

  final String lecturerId;

  @override
  ConsumerState<LecturerProfileScreen> createState() =>
      _LecturerProfileScreenState();
}

class _LecturerProfileScreenState
    extends ConsumerState<LecturerProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null) return;

    final bytes = await result.files.single.readAsBytes();

    if (bytes.lengthInBytes > 100 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image is too large. Please choose an image under 100KB.'),
        ),
      );
      return;
    }

    setState(() => _uploadingPhoto = true);
    try {
      final base64Image = base64Encode(bytes);
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.update(
        firestore.collection(AppConstants.usersCollection).doc(widget.lecturerId),
        {'photoBase64': base64Image},
      );
      batch.update(
        firestore.collection(AppConstants.lecturersCollection).doc(widget.lecturerId),
        {'photoBase64': base64Image},
      );
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update photo: $e')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lecturerAsync = ref.watch(_lecturerProfileProvider(widget.lecturerId));
    final departmentsAsync = ref.watch(_deptProvider);
    final coursesAsync = ref.watch(_coursesProvider);
    final photoAsync = ref.watch(_lecturerPhotoProvider(widget.lecturerId));
    final statsAsync = ref.watch(_lecturerProfileStatsProvider(widget.lecturerId));

    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: lecturerAsync.when(
        data: (lecturer) {
          if (lecturer == null) {
            return const Center(child: Text('Profile not found.'));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    photoAsync.when(
                      data: (base64) => CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: base64 != null
                            ? MemoryImage(base64Decode(base64))
                            : null,
                        child: base64 == null
                            ? Text(
                                lecturer.name.isNotEmpty
                                    ? lecturer.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 36),
                              )
                            : null,
                      ),
                      loading: () =>
                          const CircleAvatar(radius: 48, child: CircularProgressIndicator()),
                      error: (_, _) => CircleAvatar(
                        radius: 48,
                        child: Text(
                          lecturer.name.isNotEmpty
                              ? lecturer.name[0].toUpperCase()
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
                              : const Icon(Icons.camera_alt,
                                  size: 16, color: Colors.white),
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
                    _row('Name', lecturer.name),
                    _row('Staff ID', lecturer.lecturerId),
                    _row('Email', lecturer.email),
                    departmentsAsync.when(
                      data: (depts) {
                        Department? dept;
                        for (final d in depts) {
                          if (d.id == lecturer.departmentId) {
                            dept = d;
                            break;
                          }
                        }
                        return _row('Department', dept?.name ?? lecturer.departmentId);
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => _row('Department', lecturer.departmentId),
                    ),
                    coursesAsync.when(
                      data: (courses) {
                        final assigned = courses
                            .where((c) => lecturer.courseIds.contains(c.id))
                            .map((c) => c.name)
                            .join(', ');
                        return _row(
                          'Courses',
                          assigned.isEmpty ? 'None assigned' : assigned,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
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
                      'Teaching Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    statsAsync.when(
                      data: (stats) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statChip(
                            context,
                            label: 'Sessions',
                            value: '${stats.sessions}',
                            icon: Icons.event_outlined,
                          ),
                          _statChip(
                            context,
                            label: 'Records',
                            value: '${stats.records}',
                            icon: Icons.fact_check_outlined,
                          ),
                          _statChip(
                            context,
                            label: 'Courses',
                            value: '${lecturer.courseIds.length}',
                            icon: Icons.school_outlined,
                          ),
                        ],
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Could not load stats'),
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
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _statChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

final _lecturerProfileProvider =
    FutureProvider.family<Lecturer?, String>((ref, uid) {
  return ref.read(catalogRepositoryProvider).getLecturer(uid).timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
});

final _deptProvider = StreamProvider<List<Department>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchDepartments();
});

final _coursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchCourses();
});

final _lecturerPhotoProvider =
    StreamProvider.family<String?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection(AppConstants.lecturersCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => doc.data()?['photoBase64'] as String?);
});

class _ProfileStats {
  const _ProfileStats({required this.sessions, required this.records});
  final int sessions;
  final int records;
}

final _lecturerProfileStatsProvider =
    FutureProvider.family<_ProfileStats, String>((ref, lecturerId) async {
  final db = FirebaseFirestore.instance;

  final sessionsSnap = await db
      .collection(AppConstants.sessionsCollection)
      .where('lecturerId', isEqualTo: lecturerId)
      .get();

  final sessionIds = sessionsSnap.docs.map((d) => d.id).toSet();

  final recordsSnap = await db
      .collection(AppConstants.recordsCollection)
      .limit(1000)
      .get();

  final relevantRecords =
      recordsSnap.docs.where((d) {
        final sid = d.data()['sessionId'] as String? ?? '';
        return sessionIds.contains(sid);
      }).length;

  return _ProfileStats(
    sessions: sessionsSnap.docs.length,
    records: relevantRecords,
  );
});
