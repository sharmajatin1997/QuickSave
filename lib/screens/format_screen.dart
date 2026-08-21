import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_downloader/utils/string_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/video_info.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../widgets/neubrutal.dart';
import '../utils/language_notifier.dart';

class FormatScreen extends StatefulWidget {
  final String url;
  final VideoInfo info;

  const FormatScreen({super.key, required this.url, required this.info});

  @override
  State<FormatScreen> createState() => _FormatScreenState();
}

class _FormatScreenState extends State<FormatScreen> {
  final ApiService _api = ApiService();
  final HistoryService _history = HistoryService();

  VideoFormat? _selected;
  bool _audioSelected = false;
  bool _downloading = false;
  double _progress = 0;

  List<VideoFormat> get _videoFormats =>
      widget.info.formats.where((f) => f.hasVideo).toList();

  Future<void> _handleDownload({bool audioOnly = false}) async {
    final isAudio = audioOnly || _audioSelected;
    if (!isAudio && _selected == null) {
      _showAlert(StringHelper.chooseAQualityFirst);
      return;
    }

    setState(() {
      _downloading = true;
      _progress = 0;
    });

    try {
      final fileUrl = await _api.requestDownload(
        url: widget.url,
        formatId: isAudio ? null : _selected?.formatId,
        audioOnly: isAudio,
      );

      final dir = await getApplicationDocumentsDirectory();
      final ext = isAudio ? 'mp3' : 'mp4';
      final savePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _api.downloadFile(
        fileUrl: fileUrl,
        savePath: savePath,
        onProgress: (received, total) {
          if (total > 0) setState(() => _progress = received / total);
        },
      );

      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.videos.request();
        if (status.isDenied) status = await Permission.storage.request();
      } else {
        status = PermissionStatus.granted;
      }

      if (status.isGranted || Platform.isIOS) {
        if (!isAudio) {
          await GallerySaver.saveVideo(savePath);
        }
      }

      await _history.addItem(HistoryItem(
        title: widget.info.title,
        thumbnail: widget.info.thumbnail,
        localPath: savePath,
        savedAt: DateTime.now().millisecondsSinceEpoch,
        audioOnly: isAudio,
        actionType: StringHelper.tagDownload,
      ));

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      showNeuDialog(
        context: context,
        title: StringHelper.downloadFailed,
        body: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showAlert(String message) {
    showNeuDialog(
      context: context,
      title: StringHelper.error,
      body: message,
    );
  }

  void _showSuccessDialog() {
    showNeuDialog(
      context: context,
      title: StringHelper.saved,
      body: StringHelper.yourFileHasBeenSavedToYourDevice,
      actions: [
        Expanded(
          child: NeuButton(
            onTap: () {
              Navigator.pop(context);
              context.push('/history');
            },
            color: Colors.white,
            height: 48,
            child:  Text(StringHelper.viewHistory, style: const TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NeuButton(
            onTap: () => Navigator.pop(context),
            color: NeuColors.accent,
            height: 48,
            child:  Text(StringHelper.ok, style: const TextStyle(fontSize: 14)),
          ),
        ),
      ],
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
            title: StringHelper.appName,
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.info.thumbnail != null)
                          NeuContainer(
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: widget.info.thumbnail!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ).animate().fadeIn().scale(curve: Curves.easeOutBack),
                        const SizedBox(height: 16),
                        Text(
                          widget.info.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                        Text(
                          'from ${widget.info.extractor}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 24),
                        Text(StringHelper.videoQuality, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor))
                            .animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 12),
                        Column(
                          children: _videoFormats.map((f) => _buildFormatItem(f, textColor)).toList()
                            .animate(interval: 50.ms).fadeIn(delay: 500.ms).slideY(begin: 0.1),
                        ),
                        const SizedBox(height: 20),
                        Text(StringHelper.audioQuality, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor))
                            .animate().fadeIn(delay: 800.ms),
                        const SizedBox(height: 12),
                        _buildAudioItem(textColor).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (_downloading) ...[
                        NeuContainer(
                          padding: const EdgeInsets.all(4),
                          borderRadius: 20,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: _progress > 0 ? _progress : null,
                              minHeight: 12,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(NeuColors.primary),
                            ),
                          ),
                        ).animate().fadeIn().scaleY(),
                        const SizedBox(height: 16),
                      ],
                      NeuButton(
                        onTap: _downloading ? null : () => _handleDownload(),
                        color: NeuColors.primary,
                        child: Text(
                          _downloading ? '${StringHelper.downloading}...' : (_audioSelected ? '${StringHelper.downloadBtn} ${StringHelper.mp3}' : '${StringHelper.downloadBtn} ${StringHelper.video}'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildFormatItem(VideoFormat f, Color textColor) {
    final isSelected = _selected?.formatId == f.formatId && !_audioSelected;
    return GestureDetector(
      onTap: () => setState(() {
        _selected = f;
        _audioSelected = false;
      }),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NeuContainer(
          color: isSelected ? NeuColors.accent : null, // respects theme if null
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.play_circle_outline, color: isSelected ? Colors.black : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${f.resolution} · ${f.ext.toUpperCase()}',
                  style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.black : textColor),
                ),
              ),
              Text(f.sizeLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioItem(Color textColor) {
    return GestureDetector(
      onTap: () => setState(() {
        _selected = null;
        _audioSelected = true;
      }),
      child: NeuContainer(
        color: _audioSelected ? NeuColors.secondary : null, // respects theme if null
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.music_note, color: _audioSelected ? Colors.black : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                StringHelper.highQualityMP3,
                style: TextStyle(fontWeight: FontWeight.w900, color: _audioSelected ? Colors.black : textColor),
              ),
            ),
             Text(StringHelper.audioOnly, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
