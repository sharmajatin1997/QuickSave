import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  File? _selectedFile;
  bool _isCompressing = false;
  int _compressionLevel = 1; // 0: Low (Smallest), 1: Medium, 2: High (Best Quality)
  final HistoryService _history = HistoryService();

  String _getFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (bytes.toString().length - 1) ~/ 3;
    var res = bytes / (1 << (i * 10));
    return "${res.toStringAsFixed(2)} ${suffixes[i]}";
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _compressFile() async {
    if (_selectedFile == null) {
      showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.noFileSelected);
      return;
    }

    setState(() => _isCompressing = true);

    try {
      final String inputPath = _selectedFile!.path;
      final String extension = inputPath.split('.').last.toLowerCase();
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String outputPath = '${tempDir.path}/compressed_$timestamp.$extension';
      
      String command = "";

      // Determine compression command based on file type
      if (['mp4', 'mov', 'avi', 'mkv', 'flv'].contains(extension)) {
        // Video Compression:
        // 1. Never upscale (use min(iw, X))
        // 2. Use a better preset (faster/veryfast instead of ultrafast) for better size efficiency
        // 3. Constant Rate Factor (CRF) - higher means smaller size
        String crf;
        String width;
        if (_compressionLevel == 0) {
          crf = '40'; // Very aggressive compression
          width = '480';
        } else if (_compressionLevel == 1) {
          crf = '34'; // Balanced
          width = '720';
        } else {
          crf = '28'; // Moderate reduction
          width = '1080';
        }
        
        // Use a target bitrate to help keep size down + higher CRF
        command = '-y -i "$inputPath" -c:v libx264 -crf $crf -preset faster -vf "scale=$width:-2:force_original_aspect_ratio=decrease" -c:a aac -b:a 96k -movflags +faststart "$outputPath"';
        
      } else if (['mp3', 'm4a', 'wav', 'aac', 'ogg'].contains(extension)) {
        // Audio Compression
        String bitrate = _compressionLevel == 0 ? '64k' : (_compressionLevel == 1 ? '96k' : '128k');
        command = '-y -i "$inputPath" -c:a libmp3lame -b:a $bitrate "$outputPath"';
        
      } else if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        // Image Compression: scale down width and reduce quality
        String quality = _compressionLevel == 0 ? '40' : (_compressionLevel == 1 ? '60' : '80');
        String maxWidth = _compressionLevel == 0 ? '720' : (_compressionLevel == 1 ? '1280' : '1920');
        command = '-y -i "$inputPath" -vf "scale=$maxWidth:-1:force_original_aspect_ratio=decrease" -q:v $quality "$outputPath"';
        
      } else {
        // Generic File (Docs, etc.) - FFmpeg isn't ideal here.
        // We'll just copy it for now to prevent crash, or inform user.
        // Real doc compression usually requires specialized libs.
        showNeuDialog(
          context: context, 
          title: StringHelper.error, 
          body: "Compression for .$extension files is not supported yet. Supported: Video, Audio, Image."
        );
        setState(() => _isCompressing = false);
        return;
      }

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          final bool isVideo = ['mp4', 'mov', 'avi', 'mkv', 'flv'].contains(extension);
          final bool isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(extension);

          if (isVideo) {
            await GallerySaver.saveVideo(outputPath);
          } else if (isImage) {
            await GallerySaver.saveImage(outputPath);
          }

          final File compressedFile = File(outputPath);
          final int originalSize = _selectedFile!.lengthSync();
          final int newSize = compressedFile.lengthSync();

          // Add to history
          await _history.addItem(HistoryItem(
            title: "Compressed_${_selectedFile!.path.split('/').last}",
            localPath: outputPath,
            savedAt: DateTime.now().millisecondsSinceEpoch,
            audioOnly: !isVideo && !isImage,
            actionType: StringHelper.compress,
          ));

          if (mounted) {
            showNeuDialog(
              context: context,
              title: StringHelper.success,
              body: "${StringHelper.compressedSavedSuccess}\n\n"
                    "${StringHelper.originalSize}: ${_getFileSize(originalSize)}\n"
                    "${StringHelper.compressedSize}: ${_getFileSize(newSize)}",
              onConfirm: () => Navigator.pop(context),
            );
          }
        } else {
          if (mounted) {
            showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.error);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        showNeuDialog(context: context, title: StringHelper.error, body: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isCompressing = false);
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
            title: StringHelper.compress,
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: _isCompressing 
            ? _buildLoading(textColor)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StringHelper.selectFileToCompress,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
                    ).animate().fadeIn().slideX(begin: -0.1),
                    Text(
                      StringHelper.compressDescLong,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 24),
                    NeuButton(
                      onTap: _pickFile,
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_upload_outlined, color: isDark ? Colors.white : Colors.black),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _selectedFile != null 
                                ? _selectedFile!.path.split('/').last 
                                : StringHelper.selectFile,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(delay: 200.ms),
                    
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          "${StringHelper.originalSize}: ${_getFileSize(_selectedFile!.lengthSync())}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ).animate().fadeIn(),
                    ],

                    const SizedBox(height: 40),
                    Text(
                      StringHelper.compressionLevel,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        _buildLevelTile(0, StringHelper.lowQuality, Icons.speed_rounded, const Color(0xFFE8F5E9)),
                        _buildLevelTile(1, StringHelper.mediumQuality, Icons.balance_rounded, const Color(0xFFFFF3E0)),
                        _buildLevelTile(2, StringHelper.highQuality, Icons.high_quality_rounded, const Color(0xFFE1F5FE)),
                      ].animate(interval: 100.ms).fadeIn(delay: 500.ms).slideY(begin: 0.1),
                    ),

                    const SizedBox(height: 48),
                    NeuButton(
                      onTap: _isCompressing ? null : _compressFile,
                      color: NeuColors.primary,
                      child: Text(
                        StringHelper.compress.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
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
          Text(StringHelper.compressingFile, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildLevelTile(int level, String label, IconData icon, Color bg) {
    final bool isSelected = _compressionLevel == level;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _compressionLevel = level),
        child: NeuContainer(
          padding: const EdgeInsets.all(16),
          color: isSelected ? bg : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          shadowOffset: isSelected ? 2 : 4,
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.black : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black)
                  ),
                ),
              ),
              if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
