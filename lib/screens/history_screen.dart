import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/video_info.dart';
import '../services/history_service.dart';
import '../widgets/neubrutal.dart';
import '../utils/string_helper.dart';
import '../utils/language_notifier.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _historyService.getHistory();
    setState(() => _items = items);
  }

  Future<void> _clear() async {
    await _historyService.clear();
    setState(() => _items = []);
  }

  Color _getTagColor(String type) {
    if (type == StringHelper.tagTrim) return NeuColors.secondary;
    if (type == StringHelper.tagConvert) return NeuColors.accent;
    if (type == StringHelper.tagEraser) return const Color(0xFFB2FF59); // Light Green for Erased
    return NeuColors.primary; // Default for Download
  }

  Widget _buildPlaceholderIcon(bool audioOnly) {
    return Container(
      width: 60,
      height: 60,
      color: audioOnly ? const Color(0xFFFFE082) : const Color(0xFFB2EBF2),
      child: Icon(
        audioOnly ? Icons.music_note_rounded : Icons.movie_creation_rounded,
        color: Colors.black54,
        size: 30,
      ),
    );
  }

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
            title: StringHelper.history,
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: _items.isEmpty
              ? Center(
                  child: Text(StringHelper.noHistory, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ).animate().fadeIn()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          final date = DateTime.fromMillisecondsSinceEpoch(item.savedAt);
                          return Builder(
                            builder: (itemContext) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    if (item.localPath.isNotEmpty) {
                                      final box = itemContext.findRenderObject() as RenderBox?;
                                      Share.shareXFiles(
                                        [XFile(item.localPath)],
                                        text: item.title,
                                        sharePositionOrigin: box != null 
                                            ? (box.localToGlobal(Offset.zero) & box.size) 
                                            : null,
                                      );
                                    }
                                  },
                                  child: NeuContainer(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        NeuContainer(
                                          padding: EdgeInsets.zero,
                                          borderRadius: 8,
                                          shadowOffset: 2,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: (item.thumbnail != null && item.thumbnail!.isNotEmpty)
                                                ? CachedNetworkImage(
                                                    imageUrl: item.thumbnail!,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (context, url, error) => _buildPlaceholderIcon(item.audioOnly),
                                                  )
                                                : _buildPlaceholderIcon(item.audioOnly),
                                          ),
                                        ).animate().scale(delay: (i * 100).ms, curve: Curves.easeOutBack),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: textColor),
                                                    ),
                                                  ),
                                                  if (item.actionType != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 8.0),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: _getTagColor(item.actionType!),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: Colors.black, width: 1),
                                                        ),
                                                        child: Text(
                                                          item.actionType!.toUpperCase(),
                                                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    item.audioOnly ? Icons.music_note : Icons.videocam,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${item.audioOnly ? StringHelper.mp3 : StringHelper.video} · ${date.day}/${date.month}/${date.year}',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.open_in_new, size: 20, color: isDark ? Colors.white : Colors.black),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: NeuButton(
                        onTap: _clear,
                        color: NeuColors.primary,
                        child: Text(StringHelper.clearHistory, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  ],
                ),
        );
      }
    );
  }
}
