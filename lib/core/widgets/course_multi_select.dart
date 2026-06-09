import 'package:flutter/material.dart';
import 'package:smart_attendance/domain/entities/course.dart';

class CourseMultiSelect extends StatelessWidget {
  const CourseMultiSelect({
    super.key,
    required this.courses,
    required this.selected,
    required this.onChanged,
    this.emptyMessage = 'No courses available.',
  });

  final List<Course> courses;
  final Set<String> selected;
  final void Function(Set<String>) onChanged;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Text(emptyMessage);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Courses', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...courses.map(
          (c) => CheckboxListTile(
            title: Text(c.name),
            value: selected.contains(c.id),
            onChanged: (checked) {
              final next = Set<String>.from(selected);
              if (checked == true) {
                next.add(c.id);
              } else {
                next.remove(c.id);
              }
              onChanged(next);
            },
          ),
        ),
      ],
    );
  }
}
