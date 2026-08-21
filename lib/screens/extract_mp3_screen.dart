import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/neubrutal.dart';
import '../utils/string_helper.dart';
import '../utils/language_notifier.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../models/video_info.dart';

class ExtractMp3Screen extends StatefulWidget {
  const ExtractMp3Screen({super.key});

  @override
  State<ExtractMp3Screen> createState() => _ExtractMp3ScreenState();
}

class _ExtractMp3ScreenState extends State<ExtractMp3Screen> {
  final TextEditingController _urlController = TextEditingController();
  final ApiService _api = ApiService();
  final HistoryService _history = HistoryService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _statusText;

  Future<void> _pickVideo() async {
    try {
      final XFile? selected = await _picker.pickVideo(source: ImageSource.gallery);
      if (!mounted) return;
      if (selected != null) {
        await _processExtractMp3(File(selected.path));
      }
    } catch (e) {
      showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.galleryAccessFailed);
    }
  }

  Future<void> _handleUrlExtract() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.pasteLinkFirst);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = '${StringHelper.downloading}...';
    });

    try {
      // 1. Request audio-only download from API
      final fileUrl = await _api.requestDownload(url: url, audioOnly: true);
      
      final dir = await getTemporaryDirectory();
      // We don't know the exact extension yet, but requestDownload usually returns mp3 or m4a for audioOnly
      final String tempExt = fileUrl.split('.').last.split('?').first;
      final savePath = '${dir.path}/extract_src_${DateTime.now().millisecondsSinceEpoch}.$tempExt';

      // 2. Download the audio file
      await _api.downloadFile(fileUrl: fileUrl, savePath: savePath);
      
      // 3. Ensure it's MP3 (if it's already mp3, we just move/save it, otherwise convert)
      await _processExtractMp3(File(savePath), isAudioOnlySource: true);
      
    } catch (e) {
      if (mounted) {
        showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.couldNotReadLink);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processExtractMp3(File inputFile, {bool isAudioOnlySource = false}) async {
    setState(() {
      _isLoading = true;
      _statusText = StringHelper.extractingAudio;
    });

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPath = '${tempDir.path}/extracted_$timestamp.mp3';

      String command;
      if (isAudioOnlySource && inputFile.path.toLowerCase().endsWith('.mp3')) {
        // Already MP3, just copy to ensure consistency
        command = '-y -i "${inputFile.path}" -c:a copy "$outputPath"';
      } else {
        // Extract or Convert to High Quality MP3
        command = '-y -i "${inputFile.path}" -q:a 0 -map a "$outputPath"';
      }

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          // Note: GallerySaver.saveVideo/saveImage might not support MP3 directly 
          // depending on platform. For MP3s, they usually go to Documents/Files.
          // But we'll try to let user share or view it.
          
          // Add to history
          await _history.addItem(HistoryItem(
            title: "Audio_${inputFile.path.split('/').last.split('.').first}.mp3",
            localPath: outputPath,
            savedAt: DateTime.now().millisecondsSinceEpoch,
            audioOnly: true,
            actionType: StringHelper.tagConvert,
          ));

          if (mounted) {
            setState(() => _isLoading = false);
            showNeuDialog(
              context: context,
              title: StringHelper.success,
              body: StringHelper.audioExtractedSuccess,
              onConfirm: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to tools
              },
            );
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.error);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showNeuDialog(context: context, title: StringHelper.error, body: e.toString());
      }
    }
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
            title: StringHelper.extractMp3Title,
            actions: const [],
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: _isLoading 
            ? _buildLoading(textColor) 
            : _buildPicker(textColor),
        );
      }
    );
  }

  Widget _buildLoading(Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: NeuColors.secondary),
          const SizedBox(height: 24),
          Text(_statusText ?? '${StringHelper.processing}...', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildPicker(Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(StringHelper.pickVideoToExtract, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
          Text(StringHelper.extractMp3Desc, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          NeuButton(
            onTap: _pickVideo, 
            color: const Color(0xFFE1F5FE), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.video_library_rounded, color: Colors.black),
                const SizedBox(width: 12),
                Text(StringHelper.uploadFromGallery, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
              ],
            ),
          ).animate().scale(delay: 100.ms),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: Divider(color: textColor, thickness: 2)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(StringHelper.or, style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
              ),
              Expanded(child: Divider(color: textColor, thickness: 2)),
            ],
          ),
          const SizedBox(height: 32),

          NeuTextField(
            controller: _urlController, 
            hintText: StringHelper.pasteUrlHint, 
            prefixIcon: Icons.link
          ).animate().scale(delay: 300.ms),
          const SizedBox(height: 16),
          
          NeuButton(
            onTap: _handleUrlExtract, 
            color: NeuColors.secondary, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_note_rounded, color: Colors.black),
                const SizedBox(width: 12),
                Text(StringHelper.loadFromUrl, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
              ],
            ),
          ).animate().scale(delay: 400.ms),
          
          const SizedBox(height: 40),
          NeuContainer(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.black54),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Note: This tool extracts the highest quality audio from your video and saves it as an MP3 file.",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}
