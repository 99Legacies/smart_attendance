import 'package:hive/hive.dart';

part 'attendance_status.g.dart';

@HiveType(typeId: 21)
enum AttendanceStatus {
  @HiveField(0)
  present,
  @HiveField(1)
  late,
  @HiveField(2)
  absent;

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (s) => s.name == value.toLowerCase(),
      orElse: () => AttendanceStatus.absent,
    );
  }
}
