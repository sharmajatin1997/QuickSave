import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../widgets/neubrutal.dart';
import '../utils/string_helper.dart';
import '../utils/language_notifier.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return ValueListenableBuilder<String>(
      valueListenable: LanguageNotifier.languageCode,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F0F0),
          appBar: NeuAppBar(
            title: StringHelper.mediaTools,
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StringHelper.seeAll,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
                ).animate().fadeIn().slideX(begin: -0.1),
                Text(
                  StringHelper.mediaToolsSubtitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),
                Column(
                  children: [
                    _buildToolCard(StringHelper.removeWatermark, StringHelper.removeWatermarkDesc, Icons.auto_fix_high_rounded, const Color(0xFFE1F5FE), textColor, 0, onTap: () => context.push('/remove-watermark')),
                    _buildToolCard(StringHelper.addWatermark, StringHelper.addWatermarkDesc, Icons.branding_watermark_rounded, const Color(0xFFF3E5F5), textColor, 100, onTap: () => context.push('/add-watermark')),
                    _buildToolCard(StringHelper.trimVideo, StringHelper.trimVideoDesc, Icons.content_cut, const Color(0xFFE8F5E9), textColor, 200, onTap: () => context.push('/trim')),
                    _buildToolCard(StringHelper.convertFormat, StringHelper.convertFormatDesc, Icons.swap_horiz, const Color(0xFFFFF3E0), textColor, 300, onTap: () => context.push('/convert')),
                    _buildToolCard(StringHelper.compress, StringHelper.compressDesc, Icons.compress, const Color(0xFFF1F8E9), textColor, 400, onTap: () => context.push('/compress')),
                    _buildToolCard(StringHelper.removeAudio, StringHelper.removeAudioDesc, Icons.volume_off, const Color(0xFFFFEBEE), textColor, 500, onTap: () => context.push('/remove-audio')),
                    _buildToolCard(StringHelper.extractMp3, StringHelper.extractMp3Desc, Icons.music_note, const Color(0xFFE1F5FE), textColor, 600),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildToolCard(String title, String subtitle, IconData icon, Color iconBg, Color textColor, int delay, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: NeuContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(icon, color: Colors.black),
              ).animate().scale(delay: (200 + delay).ms, curve: Curves.elasticOut),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),maxLines: 1,overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textColor.withValues(alpha: 0.5)),
            ],
          ),
        ).animate().fadeIn(delay: (200 + delay).ms).slideX(begin: 0.1),
      ),
    );
  }
}
