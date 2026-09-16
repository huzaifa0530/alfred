// lib/features/gpa/domain/smiu_grading.dart
class SMIUGrade {
  final String letter;
  final double point;
  SMIUGrade(this.letter, this.point);
}

SMIUGrade getGradeFromPercentage(double percent) {
  if (percent >= 90) return SMIUGrade('A', 4.00);
  if (percent >= 85) return SMIUGrade('A-', 3.66);
  if (percent >= 80) return SMIUGrade('B+', 3.33);
  if (percent >= 75) return SMIUGrade('B', 3.00);
  if (percent >= 71) return SMIUGrade('B', 3.00); 
  if (percent >= 68) return SMIUGrade('B-', 2.66);
  if (percent >= 64) return SMIUGrade('C+', 2.33);
  if (percent >= 61) return SMIUGrade('C', 2.00);
  if (percent >= 58) return SMIUGrade('C-', 1.66);
  if (percent >= 54) return SMIUGrade('D+', 1.33);
  if (percent >= 50) return SMIUGrade('D', 1.00);
  return SMIUGrade('F', 0.00);
}