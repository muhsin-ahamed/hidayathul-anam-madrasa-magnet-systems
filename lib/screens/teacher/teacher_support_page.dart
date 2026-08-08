// teacher_support_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherSupportPage extends StatefulWidget {
  const TeacherSupportPage({super.key});

  @override
  State<TeacherSupportPage> createState() => _TeacherSupportPageState();
}

class _TeacherSupportPageState extends State<TeacherSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // FAQ items list
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I correctly format the results CSV for upload?',
      'answer':
          'The CSV file must contain columns for \'Student ID\', \'Course Code\', and \'Grade\'. Ensure there are no empty rows and that \'Student ID\' perfectly matches the registrar\'s database format. Download the template from the \'Upload Results\' page.',
      'category': 'Results',
    },
    {
      'question': 'What is the file size limit for uploading lecture notes?',
      'answer':
          'Lecture notes (PDF, PPTX, DOCX) must not exceed 50MB per file. For larger presentations containing video or high-res images, please provide a shared drive link in the class announcements instead.',
      'category': 'Notes',
    },
    {
      'question': 'How can I view a student\'s past academic history?',
      'answer':
          'Navigate to \'My Students\', select the specific student, and click on the \'Academic Transcript\' tab. This section is restricted and requires reverification of your faculty credentials.',
      'category': 'Students',
    },
    {
      'question': 'How do I generate and print hall tickets for my class?',
      'answer':
          'Go to the \'Hall Tickets\' section from the sidebar, select your assigned class and examination term, then click \'Generate All\'. You can batch download or print PDF tickets directly.',
      'category': 'Exams',
    },
    {
      'question': 'What should I do if a student\'s attendance record is incorrect?',
      'answer':
          'Faculty members can update attendance logs within 48 hours of submission. For older corrections, submit a request via \'Raise a Ticket\' with the student ID and session date.',
      'category': 'Attendance',
    },
  ];

  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs.where((faq) {
      final q = faq['question']!.toLowerCase();
      final a = faq['answer']!.toLowerCase();
      final c = (faq['category'] ?? '').toLowerCase();
      return q.contains(_searchQuery) || a.contains(_searchQuery) || c.contains(_searchQuery);
    }).toList();
  }

  void _showRaiseTicketDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'General Technical Support';
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Raise a Support Ticket',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(dialogCtx).size.width * 0.9 < 500 ? MediaQuery.of(dialogCtx).size.width * 0.9 : 500),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [
                        'General Technical Support',
                        'Results CSV Upload Issue',
                        'Lecture Notes Upload',
                        'Account & Permissions',
                        'Exam / Hall Tickets',
                      ]
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) selectedCategory = val;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Priority Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['Low', 'Medium', 'High', 'Urgent']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) selectedPriority = val;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Subject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: subjectController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a subject' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Error uploading Term 1 Math CSV file',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please provide detailed issue description' : null,
                      decoration: InputDecoration(
                        hintText: 'Describe the issue or error message in detail...',
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogCtx);
                  final ticketId = 'TK-${10000 + (DateTime.now().millisecondsSinceEpoch % 89999)}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Support ticket #$ticketId created successfully. IT Team will contact you soon.'),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Submit Ticket'),
            ),
          ],
        );
      },
    );
  }

  void _showResourceDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFC6C6CD);
    final textColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final mutedTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF45464D);

    final filteredList = _filteredFaqs;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support Center',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Serif',
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'How can we assist you today?',
                        style: TextStyle(
                          fontSize: 18,
                          color: mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Search Bar
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 768),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search for help articles, FAQs, or documentation...',
                      hintStyle: TextStyle(color: mutedTextColor),
                      prefixIcon: Icon(Icons.search, color: mutedTextColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: cardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: textColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Main Layout Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FAQ Column (8 units / 66%)
                          Expanded(
                            flex: 8,
                            child: _buildFaqSection(cardBg, borderColor, textColor, mutedTextColor, filteredList),
                          ),
                          const SizedBox(width: 28),
                          // Sidebar Column (4 units / 33%)
                          Expanded(
                            flex: 4,
                            child: _buildSidebarSection(context, cardBg, borderColor, textColor, mutedTextColor),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFaqSection(cardBg, borderColor, textColor, mutedTextColor, filteredList),
                          const SizedBox(height: 32),
                          _buildSidebarSection(context, cardBg, borderColor, textColor, mutedTextColor),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color mutedTextColor,
    List<Map<String, String>> filteredList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.forum_outlined, color: textColor, size: 26),
            const SizedBox(width: 10),
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (filteredList.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_outlined, size: 48, color: mutedTextColor),
                  const SizedBox(height: 12),
                  Text(
                    'No matching FAQ articles found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try searching with different keywords or raise a support ticket.',
                    style: TextStyle(fontSize: 14, color: mutedTextColor),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
              itemBuilder: (context, index) {
                final item = filteredList[index];
                final isExpanded = _expandedIndices.contains(index);
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: Key('faq_$index'),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        if (expanded) {
                          _expandedIndices.add(index);
                        } else {
                          _expandedIndices.remove(index);
                        }
                      });
                    },
                    title: Text(
                      item['question']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    trailing: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: mutedTextColor,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    children: [
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item['answer']!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: mutedTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarSection(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Contact Support Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.06),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.support_agent, size: 140, color: textColor),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need more help?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our IT support team is available during standard academic hours (8AM - 6PM) for technical assistance.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: mutedTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _showRaiseTicketDialog(context),
                      icon: const Icon(Icons.confirmation_number_outlined, size: 18, color: Colors.orangeAccent),
                      label: const Text(
                        'Raise a Ticket',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: borderColor, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        final Uri whatsappUrl = Uri.parse('https://wa.me/919947929206');
                        try {
                          if (await canLaunchUrl(whatsappUrl)) {
                            await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                          } else {
                            await launchUrl(whatsappUrl);
                          }
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open WhatsApp. Contact: +91 9947929206'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.green),
                      label: const Text(
                        'WhatsApp IT Support',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Useful Resources Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'USEFUL RESOURCES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: mutedTextColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildResourceItem(
                icon: Icons.menu_book_outlined,
                label: 'Faculty Handbook',
                onTap: () => _showResourceDialog(
                  context,
                  'Faculty Handbook',
                  'The Faculty Handbook provides comprehensive operational guidelines, academic codes of conduct, and administrative policies for teachers.',
                ),
                textColor: textColor,
                mutedColor: mutedTextColor,
              ),
              const SizedBox(height: 14),
              _buildResourceItem(
                icon: Icons.developer_board_outlined,
                label: 'System Documentation',
                onTap: () => _showResourceDialog(
                  context,
                  'System Documentation',
                  'Comprehensive user guide covering CSV results upload, lecture notes management, student profile tracking, and grade reports.',
                ),
                textColor: textColor,
                mutedColor: mutedTextColor,
              ),
              const SizedBox(height: 14),
              _buildResourceItem(
                icon: Icons.security_outlined,
                label: 'Data Privacy Guidelines',
                onTap: () => _showResourceDialog(
                  context,
                  'Data Privacy Guidelines',
                  'Information on FERPA and student records privacy compliance, secure credential management, and data protection practices.',
                ),
                textColor: textColor,
                mutedColor: mutedTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResourceItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
    required Color mutedColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: mutedColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: mutedColor,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
