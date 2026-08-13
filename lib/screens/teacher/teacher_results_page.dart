import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../utils/string_utils.dart';
import '../../widgets/status_badge.dart';

class TeacherResultsPage extends StatefulWidget {
  const TeacherResultsPage({super.key});

  @override
  State<TeacherResultsPage> createState() => _TeacherResultsPageState();
}

class _TeacherResultsPageState extends State<TeacherResultsPage> {
  bool _isLoading = true;
  String? _error;

  List<Exam> _exams = [];
  List<Subject> _subjects = [];
  List<Student> _students = [];
  List<Result> _results = [];




  @override
  void initState() {
    super.initState();
    _loadSetupData();
  }

  Future<void> _loadSetupData() async {
    try {
      debugPrint('[FLUTTER RESULTS PAGE] Opening Upload Results page');
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';

      final examRepo = context.read<ExamRepository>();
      final subjectRepo = context.read<SubjectRepository>();
      final studentRepo = context.read<StudentRepository>();
      final resultRepo = context.read<ResultRepository>();

      debugPrint('[FLUTTER RESULTS PAGE] Calling Students API for classId: "$classId"');
      final studentsFuture = studentRepo.getStudentsByClass(classId).then((res) {
        debugPrint('[FLUTTER RESULTS PAGE] Response status Students API: 200 | Count: ${res.length}');
        return res;
      }).catchError((err, stack) {
        debugPrint('[FLUTTER RESULTS PAGE Parsing exceptions] Students API error: $err\n$stack');
        return <Student>[];
      });

      debugPrint('[FLUTTER RESULTS PAGE] Calling Subjects API for classId: "$classId"');
      final subjectsFuture = subjectRepo.getSubjectsByClass(classId).then((res) {
        debugPrint('[FLUTTER RESULTS PAGE] Response status Subjects API: 200 | Count: ${res.length}');
        return res;
      }).catchError((err, stack) {
        debugPrint('[FLUTTER RESULTS PAGE Parsing exceptions] Subjects API error: $err\n$stack');
        return <Subject>[];
      });

      debugPrint('[FLUTTER RESULTS PAGE] Calling Exams API for classId: "$classId"');
      final examsFuture = examRepo.getExamsByClass(classId).then((res) {
        debugPrint('[FLUTTER RESULTS PAGE] Response status Exams API: 200 | Count: ${res.length}');
        return res;
      }).catchError((err, stack) {
        debugPrint('[FLUTTER RESULTS PAGE Parsing exceptions] Exams API error: $err\n$stack');
        return <Exam>[];
      });

      debugPrint('[FLUTTER RESULTS PAGE] Calling Results API for classId: "$classId"');
      final resultsFuture = resultRepo.getResultsByClass(classId).then((res) {
        debugPrint('[FLUTTER RESULTS PAGE] Response status Results API: 200 | Count: ${res.length}');
        return res;
      }).catchError((err, stack) {
        debugPrint('[FLUTTER RESULTS PAGE Parsing exceptions] Results API error: $err\n$stack');
        return <Result>[];
      });

      final data = await Future.wait([
        examsFuture,
        subjectsFuture,
        studentsFuture,
        resultsFuture,
      ]);

      debugPrint('[FLUTTER RESULTS PAGE] Response body setup complete: Exams=${data[0].length}, Subjects=${data[1].length}, Students=${data[2].length}, Results=${data[3].length}');

      setState(() {
        _exams = data[0] as List<Exam>;
        _subjects = data[1] as List<Subject>;
        _students = data[2] as List<Student>;
        _results = data[3] as List<Result>;



        _isLoading = false;
        _error = null;
      });
    } catch (e, stack) {
      debugPrint('[FLUTTER RESULTS PAGE Parsing exceptions] Failed to load setup data: $e\n$stack');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshResults() async {
    debugPrint('[FLUTTER RESULTS PAGE] Refresh button clicked');
    try {
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';
      debugPrint('[FLUTTER RESULTS PAGE] Calling getResultsByClass for classId: "$classId"');
      final resultRepo = context.read<ResultRepository>();
      final updatedResults = await resultRepo.getResultsByClass(classId);
      debugPrint('[FLUTTER RESULTS PAGE] getResultsByClass completed: count=${updatedResults.length}');
      setState(() {
        _results = updatedResults;
      });
    } catch (e, stack) {
      debugPrint('[FLUTTER RESULTS PAGE ERROR] Failed to refresh results: $e\n$stack');
    }
  }

  void _showUploadResultDialog({Result? resultToEdit}) {
    debugPrint('[FLUTTER RESULTS PAGE] + Add Result button clicked (Editing: ${resultToEdit != null})');
    debugPrint('[FLUTTER RESULTS PAGE] Opening _UploadResultDialog: Students=${_students.length}, Subjects=${_subjects.length}, Exams=${_exams.length}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UploadResultDialog(
        exams: _exams,
        subjects: _subjects,
        students: _students,
        initialResult: resultToEdit,
        onSaved: () async {
          debugPrint('[FLUTTER RESULTS PAGE] Result saved! Refreshing results...');
          await _refreshResults();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  resultToEdit == null
                      ? 'Result uploaded successfully!'
                      : 'Result updated successfully!',
                ),
                backgroundColor: const Color(0xFF059669),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteResult(Result result) async {
    debugPrint('[FLUTTER RESULTS PAGE] Delete button clicked for result: ${result.id}');
    final resultRepo = context.read<ResultRepository>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Result'),
        content: Text(
          'Are you sure you want to delete the result for ${result.studentName ?? 'this student'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        debugPrint('[FLUTTER RESULTS PAGE] Deleting result ID: ${result.id}');
        await resultRepo.deleteResult(result.id);
        debugPrint('[FLUTTER RESULTS PAGE] Result deleted. Refreshing table...');
        await _refreshResults();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Result deleted successfully')),
          );
        }
      } catch (e, stack) {
        debugPrint('[FLUTTER RESULTS PAGE ERROR] Failed to delete result: $e\n$stack');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showExcelUploadDialog() async {
    debugPrint('[FLUTTER RESULTS PAGE] Upload Excel button clicked');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[FLUTTER RESULTS PAGE] File picker cancelled or empty');
        return;
      }

      final file = result.files.first;
      debugPrint('[FLUTTER RESULTS PAGE] File selected: ${file.name} (${file.size} bytes)');
      final bytes = file.bytes;
      if (bytes == null) {
        debugPrint('[FLUTTER RESULTS PAGE ERROR] File bytes null');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read file bytes.')),
        );
        return;
      }

      List<Map<String, String>> previewRows = [];
      try {
        final excel = Excel.decodeBytes(bytes);
        for (var table in excel.tables.keys) {
          final sheet = excel.tables[table];
          if (sheet == null || sheet.maxRows <= 1) continue;
          final headerRow = sheet.rows.first;
          final headers = headerRow.map((cell) => cell?.value?.toString().trim() ?? '').toList();

          for (var i = 1; i < sheet.rows.length; i++) {
            final row = sheet.rows[i];
            if (row.isEmpty) continue;
            Map<String, String> rowMap = {};
            for (var j = 0; j < headers.length && j < row.length; j++) {
              rowMap[headers[j]] = row[j]?.value?.toString().trim() ?? '';
            }
            if (rowMap.values.any((v) => v.isNotEmpty)) {
              previewRows.add(rowMap);
            }
          }
          break;
        }
      } catch (e) {
        debugPrint('[FLUTTER RESULTS PAGE] Excel decode note: $e');
      }

      if (!mounted) return;

      debugPrint('[FLUTTER RESULTS PAGE] Opening Excel Preview Dialog: rows=${previewRows.length}');
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Import Results from Excel'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(dialogCtx).size.width * 0.9 < 750 ? MediaQuery.of(dialogCtx).size.width * 0.9 : 750),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: ${file.name} (${previewRows.length} rows found)'),
                const SizedBox(height: 12),
                if (previewRows.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: previewRows.first.keys.map((k) => DataColumn(label: Text(k.toString(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                          rows: previewRows.map((r) {
                            return DataRow(
                              cells: r.keys.map((k) => DataCell(Text(r[k]?.toString() ?? ''))).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  )
                else
                  const Text('Ready to upload Excel file to backend for parsing and validation.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                setState(() => _isLoading = true);
                try {
                  debugPrint('[FLUTTER RESULTS PAGE] Calling importResultsExcel API...');
                  final resultRepo = context.read<ResultRepository>();
                  final res = await resultRepo.importResultsExcel(bytes, file.name);
                  final importedCount = res['importedCount'] ?? 0;
                  final skippedCount = res['skippedCount'] ?? 0;
                  final errors = (res['errors'] as List?)?.cast<String>() ?? [];

                  debugPrint('[FLUTTER RESULTS PAGE] importResultsExcel response: imported=$importedCount, skipped=$skippedCount, errors=${errors.length}');
                  if (!mounted) return;
                  await _refreshResults();
                  if (!mounted) return;

                  String message = 'Successfully imported $importedCount results.';
                  if (skippedCount > 0) {
                    message += ' ($skippedCount skipped)';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message + (errors.isNotEmpty ? '\n${errors.take(2).join('\n')}' : '')),
                      backgroundColor: importedCount > 0 ? const Color(0xFF059669) : Colors.orange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e, stack) {
                  debugPrint('[FLUTTER RESULTS PAGE ERROR] Excel import failed: $e\n$stack');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Import failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Import Results'),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      debugPrint('[FLUTTER RESULTS PAGE ERROR] File selection error: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _downloadTemplate() {
    final sampleCsv = 
        "ADMISSION NO`,STUDENT NAME,THAREEEQ,LISANUL QURAN,DUROOSUL IHSAN,FIQH,TOTAL (200),Grade,STATUS (rank)\n"
        "1320,M.MISHHAL,6,18,20,7,51,,8\n"
        "1306,SHAMMAS,8,20,11,12,51,,8\n"
        "1324,M.SINAN M,9,18,25,18,70,,5";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.table_chart_outlined, color: Color(0xFF0F172A)),
            SizedBox(width: 10),
            Text('Result Upload Template Format'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.9 < 800 ? MediaQuery.of(ctx).size.width * 0.9 : 800),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload files formatted as an Excel (.xlsx) or CSV (.csv) file with the following column headers:',
                  style: TextStyle(fontSize: 14, color: Color(0xFF45464D)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Chip(
                      avatar: CircleAvatar(child: Text('1', style: TextStyle(fontSize: 10))),
                      label: Text('ADMISSION NO *'),
                      backgroundColor: Color(0xFFEFF6FF),
                    ),
                    Chip(
                      avatar: CircleAvatar(child: Text('2', style: TextStyle(fontSize: 10))),
                      label: Text('STUDENT NAME'),
                    ),
                    Chip(
                      avatar: CircleAvatar(child: Text('3', style: TextStyle(fontSize: 10))),
                      label: Text('Subject Columns * (e.g. THAREEEQ, LISANUL QURAN, DUROOSUL IHSAN, FIQH)'),
                      backgroundColor: Color(0xFFEFF6FF),
                    ),
                    Chip(
                      avatar: CircleAvatar(child: Text('4', style: TextStyle(fontSize: 10))),
                      label: Text('TOTAL (200)'),
                    ),
                    Chip(
                      avatar: CircleAvatar(child: Text('5', style: TextStyle(fontSize: 10))),
                      label: Text('Grade'),
                    ),
                    Chip(
                      avatar: CircleAvatar(child: Text('6', style: TextStyle(fontSize: 10))),
                      label: Text('STATUS (rank)'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '* Admission No and Subject Marks columns are mandatory.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sample Class Template Preview:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    columns: const [
                      DataColumn(label: Text('ADMISSION NO`', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('STUDENT NAME', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('THAREEEQ', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('LISANUL QURAN', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('DUROOSUL IHSAN', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('FIQH', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('TOTAL (200)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('STATUS (rank)', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: const [
                      DataRow(cells: [
                        DataCell(Text('1320')),
                        DataCell(Text('M.MISHHAL')),
                        DataCell(Text('6')),
                        DataCell(Text('18')),
                        DataCell(Text('20')),
                        DataCell(Text('7')),
                        DataCell(Text('51')),
                        DataCell(Text('')),
                        DataCell(Text('8')),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('1306')),
                        DataCell(Text('SHAMMAS')),
                        DataCell(Text('8')),
                        DataCell(Text('20')),
                        DataCell(Text('11')),
                        DataCell(Text('12')),
                        DataCell(Text('51')),
                        DataCell(Text('')),
                        DataCell(Text('8')),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('1324')),
                        DataCell(Text('M.SINAN M')),
                        DataCell(Text('9')),
                        DataCell(Text('18')),
                        DataCell(Text('25')),
                        DataCell(Text('18')),
                        DataCell(Text('70')),
                        DataCell(Text('')),
                        DataCell(Text('5')),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sampleCsv));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV Template copied to clipboard!'),
                  backgroundColor: Color(0xFF059669),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy CSV Template'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFC6C6CD);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F172A)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
        body: Center(
          child: Card(
            color: Colors.red.shade50,
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error loading results manager: $_error',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSetupData,
                    child: const Text('Retry Loading Data'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Container(
                  padding: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 0.8),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 768;
                      return isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload Student Results',
                                  style: TextStyle(
                                    fontFamily: 'Serif',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Select a class and upload examination results for processing.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF45464D),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                    side: BorderSide(color: borderColor, width: 0.8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  onPressed: _downloadTemplate,
                                  icon: const Icon(
                                    Icons.download_outlined,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Download Results Template',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Upload Student Results',
                                        style: TextStyle(
                                          fontFamily: 'Serif',
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Select a class and upload examination results for processing.',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Color(0xFF45464D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                    side: BorderSide(color: borderColor, width: 0.8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  onPressed: _downloadTemplate,
                                  icon: const Icon(
                                    Icons.download_outlined,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Download Results Template',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Bento Style Layout (2 Columns on Desktop)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 992;
                    return isDesktop
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildLeftColumn(
                                isDark: isDark,
                                borderColor: borderColor,
                                cardBg: cardBg,
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 1,
                              child: _buildRightColumn(
                                isDark: isDark,
                                borderColor: borderColor,
                                cardBg: cardBg,
                              ),
                            ),
                          ],
                        )
                        : Column(
                          children: [
                            _buildLeftColumn(
                              isDark: isDark,
                              borderColor: borderColor,
                              cardBg: cardBg,
                            ),
                            const SizedBox(height: 32),
                            _buildRightColumn(
                              isDark: isDark,
                              borderColor: borderColor,
                              cardBg: cardBg,
                            ),
                          ],
                        );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn({
    required bool isDark,
    required Color borderColor,
    required Color cardBg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File Upload Card
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFF9B4500),
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'File Upload',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE6E8EA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Accepted: .csv, .xlsx',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF45464D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Drag & Drop Box
              InkWell(
                onTap: _showExcelUploadDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF7F9FB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE6E8EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload_file_outlined,
                          size: 36,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Drag and drop student results file here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'or click to browse your computer files',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF45464D),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: _showExcelUploadDialog,
                        child: const Text(
                          'Browse Files',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Required Excel/CSV Format Guidance Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.help_outline_rounded, size: 18, color: Color(0xFF0F172A)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Required Result File Columns Format',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _downloadTemplate,
                          icon: const Icon(Icons.download_outlined, size: 14),
                          label: const Text(
                            'View / Download Template',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFormatHeaderBadge('Admission Number', isRequired: true),
                          _buildFormatHeaderBadge('Student Name', isRequired: false),
                          _buildFormatHeaderBadge('Subject', isRequired: true),
                          _buildFormatHeaderBadge('Exam', isRequired: true),
                          _buildFormatHeaderBadge('Marks', isRequired: true),
                          _buildFormatHeaderBadge('Total Marks', isRequired: false),
                          _buildFormatHeaderBadge('Grade', isRequired: false),
                          _buildFormatHeaderBadge('Remarks', isRequired: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Uploaded Results Table
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Text(
                    'Uploaded Results',
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () => _showUploadResultDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Add Single Result',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh Results',
                        onPressed: _refreshResults,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No examination results recorded yet.',
                      style: TextStyle(color: Color(0xFF45464D)),
                    ),
                  ),
                )
              else
                _buildMatrixUploadedResultsTable(
                  borderColor: borderColor,
                  isDark: isDark,
                ),
            ],
          ),
        ),

      ],
    );
  }

  void _deleteStudentResults(_StudentMatrixRow row) async {
    final resultRepo = context.read<ResultRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student Results'),
        content: Text('Are you sure you want to delete all examination results for ${row.student.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        for (final r in row.resultsList) {
          await resultRepo.deleteResult(r.id);
        }
        if (!mounted) return;
        await _refreshResults();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting results: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildMatrixUploadedResultsTable({
    required Color borderColor,
    required bool isDark,
  }) {
    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No examination results recorded yet.',
            style: TextStyle(color: Color(0xFF45464D)),
          ),
        ),
      );
    }

    final Map<String, List<Result>> studentResultsMap = {};
    for (final r in _results) {
      studentResultsMap.putIfAbsent(r.studentId, () => []).add(r);
    }

    final List<String> subjectNames = [];
    for (final r in _results) {
      final name = r.subjectName ?? _subjects.firstWhere(
        (s) => s.id == r.subjectId,
        orElse: () => Subject(id: r.subjectId, subjectName: '', classId: '', createdAt: DateTime.now()),
      ).subjectName;
      if (name.isNotEmpty && !subjectNames.contains(name)) {
        subjectNames.add(name);
      }
    }

    final List<_StudentMatrixRow> matrixRows = [];

    for (final entry in studentResultsMap.entries) {
      final sId = entry.key;
      final resList = entry.value;

      final firstRes = resList.first;
      final studentObj = _students.firstWhere(
        (s) => s.id == sId,
        orElse: () => Student(
          id: sId,
          admissionNumber: firstRes.studentName != null ? shortId(sId) : '',
          rollNumber: '',
          fullName: firstRes.studentName ?? 'Student (${shortId(sId)})',
          classId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      double totalObtained = 0;
      double totalMax = 0;
      bool hasFailedSubject = false;

      final Map<String, Result> subMap = {};
      for (final r in resList) {
        final name = r.subjectName ?? _subjects.firstWhere((s) => s.id == r.subjectId, orElse: () => Subject(id: r.subjectId, subjectName: 'Sub', classId: '', createdAt: DateTime.now())).subjectName;
        subMap[name] = r;
        final m = r.marksObtained ?? 0;
        totalObtained += m;
        totalMax += (r.maximumMarks > 0 ? r.maximumMarks : 50);

        if (m < 18 || r.grade == 'F') {
          hasFailedSubject = true;
        }
      }

      final String overallGrade = hasFailedSubject ? 'FAILED' : 'PASSED';

      matrixRows.add(_StudentMatrixRow(
        student: studentObj,
        subjectMarksMap: subMap,
        totalObtained: totalObtained,
        totalMax: totalMax,
        grade: overallGrade,
        resultsList: resList,
      ));
    }

    matrixRows.sort((a, b) => b.totalObtained.compareTo(a.totalObtained));
    for (int i = 0; i < matrixRows.length; i++) {
      matrixRows[i].rank = i + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(color: borderColor.withValues(alpha: 0.5), width: 1),
        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        columns: [
          const DataColumn(label: Text('ADMISSION NO`', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('STUDENT NAME', style: TextStyle(fontWeight: FontWeight.bold))),
          for (final subName in subjectNames)
            DataColumn(label: Text(subName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('STATUS (rank)', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: matrixRows.map((row) {
          return DataRow(
            cells: [
              DataCell(Text(row.student.admissionNumber.isNotEmpty ? row.student.admissionNumber : shortId(row.student.id))),
              DataCell(Text(row.student.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
              for (final subName in subjectNames)
                DataCell(
                  Center(
                    child: Text(
                      row.subjectMarksMap.containsKey(subName) && row.subjectMarksMap[subName]?.marksObtained != null
                          ? '${row.subjectMarksMap[subName]!.marksObtained!.toInt()}'
                          : '-',
                      style: TextStyle(
                        color: (row.subjectMarksMap[subName]?.marksObtained ?? 0) < 18 ? Colors.red : null,
                        fontWeight: (row.subjectMarksMap[subName]?.marksObtained ?? 0) < 18 ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              DataCell(Text('${row.totalObtained.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(
                StatusBadge(
                  label: row.grade,
                  color: row.grade == 'PASSED'
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    '${row.rank}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Marks',
                      onPressed: () => _showUploadResultDialog(resultToEdit: row.resultsList.first),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'Delete Student Results',
                      onPressed: () => _deleteStudentResults(row),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRightColumn({
    required bool isDark,
    required Color borderColor,
    required Color cardBg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Guidelines Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: borderColor, width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Upload Guidelines',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Column(
                children: [
                  _GuidelineItem(
                    text:
                        'File must include header columns: Admission Number, Subject, Exam, Marks, Total Marks, Remarks.',
                  ),
                  SizedBox(height: 12),
                  _GuidelineItem(
                    text:
                        'Ensure Admission Number, Subject, and Exam match system records.',
                  ),
                  SizedBox(height: 12),
                  _GuidelineItem(
                    text: 'Marks obtained must not exceed Total Marks (default 100).',
                  ),
                  SizedBox(height: 12),
                  _GuidelineItem(
                    text: 'Supported file types: Excel (.xlsx, .xls) and CSV (.csv). Maximum size 10MB.',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Recent Uploads Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: Color(0xFF9B4500),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Recent Uploads',
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Uploads Table
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(70),
                  1: FlexColumnWidth(),
                  2: FixedColumnWidth(95),
                },
                children: [
                  // Table Header
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 0.8),
                      ),
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF45464D),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Class',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF45464D),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF45464D),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Dynamic Recent Upload Rows
                  if (_results.isNotEmpty)
                    ..._results.take(3).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final res = entry.value;
                      final isLast = index == _results.take(3).length - 1;
                      final teacherClass = context.read<Teacher>().assignedClassName ?? 'Class';
                      final dateStr = '${res.createdAt.day}/${res.createdAt.month}';
                      final label = res.subjectName != null && res.subjectName!.isNotEmpty
                          ? '$teacherClass (${res.subjectName})'
                          : teacherClass;
                      return _buildRecentUploadRow(
                        date: dateStr,
                        className: label,
                        status: res.isPublished ? 'PROCESSED' : 'PENDING',
                        isProcessed: res.isPublished,
                        borderColor: borderColor,
                        isLast: isLast,
                      );
                    })
                  else
                    _buildRecentUploadRow(
                      date: '-',
                      className: 'No upload history',
                      status: 'NONE',
                      isProcessed: false,
                      borderColor: borderColor,
                      isLast: true,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: borderColor, width: 0.8),
                  ),
                ),
                child: Center(
                  child: TextButton(
                    onPressed: _refreshResults,
                    child: const Text(
                      'View All Upload History',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildRecentUploadRow({
    required String date,
    required String className,
    required String status,
    required bool isProcessed,
    required Color borderColor,
    bool isLast = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            date,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            className,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isProcessed
                        ? const Color(0xFFE6F4EA)
                        : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color:
                      isProcessed
                          ? const Color(0xFF137333)
                          : const Color(0xFFE65100),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatHeaderBadge(String label, {required bool isRequired}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isRequired ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isRequired ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Text(
        '$label${isRequired ? ' *' : ''}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: isRequired ? FontWeight.bold : FontWeight.w500,
          color: isRequired ? const Color(0xFF1E40AF) : const Color(0xFF475569),
        ),
      ),
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  final String text;
  const _GuidelineItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          color: Color(0xFF9B4500),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF45464D),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadResultDialog extends StatefulWidget {
  final List<Exam> exams;
  final List<Subject> subjects;
  final List<Student> students;
  final Result? initialResult;
  final VoidCallback onSaved;

  const _UploadResultDialog({
    required this.exams,
    required this.subjects,
    required this.students,
    this.initialResult,
    required this.onSaved,
  });

  @override
  State<_UploadResultDialog> createState() => _UploadResultDialogState();
}

class _UploadResultDialogState extends State<_UploadResultDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStudentId;
  String? _selectedExamId;
  String? _selectedSubjectId;

  late TextEditingController _marksController;
  late TextEditingController _totalMarksController;
  late TextEditingController _gradeController;
  late TextEditingController _remarksController;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final res = widget.initialResult;

    _selectedStudentId = (res?.studentId != null && widget.students.any((s) => s.id == res!.studentId))
        ? res!.studentId
        : (widget.students.isNotEmpty ? widget.students.first.id : null);
    _selectedExamId = (res?.examId != null && widget.exams.any((e) => e.id == res!.examId))
        ? res!.examId
        : (widget.exams.isNotEmpty ? widget.exams.first.id : null);
    _selectedSubjectId = (res?.subjectId != null && widget.subjects.any((s) => s.id == res!.subjectId))
        ? res!.subjectId
        : (widget.subjects.isNotEmpty ? widget.subjects.first.id : null);

    _marksController = TextEditingController(
      text: res?.marksObtained != null ? res!.marksObtained.toString() : '',
    );
    _totalMarksController = TextEditingController(
      text: res?.maximumMarks != null ? res!.maximumMarks.toInt().toString() : '100',
    );
    _gradeController = TextEditingController(text: res?.grade ?? '');
    _remarksController = TextEditingController(text: res?.remarks ?? '');

    _marksController.addListener(_recalculateGrade);
    _totalMarksController.addListener(_recalculateGrade);
  }

  @override
  void dispose() {
    _marksController.dispose();
    _totalMarksController.dispose();
    _gradeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _recalculateGrade() {
    final marks = double.tryParse(_marksController.text);
    final total = double.tryParse(_totalMarksController.text) ?? 100;
    if (marks == null || total <= 0) {
      _gradeController.text = '';
      return;
    }
    final percentage = (marks / total) * 100;
    if (percentage >= 90) {
      _gradeController.text = 'A+';
    } else if (percentage >= 80) {
      _gradeController.text = 'A';
    } else if (percentage >= 70) {
      _gradeController.text = 'B+';
    } else if (percentage >= 60) {
      _gradeController.text = 'B';
    } else if (percentage >= 50) {
      _gradeController.text = 'C';
    } else if (percentage >= 35) {
      _gradeController.text = 'D';
    } else {
      _gradeController.text = 'F';
    }
  }

  Future<void> _submit() async {
    debugPrint('[FLUTTER RESULTS DIALOG] Save Result button pressed');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[FLUTTER RESULTS DIALOG] Form validation failed');
      return;
    }
    if (_selectedStudentId == null || _selectedSubjectId == null || _selectedExamId == null) {
      debugPrint('[FLUTTER RESULTS DIALOG ERROR] Missing student/exam/subject selection');
      setState(() => _errorMessage = 'Please select Student, Exam, and Subject.');
      return;
    }

    final marks = double.tryParse(_marksController.text);
    final total = double.tryParse(_totalMarksController.text) ?? 100;

    if (marks == null) {
      debugPrint('[FLUTTER RESULTS DIALOG ERROR] Invalid marks input: ${_marksController.text}');
      setState(() => _errorMessage = 'Please enter valid marks.');
      return;
    }

    if (marks > total) {
      debugPrint('[FLUTTER RESULTS DIALOG ERROR] Marks ($marks) exceeds Total ($total)');
      setState(() => _errorMessage = 'Marks Obtained cannot exceed Total Marks.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<ResultRepository>();
      final isEdit = widget.initialResult != null;

      final resultData = Result(
        id: widget.initialResult?.id ?? '',
        examId: _selectedExamId!,
        studentId: _selectedStudentId!,
        subjectId: _selectedSubjectId!,
        marksObtained: marks,
        maximumMarks: total,
        grade: _gradeController.text,
        resultStatus: (marks >= total * 0.35) ? 'Pass' : 'Fail',
        remarks: _remarksController.text,
        isPublished: true,
        publishedAt: DateTime.now(),
        createdAt: widget.initialResult?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('[FLUTTER RESULTS DIALOG] Submitting ${isEdit ? "PUT" : "POST"} result to backend...');

      if (isEdit) {
        final updated = await repo.updateResult(resultData);
        debugPrint('[FLUTTER RESULTS DIALOG] Result updated successfully! ID: ${updated.id}');
      } else {
        final created = await repo.createResult(resultData);
        debugPrint('[FLUTTER RESULTS DIALOG] Result created successfully! ID: ${created.id}');
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('[FLUTTER RESULTS DIALOG ERROR] Submit error: $e\n$stack');
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialResult != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Result' : 'Add Single Student Result'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9 < 480 ? MediaQuery.of(context).size.width * 0.9 : 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                    ),
                  ),
                // Student Dropdown
                DropdownButtonFormField<String>(
                  initialValue: (_selectedStudentId != null && widget.students.any((s) => s.id == _selectedStudentId)) ? _selectedStudentId : null,
                  decoration: const InputDecoration(
                    labelText: 'Student *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final s in widget.students)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.fullName} (${s.rollNumber})'),
                      ),
                  ],
                  onChanged: isEdit
                      ? null
                      : (val) => setState(() => _selectedStudentId = val),
                  validator: (val) => val == null ? 'Student is required' : null,
                ),
                const SizedBox(height: 14),
                // Exam Dropdown
                DropdownButtonFormField<String>(
                  initialValue: (_selectedExamId != null && widget.exams.any((e) => e.id == _selectedExamId)) ? _selectedExamId : null,
                  decoration: const InputDecoration(
                    labelText: 'Exam *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final e in widget.exams)
                      DropdownMenuItem(
                        value: e.id,
                        child: Text(e.examName),
                      ),
                  ],
                  onChanged: isEdit
                      ? null
                      : (val) => setState(() => _selectedExamId = val),
                  validator: (val) => val == null ? 'Exam is required' : null,
                ),
                const SizedBox(height: 14),
                // Subject Dropdown
                DropdownButtonFormField<String>(
                  initialValue: (_selectedSubjectId != null && widget.subjects.any((s) => s.id == _selectedSubjectId)) ? _selectedSubjectId : null,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final sub in widget.subjects)
                      DropdownMenuItem(
                        value: sub.id,
                        child: Text(sub.subjectName),
                      ),
                  ],
                  onChanged: isEdit
                      ? null
                      : (val) {
                          setState(() {
                            _selectedSubjectId = val;
                            final subObj = widget.subjects.firstWhere(
                              (s) => s.id == val,
                              orElse: () => Subject(
                                id: '',
                                subjectName: '',
                                classId: '',
                                maximumMarks: 100,
                                createdAt: DateTime.now(),
                              ),
                            );
                            _totalMarksController.text = subObj.maximumMarks.toInt().toString();
                          });
                        },
                  validator: (val) => val == null ? 'Subject is required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _marksController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Marks Obtained *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final m = double.tryParse(val);
                          if (m == null || m < 0) return 'Invalid';
                          final total = double.tryParse(_totalMarksController.text) ?? 100;
                          if (m > total) return 'Max $total';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _totalMarksController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Marks *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final t = double.tryParse(val);
                          if (t == null || t <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gradeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Grade (Auto)',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Result'),
        ),
      ],
    );
  }
}

class _StudentMatrixRow {
  final Student student;
  final Map<String, Result> subjectMarksMap;
  final double totalObtained;
  final double totalMax;
  final String grade;
  final List<Result> resultsList;
  int rank;

  _StudentMatrixRow({
    required this.student,
    required this.subjectMarksMap,
    required this.totalObtained,
    required this.totalMax,
    required this.grade,
    required this.resultsList,
    this.rank = 0,
  });
}


