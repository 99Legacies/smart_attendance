import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/data/repositories/user_profile_image_repository.dart';

final userProfileImageRepositoryProvider = Provider((ref) {
  return UserProfileImageRepository();
});
