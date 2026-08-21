import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class RemoveAudioScreen extends StatefulWidget {
  const RemoveAudioScreen({super.key});

  @override
  State<RemoveAudioScreen> createState() => _RemoveAudioScreenState();
}

class _RemoveAudioScreenState extends State<RemoveAudioScreen> {
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
        await _processRemoveAudio(File(selected.path));
      }
    } catch (e) {
      showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.galleryAccessFailed);
    }
  }

  Future<void> _handleUrlMute() async {
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
      await _api.fetchVideoInfo(url);
      final fileUrl = await _api.requestDownload(url: url, formatId: '18'); // Default basic MP4
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/mute_src_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _api.downloadFile(fileUrl: fileUrl, savePath: savePath);
      await _processRemoveAudio(File(savePath));
    } catch (e) {
      if (mounted) {
        showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.couldNotReadLink);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processRemoveAudio(File inputFile) async {
    setState(() {
      _isLoading = true;
      _statusText = StringHelper.removingAudio;
    });

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPath = '${tempDir.path}/muted_$timestamp.mp4';

      // Command: -an removes audio stream, -c:v copy copies video without re-encoding
      final String command = '-y -i "${inputFile.path}" -an -c:v copy "$outputPath"';

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          await GallerySaver.saveVideo(outputPath);
          
          // Add to history
          await _history.addItem(HistoryItem(
            title: "Muted_${inputFile.path.split('/').last}",
            localPath: outputPath,
            savedAt: DateTime.now().millisecondsSinceEpoch,
            audioOnly: false,
            actionType: StringHelper.tagEraser, // Or a new tag if needed
          ));

          if (mounted) {
            setState(() => _isLoading = false);
            showNeuDialog(
              context: context,
              title: StringHelper.success,
              body: StringHelper.audioRemovedSuccess,
              onConfirm: () {
                Navigator.pop(context);
                context.push('/history');
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
            title: StringHelper.muteVideoTitle,
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
          Text(StringHelper.chooseSource, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
          Text(StringHelper.pickSourceDesc, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          NeuButton(
            onTap: _pickVideo, 
            color: const Color(0xFFFFEBEE), 
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
            onTap: _handleUrlMute, 
            color: NeuColors.accent, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_off_rounded, color: Colors.black),
                const SizedBox(width: 12),
                Text(StringHelper.loadFromUrl, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
              ],
            ),
          ).animate().scale(delay: 400.ms),
          
          const SizedBox(height: 40),
          NeuContainer(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFF3E0),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.black54),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    StringHelper.muteVideoDesc,
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
