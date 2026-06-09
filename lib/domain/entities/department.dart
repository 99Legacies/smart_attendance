import 'package:equatable/equatable.dart';

class Department extends Equatable {
  const Department({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
