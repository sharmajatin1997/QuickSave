import 'package:flutter/material.dart';
import '../widgets/neubrutal.dart';
import '../utils/string_helper.dart';

class ContentDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  const ContentDetailScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F0F0),
      appBar: NeuAppBar(
        title: title,
        leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: NeuContainer(
          padding: const EdgeInsets.all(24),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

class FAQDetailScreen extends StatelessWidget {
  const FAQDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F0F0),
      appBar: NeuAppBar(
        title: StringHelper.faq,
        leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildFAQItem(context, StringHelper.faqQ1, StringHelper.faqA1),
          _buildFAQItem(context, StringHelper.faqQ2, StringHelper.faqA2),
          _buildFAQItem(context, StringHelper.faqQ3, StringHelper.faqA3),
          _buildFAQItem(context, StringHelper.faqQ4, StringHelper.faqA4),
          _buildFAQItem(context, StringHelper.faqQ8, StringHelper.faqA8),
          _buildFAQItem(context, StringHelper.faqQ5, StringHelper.faqA5),
          _buildFAQItem(context, StringHelper.faqQ6, StringHelper.faqA6),
          _buildFAQItem(context, StringHelper.faqQ7, StringHelper.faqA7),
          _buildFAQItem(context, StringHelper.faqQ9, StringHelper.faqA9),
          _buildFAQItem(context, StringHelper.faqQ10, StringHelper.faqA10),
          _buildFAQItem(context, StringHelper.faqQ11, StringHelper.faqA11),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String q, String a) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeuContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              a,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
