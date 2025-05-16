import 'package:flutter/material.dart';
import '../models/models.dart';

class CourseGradesCard extends StatelessWidget {
  final Course course;
  final List<Grade> grades;

  const CourseGradesCard({
    Key? key,
    required this.course,
    required this.grades,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final averageGrade = _calculateAverageGrade();
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getColorForGrade(averageGrade),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    averageGrade.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (course.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                course.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Evaluaciones:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (grades.isEmpty)
              const Text('No hay evaluaciones registradas.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: grades.length,
                itemBuilder: (context, index) {
                  final grade = grades[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Evaluación ${index + 1} (${_formatDate(grade.date)})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getColorForGrade(grade.value).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            grade.value.toStringAsFixed(1),
                            style: TextStyle(
                              color: _getColorForGrade(grade.value),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageGrade() {
    if (grades.isEmpty) return 0.0;
    final sum = grades.fold(0.0, (sum, grade) => sum + grade.value);
    return sum / grades.length;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getColorForGrade(double grade) {
    if (grade >= 90) {
      return Colors.green;
    } else if (grade >= 80) {
      return Colors.lightGreen;
    } else if (grade >= 70) {
      return Colors.yellow.shade800;
    } else if (grade >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
