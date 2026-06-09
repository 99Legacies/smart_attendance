import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/data/models/user_model.dart';
import 'package:smart_attendance/domain/entities/app_user.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/domain/repositories/user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  @override
  Stream<List<AppUser>> watchUsers() {
    return _users.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map(UserModel.fromFirestore).toList(growable: false),
        );
  }

  @override
  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> updateUserRole({
    required String uid,
    required UserRole role,
  }) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      throw const AppException('User not found.', code: 'user_not_found');
    }

    final data = doc.data()!;
    final batch = _firestore.batch();

    batch.update(_users.doc(uid), {'role': role.name});

    if (role == UserRole.admin) {
      batch.set(
        _firestore.collection(AppConstants.adminsCollection).doc(uid),
        {
          'name': data['name'],
          'email': data['email'],
          'department': data['department'],
          'role': role.name,
        },
        SetOptions(merge: true),
      );
      batch.delete(
        _firestore.collection(AppConstants.studentsCollection).doc(uid),
      );
    } else if (role == UserRole.student) {
      final departmentId = await _ensureDepartmentId(
        data['department'] as String? ?? '',
      );
      batch.set(
        _firestore.collection(AppConstants.studentsCollection).doc(uid),
        {
          'name': data['name'],
          'email': data['email'],
          'studentId': (data['roleId'] as String? ?? '').trim().isNotEmpty
              ? (data['roleId'] as String).trim()
              : _studentIdFromUid(uid),
          'departmentId': departmentId,
          'courseIds': <String>[],
          'role': role.name,
        },
        SetOptions(merge: true),
      );
      batch.delete(
        _firestore.collection(AppConstants.adminsCollection).doc(uid),
      );
    }

    await batch.commit();
  }

  @override
  Future<void> deleteUser(String uid) async {
    final batch = _firestore.batch();
    batch.delete(_users.doc(uid));
    batch.delete(
      _firestore.collection(AppConstants.studentsCollection).doc(uid),
    );
    batch.delete(
      _firestore.collection(AppConstants.adminsCollection).doc(uid),
    );
    batch.delete(
      _firestore.collection(AppConstants.lecturersCollection).doc(uid),
    );
    await batch.commit();
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String department,
  }) async {
    final trimmedName = name.trim();
    final trimmedDepartment = department.trim();
    if (trimmedName.isEmpty || trimmedDepartment.isEmpty) {
      throw const AppException(
        'Name and department are required.',
        code: 'invalid_profile',
      );
    }

    await _users.doc(uid).update({
      'name': trimmedName,
      'department': trimmedDepartment,
    });
  }

  Future<String> _ensureDepartmentId(String departmentName) async {
    final existing = await _firestore
        .collection(AppConstants.departmentsCollection)
        .where('name', isEqualTo: departmentName)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }
    final ref = await _firestore
        .collection(AppConstants.departmentsCollection)
        .add({'name': departmentName});
    return ref.id;
  }

  String _studentIdFromUid(String uid) {
    return uid.length >= 8 ? uid.substring(0, 8).toUpperCase() : uid.toUpperCase();
  }
}
