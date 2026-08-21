import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
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

class RemoveWatermarkScreen extends StatefulWidget {
  const RemoveWatermarkScreen({super.key});

  @override
  State<RemoveWatermarkScreen> createState() => _RemoveWatermarkScreenState();
}

class _RemoveWatermarkScreenState extends State<RemoveWatermarkScreen> {
  File? _selectedFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  bool _isDrawing = false;
  bool _isFinalized = false;
  final HistoryService _history = HistoryService();
  
  // Custom drawing points
  Offset? _startPoint;
  Offset? _endPoint;
  Rect? _selectionRect;

  double _imageAspectRatio = 1.0;

  Future<void> _pickMedia() async {
    final XFile? media = await _picker.pickMedia();
    if (media != null) {
      final file = File(media.path);
      final isVideo = media.path.toLowerCase().endsWith('.mp4') || 
                      media.path.toLowerCase().endsWith('.mov') ||
                      media.path.toLowerCase().endsWith('.avi') ||
                      media.path.toLowerCase().endsWith('.mkv');
      
      final isImage = media.path.toLowerCase().endsWith('.jpg') || 
                      media.path.toLowerCase().endsWith('.jpeg') || 
                      media.path.toLowerCase().endsWith('.png') ||
                      media.path.toLowerCase().endsWith('.webp');

      if (!isVideo && !isImage) {
        if (mounted) {
          showNeuDialog(
            context: context, 
            title: StringHelper.error, 
            body: StringHelper.unsupportedFileType,
          );
        }
        return;
      }
      
      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }

      if (isVideo) {
        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize();
        _videoController!.addListener(() {
          if (mounted) setState(() {});
        });
      } else {
        // Calculate image aspect ratio
        final data = await file.readAsBytes();
        final image = await decodeImageFromList(data);
        setState(() {
          _imageAspectRatio = image.width / image.height;
        });
      }

      setState(() {
        _selectedFile = file;
        _isVideo = isVideo;
        _selectionRect = null;
        _startPoint = null;
        _endPoint = null;
        _isFinalized = false;
      });
    }
  }

  Future<void> _handleRemoveWatermark() async {
    if (_selectedFile == null || _selectionRect == null) {
      showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.drawBoxFirst);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      double originalW;
      double originalH;

      if (_isVideo && _videoController != null) {
        originalW = _videoController!.value.size.width;
        originalH = _videoController!.value.size.height;
      } else {
        // For images, we can decode dimensions using decodeImageFromList or similar
        // but FFmpeg can also handle it. Let's get size from the file.
        final data = await _selectedFile!.readAsBytes();
        final image = await decodeImageFromList(data);
        originalW = image.width.toDouble();
        originalH = image.height.toDouble();
      }

      final RenderBox? renderBox = _mediaKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) throw Exception("UI not ready");

      final double screenW = renderBox.size.width;
      final double screenH = renderBox.size.height;

      // Map screen selection to pixels
      int x = ((_selectionRect!.left / screenW) * originalW).toInt();
      int y = ((_selectionRect!.top / screenH) * originalH).toInt();
      int w = ((_selectionRect!.width / screenW) * originalW).toInt();
      int h = ((_selectionRect!.height / screenH) * originalH).toInt();

      if (x < 0) x = 0;
      if (y < 0) y = 0;
      if (x + w > originalW) w = (originalW - x).toInt();
      if (y + h > originalH) h = (originalH - y).toInt();
      if (w <= 0) w = 1;
      if (h <= 0) h = 1;

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String ext = _isVideo ? 'mp4' : _selectedFile!.path.split('.').last;
      final String outputPath = '${tempDir.path}/clean_$timestamp.$ext';

      // FFmpeg command works for both images and videos
      String command;
      if (_isVideo) {
        command = '-y -i "${_selectedFile!.path}" -vf "delogo=x=$x:y=$y:w=$w:h=$h" -c:v libx264 -preset ultrafast -crf 28 -c:a copy "$outputPath"';
      } else {
        command = '-y -i "${_selectedFile!.path}" -vf "delogo=x=$x:y=$y:w=$w:h=$h" "$outputPath"';
      }

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          if (_isVideo) {
            await GallerySaver.saveVideo(outputPath);
          } else {
            await GallerySaver.saveImage(outputPath);
          }
          
          // ADD TO HISTORY
          await _history.addItem(HistoryItem(
            title: _selectedFile!.path.split('/').last,
            localPath: outputPath,
            savedAt: DateTime.now().millisecondsSinceEpoch,
            audioOnly: false,
            actionType: StringHelper.tagEraser,
          ));

          if (mounted) {
            setState(() => _isProcessing = false);
            showNeuDialog(
              context: context,
              title: StringHelper.success,
              body: StringHelper.erasedSavedSuccess,
              onConfirm: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            );
          }
        } else {
          if (mounted) {
            setState(() => _isProcessing = false);
            showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.processingFailed);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        showNeuDialog(context: context, title: StringHelper.error, body: e.toString());
      }
    }
  }

  final GlobalKey _mediaKey = GlobalKey();

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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
            title: StringHelper.magicEraser,
            fontSize: 24,
            actions: const [],
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: SafeArea(
            child: _selectedFile == null 
              ? _buildPicker(textColor, isDark) 
              : _buildDrawer(textColor, isDark),
          ),
        );
      }
    );
  }

  Widget _buildPicker(Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(32),
            color: NeuColors.accent,
            borderRadius: 100,
            child: const Icon(Icons.auto_fix_high_rounded, size: 64, color: Colors.black),
          ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
          const SizedBox(height: 40),
          Text(
            StringHelper.magicEraser,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor),
          ),
          const SizedBox(height: 12),
          Text(
            StringHelper.removeWatermarkDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 48),
          NeuButton(
            onTap: _pickMedia,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.perm_media_rounded, color: Colors.black),
                const SizedBox(width: 12),
                Text(StringHelper.chooseMedia.toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(Color textColor, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: NeuColors.secondary, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 2))),
                child: const Text("1", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectionRect == null ? StringHelper.drawToErase : StringHelper.success, 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: NeuContainer(
              padding: EdgeInsets.zero,
              color: Colors.black,
              borderRadius: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: AspectRatio(
                    key: _mediaKey,
                    aspectRatio: _isVideo ? _videoController!.value.aspectRatio : _imageAspectRatio,
                    child: Stack(
                      children: [
                        if (_isVideo)
                          VideoPlayer(_videoController!)
                        else
                          Image.file(_selectedFile!, fit: BoxFit.contain),
                        
                        // DRAWING LAYER
                        if (!_isFinalized)
                          GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _isDrawing = true;
                                _startPoint = details.localPosition;
                                _endPoint = details.localPosition;
                                _selectionRect = Rect.fromPoints(_startPoint!, _endPoint!);
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                _endPoint = details.localPosition;
                                _selectionRect = Rect.fromPoints(_startPoint!, _endPoint!);
                              });
                            },
                            onPanEnd: (details) {
                              setState(() {
                                _isDrawing = false;
                                _isFinalized = true;
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),

                        // DISPLAY AND DRAG THE DRAWN RECTANGLE
                        if (_selectionRect != null)
                          Positioned(
                            left: _selectionRect!.left,
                            top: _selectionRect!.top,
                            child: GestureDetector(
                              onPanUpdate: _isFinalized ? (details) {
                                setState(() {
                                  // Drag the box
                                  final double screenW = _mediaKey.currentContext!.size!.width;
                                  final double screenH = _mediaKey.currentContext!.size!.height;

                                  double newLeft = _selectionRect!.left + details.delta.dx;
                                  double newTop = _selectionRect!.top + details.delta.dy;

                                  // Clamp position
                                  newLeft = newLeft.clamp(0.0, screenW - _selectionRect!.width);
                                  newTop = newTop.clamp(0.0, screenH - _selectionRect!.height);

                                  _selectionRect = Rect.fromLTWH(
                                    newLeft,
                                    newTop,
                                    _selectionRect!.width,
                                    _selectionRect!.height,
                                  );
                                });
                              } : null,
                              child: Container(
                                width: _selectionRect!.width,
                                height: _selectionRect!.height,
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.4),
                                  border: Border.all(color: Colors.amber, width: 3),
                                ),
                                child: _isFinalized ? const Center(
                                  child: Icon(Icons.drag_indicator, color: Colors.white, size: 20),
                                ) : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              if (_isVideo && _videoController != null)
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                      },
                      icon: Icon(
                        _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 40,
                        color: textColor,
                      ),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        _videoController!, 
                        allowScrubbing: true, 
                        colors: const VideoProgressColors(playedColor: NeuColors.secondary),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              NeuButton(
                onTap: _isProcessing ? null : _handleRemoveWatermark,
                color: NeuColors.primary,
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(StringHelper.tagEraser.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectionRect = null;
                        _startPoint = null;
                        _endPoint = null;
                        _isFinalized = false;
                      });
                    }, 
                    child: Text(StringHelper.clearSelection, style: const TextStyle(color: NeuColors.primary, fontWeight: FontWeight.bold))
                  ),
                  TextButton(
                    onPressed: _pickMedia, 
                    child: Text(StringHelper.changeVideo, style: TextStyle(color: textColor, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
