// lib/features/gpa/presentation/screens/gpa_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/gpa_providers.dart';

class GpaCalculatorScreen extends ConsumerStatefulWidget {
  const GpaCalculatorScreen({super.key});
  @override
  ConsumerState<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends ConsumerState<GpaCalculatorScreen> {
  final prevCgpaCtrl = TextEditingController();
  final prevCreditsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load saved prev CGPA from SharedPref
    Future.microtask(() => ref.read(prevDataLoaderProvider));
  }

  @override
  void dispose() {
    prevCgpaCtrl.dispose();
    prevCreditsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 1. This now returns (list, sgpa, credits, qp) directly, NOT AsyncValue
    final current = ref.watch(currentSemGpaProvider);
    final (list, sgpa, totalCredits, totalQP) = current;
    
    final cgpa = ref.watch(cgpaProvider);
    final prevCgpa = ref.watch(prevCgpaProvider);
    final prevCredits = ref.watch(prevCreditsProvider);

    // 2. Sync controllers when SharedPref loads - listen to the providers
    ref.listen(prevCgpaProvider, (_, next) {
      if (prevCgpaCtrl.text != next.toString()) {
        prevCgpaCtrl.text = next == 0 ? '' : next.toString();
      }
    });
    ref.listen(prevCreditsProvider, (_, next) {
      if (prevCreditsCtrl.text != next.toString()) {
        prevCreditsCtrl.text = next == 0 ? '' : next.toString();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA Calculator', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // SGPA CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: theme.colorScheme.surface,
                  child: Text(
                    sgpa.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 16),
        Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Current SGPA',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onPrimaryContainer, // primary color
          )),
      Text('$totalQP QP / $totalCredits Credits',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          )),
      const SizedBox(height: 4),
      Text('CGPA: ${cgpa.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: theme.colorScheme.primary, // primary color
          )),
      if (prevCredits > 0)
        Text('Prev: $prevCgpa CGPA / $prevCredits CR',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
            )),
    ],
  ),
)
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PREV SEM INPUTS
          Text('Previous Semesters (for CGPA)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: prevCgpaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Prev CGPA',
                    border: OutlineInputBorder(),
                    hintText: 'e.g 2.94',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: prevCreditsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prev Credits',
                    border: OutlineInputBorder(),
                    hintText: 'e.g 52',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final pc = double.tryParse(prevCgpaCtrl.text) ?? 0.0;
              final cr = int.tryParse(prevCreditsCtrl.text) ?? 0;
              ref.read(prevCgpaProvider.notifier).state = pc;
              ref.read(prevCreditsProvider.notifier).state = cr;
              await ref.read(gpaPrefsProvider).savePrevData(cgpa: pc, credits: cr);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Saved in SharedPref')));
              }
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save & Calculate CGPA'),
          ),
          const SizedBox(height: 24),
          Text('Subjects Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No subjects/marks found. Add subjects first.'),
            ),
          ...list.map(
            (e) => Card(
              child: ListTile(
                title: Text('${e.courseCode} - ${e.grade.letter}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${e.name}\n${e.obtained}/${e.max} = ${e.percent.toStringAsFixed(1)}% • ${e.creditHours} CR'),
                trailing: Text(e.grade.point.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}