// lib/features/gpa/data/gpa_prefs_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class GpaPrefsService {
  static const _kPrevCgpa = 'prev_cgpa';
  static const _kPrevCredits = 'prev_total_credits';
  static const _kPrevGpa = 'prev_sem_gpa'; // fallback for old logic

  Future<void> savePrevData({required double cgpa, required int credits}) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kPrevCgpa, cgpa);
    await p.setInt(_kPrevCredits, credits);
  }

  Future<(double, int)> loadPrevData() async {
    final p = await SharedPreferences.getInstance();
    final cgpa = p.getDouble(_kPrevCgpa) ?? p.getDouble(_kPrevGpa) ?? 0.0;
    final credits = p.getInt(_kPrevCredits) ?? 0;
    return (cgpa, credits);
  }
}