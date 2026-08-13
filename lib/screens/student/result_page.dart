// result_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/status_badge.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, List<Result>> _groupedResults = {};
  String? _selectedExam;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final student = context.read<Student>();
      final resultsRepo = context.read<ResultRepository>();
      final res = await resultsRepo.getResultsByStudent(student.id);

      final published = res;

      final Map<String, List<Result>> grouped = {};
      for (final r in published) {
        final examName = r.examName ?? 'General Exam';
        grouped.putIfAbsent(examName, () => []).add(r);
      }

      if (mounted) {
        setState(() {
          _groupedResults = grouped;
          _selectedExam = grouped.keys.isNotEmpty ? grouped.keys.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadResults();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentExamRecords = _selectedExam != null
        ? (_groupedResults[_selectedExam] ?? [])
        : <Result>[];
    double average = 0.0;
    double totalObtained = 0.0;
    double totalMax = 0.0;
    for (final r in currentExamRecords) {
      if (r.marksObtained != null) {
        totalObtained += r.marksObtained!;
        totalMax += r.maximumMarks;
      }
    }
    if (totalMax > 0) {
      average = (totalObtained / totalMax) * 100;
    }

    return PageScaffold(
      title: 'Result',
      trailing: currentExamRecords.isNotEmpty
          ? FilledButton.icon(
              onPressed: () {
                // Trigger download alert/action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading report card...')),
                );
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download Result'),
            )
          : null,
      children: [
        PortalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_groupedResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'No results have been published for you yet.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: (_selectedExam != null && _groupedResults.containsKey(_selectedExam)) ? _selectedExam : (_groupedResults.isNotEmpty ? _groupedResults.keys.first : null),
                        decoration: const InputDecoration(
                          labelText: 'Exam Term',
                          prefixIcon: Icon(Icons.tune_outlined),
                        ),
                        items: [
                          for (final term in _groupedResults.keys)
                            DropdownMenuItem(value: term, child: Text(term)),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedExam = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    _AverageBadge(average: average),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final minTableWidth = constraints.maxWidth;
                    final dynamicColumnSpacing = math.max(
                      24.0,
                      (constraints.maxWidth - 320) / 4,
                    );
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: minTableWidth),
                        child: DataTable(
                          columnSpacing: dynamicColumnSpacing,
                          columns: const [
                            DataColumn(label: Text('Subject')),
                            DataColumn(label: Text('Marks Obtained')),
                            DataColumn(label: Text('Grade')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: [
                            for (final record in currentExamRecords)
                              DataRow(
                                cells: [
                                  DataCell(
                                    Text(record.subjectName ?? 'Unknown Subject'),
                                  ),
                                  DataCell(
                                    Text(
                                      '${record.marksObtained ?? 0} / ${record.maximumMarks}',
                                    ),
                                  ),
                                  DataCell(Text(record.grade ?? 'N/A')),
                                  DataCell(
                                    StatusBadge(
                                      label: (record.marksObtained ?? 0) >= 18 ? 'Pass' : 'Fail',
                                      color: (record.marksObtained ?? 0) >= 18
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AverageBadge extends StatelessWidget {
  const _AverageBadge({required this.average});

  final double average;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${average.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2563EB),
            ),
          ),
          Text(
            'Average',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
