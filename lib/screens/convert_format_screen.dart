import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
import '../services/history_service.dart';
import '../models/video_info.dart';

class ConvertFormatScreen extends StatefulWidget {
  const ConvertFormatScreen({super.key});

  @override
  State<ConvertFormatScreen> createState() => _ConvertFormatScreenState();
}

class _ConvertFormatScreenState extends State<ConvertFormatScreen> {
  bool _isAudioMode = true; // true for Audio, false for Video
  File? _selectedFile;
  String? _targetFormat;
  bool _isConverting = false;
  final ImagePicker _picker = ImagePicker();
  final HistoryService _history = HistoryService();

  final List<String> _audioFormats = ['MP3', 'M4A', 'WAV', 'AAC', 'OGG'];
  final List<String> _videoFormats = ['MP4', 'MOV', 'AVI', 'MKV', 'FLV'];

  Future<void> _pickFile() async {
    if (_isAudioMode) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFile = File(result.files.single.path!));
      }
    } else {
      final XFile? result = await _picker.pickVideo(source: ImageSource.gallery);
      if (result != null) {
        setState(() => _selectedFile = File(result.path));
      }
    }
  }

  Future<void> _convertFile() async {
    if (_selectedFile == null) {
      showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.noFileSelected);
      return;
    }
    if (_targetFormat == null) {
      showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.selectTargetFormat);
      return;
    }

    setState(() => _isConverting = true);

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPath = '${tempDir.path}/converted_$timestamp.${_targetFormat!.toLowerCase()}';

      final String command = '-i "${_selectedFile!.path}" "$outputPath"';

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          if (!_isAudioMode) {
            await GallerySaver.saveVideo(outputPath);
          }

          // Add to history
          await _history.addItem(HistoryItem(
            title: _selectedFile!.path.split('/').last,
            localPath: outputPath,
            savedAt: DateTime.now().millisecondsSinceEpoch,
            audioOnly: _isAudioMode,
            actionType: StringHelper.tagConvert,
          ));

          if (mounted) {
            showNeuDialog(
              context: context,
              title: StringHelper.success,
              body: StringHelper.conversionSuccess,
              onConfirm: (ctx) {
                Navigator.pop(ctx);
                context.push('/history');
              },
            );
          }
        } else {
          if (mounted) {
            showNeuDialog(
              context: context, title: StringHelper.error, body: StringHelper.conversionFailed);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        showNeuDialog(context: context, title: StringHelper.error, body: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
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
            title: StringHelper.convertFormatTitle,
            actions: const [],
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: _isConverting 
            ? _buildLoading(textColor) 
            : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StringHelper.chooseMediaType,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
                ).animate().fadeIn().slideX(begin: -0.1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeCard(
                        label: StringHelper.audio,
                        icon: Icons.audiotrack_rounded,
                        isSelected: _isAudioMode,
                        color: NeuColors.accent,
                        onTap: () => setState(() {
                          _isAudioMode = true;
                          _selectedFile = null;
                          _targetFormat = null;
                        }),
                      ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTypeCard(
                        label: StringHelper.video,
                        icon: Icons.videocam_rounded,
                        isSelected: !_isAudioMode,
                        color: NeuColors.primary,
                        onTap: () => setState(() {
                          _isAudioMode = false;
                          _selectedFile = null;
                          _targetFormat = null;
                        }),
                      ).animate().scale(curve: Curves.elasticOut, duration: 600.ms, delay: 100.ms),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  _isAudioMode ? StringHelper.pickAudioFile : StringHelper.pickVideoFile,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                NeuButton(
                  onTap: _isConverting ? null : _pickFile,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isAudioMode ? Icons.library_music_rounded : Icons.video_library_rounded, color: isDark ? Colors.white : Colors.black),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _selectedFile != null 
                            ? _selectedFile!.path.split('/').last 
                            : (_isAudioMode ? StringHelper.chooseAudio : StringHelper.chooseVideo),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.2, delay: 300.ms),
                const SizedBox(height: 32),
                Text(
                  StringHelper.selectTargetFormat,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: (_isAudioMode ? _audioFormats : _videoFormats).map((format) {
                    final isSelected = _targetFormat == format;
                    return GestureDetector(
                      onTap: () => setState(() => _targetFormat = format),
                      child: NeuContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        color: isSelected ? NeuColors.secondary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: 30,
                        shadowOffset: isSelected ? 2 : 4,
                        child: Text(
                          format,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.black : textColor,
                          ),
                        ),
                      ),
                    );
                  }).toList().animate(interval: 50.ms).fadeIn(delay: 500.ms).scale(),
                ),
                const SizedBox(height: 48),
                NeuButton(
                  onTap: _isConverting ? null : _convertFile,
                  color: NeuColors.header,
                  child: Text(
                    StringHelper.convertNow,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
              ],
            ),
          ),
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
          Text('${StringHelper.converting}...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildTypeCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: NeuContainer(
        padding: const EdgeInsets.symmetric(vertical: 20),
        color: isSelected ? color : null,
        shadowOffset: isSelected ? 2 : 6,
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.black),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
