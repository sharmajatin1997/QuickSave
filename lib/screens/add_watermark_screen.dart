import 'dart:io';
import 'dart:ui' as ui;
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

class AddWatermarkScreen extends StatefulWidget {
  const AddWatermarkScreen({super.key});

  @override
  State<AddWatermarkScreen> createState() => _AddWatermarkScreenState();
}

class _AddWatermarkScreenState extends State<AddWatermarkScreen> {
  File? _selectedVideo;
  File? _watermarkImage;
  String _watermarkText = "";
  final TextEditingController _watermarkTextController = TextEditingController();
  bool _isTextWatermark = true;
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();
  final HistoryService _history = HistoryService();
  bool _isProcessing = false;
  bool _isMediaLoading = false;
  
  // Custom relative position (0.0 to 1.0)
  Offset _relativePos = const Offset(0.1, 0.1);
  double _watermarkScale = 0.30; 

  final GlobalKey _videoKey = GlobalKey();

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _isMediaLoading = true);
      try {
        if (_videoController != null) await _videoController!.dispose();
        _videoController = VideoPlayerController.file(File(video.path));
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.addListener(() => setState(() {}));
        setState(() {
          _selectedVideo = File(video.path);
          _relativePos = const Offset(0.1, 0.1); 
          _isMediaLoading = false;
        });
      } catch (e) {
        if (mounted) setState(() => _isMediaLoading = false);
      }
    }
  }

  Future<void> _pickWatermarkImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _watermarkImage = File(image.path);
      });
    }
  }

  Future<File> _saveTextAsImage(String text, double scale, double videoWidth) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Exact same formula as preview
    final double fontSize = videoWidth * scale * 0.2; 
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final double w = textPainter.width + 20;
    final double h = textPainter.height + 10;
    
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), Paint()..color = Colors.black.withValues(alpha: 0.4));
    textPainter.paint(canvas, const Offset(10, 5));
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/text_wm_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(buffer);
    return file;
  }

  Future<void> _handleAddWatermark() async {
    if (_selectedVideo == null) return;
    setState(() => _isProcessing = true);

    try {
      final double videoW = _videoController!.value.size.width;
      final double videoH = _videoController!.value.size.height;

      // Map relative coordinates to video pixels
      int x = (_relativePos.dx * videoW).toInt();
      int y = (_relativePos.dy * videoH).toInt();

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPath = '${tempDir.path}/watermarked_$timestamp.mp4';

      String command;
      if (_isTextWatermark) {
        final File textImgFile = await _saveTextAsImage(_watermarkText, _watermarkScale, videoW);
        command = '-y -i "${_selectedVideo!.path}" -i "${textImgFile.path}" -filter_complex "overlay=$x:$y" -c:v libx264 -preset ultrafast -crf 28 -c:a copy "$outputPath"';
      } else {
        command = '-y -i "${_selectedVideo!.path}" -i "${_watermarkImage!.path}" -filter_complex "[1:v][0:v]scale2ref=w=main_w*$_watermarkScale:h=ow/mdar[wm][vid];[vid][wm]overlay=$x:$y" -c:v libx264 -preset ultrafast -crf 28 -c:a copy "$outputPath"';
      }

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        await GallerySaver.saveVideo(outputPath);
        await _history.addItem(HistoryItem(
          title: "WM_${_selectedVideo!.path.split('/').last}",
          localPath: outputPath,
          savedAt: DateTime.now().millisecondsSinceEpoch,
          audioOnly: false,
          actionType: StringHelper.tagWatermarked,
        ));
        if (mounted) {
          setState(() => _isProcessing = false);
          showNeuDialog(context: context, title: StringHelper.success, body: StringHelper.videoSavedSuccess, onConfirm: () {
            Navigator.pop(context);
            Navigator.pop(context);
          });
        }
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.failedApplyWatermark);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        showNeuDialog(context: context, title: "Error", body: e.toString());
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _watermarkTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return ValueListenableBuilder<String>(
      valueListenable: LanguageNotifier.languageCode,
      builder: (context, lang, _) {
        return PopScope(
          canPop: !_isProcessing,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _isProcessing) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(StringHelper.processingWait)));
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F0F0),
            resizeToAvoidBottomInset: true,
            appBar: NeuAppBar(
              title: StringHelper.addWatermark,
              fontSize: 24,
              actions: const [],
              leading: buildCircleIcon(Icons.arrow_back, () => _isProcessing ? null : Navigator.pop(context)),
            ),
            body: SafeArea(
              child: _isMediaLoading 
                ? _buildMediaLoading(textColor)
                : _selectedVideo == null 
                  ? _buildPicker(textColor) 
                  : AbsorbPointer(
                      absorbing: _isProcessing,
                      child: _buildDesigner(textColor, isDark),
                    ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildMediaLoading(Color textColor) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: NeuColors.secondary), const SizedBox(height: 24), Text(StringHelper.loadingMedia, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor))]));
  }

  Widget _buildPicker(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NeuContainer(padding: EdgeInsets.all(32), color: Color(0xFFF3E5F5), borderRadius: 100, child: Icon(Icons.branding_watermark_rounded, size: 64, color: Colors.black)).animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 40),
            Text(StringHelper.addBranding, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
            Text(StringHelper.dragBrand, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            NeuButton(onTap: _pickVideo, color: NeuColors.accent, child: Text(StringHelper.chooseVideo.toUpperCase())),
          ],
        ),
      ),
    );
  }

  Widget _buildDesigner(Color textColor, bool isDark) {
    return Column(
      children: [
        // 1. PREVIEW (FLEXIBLE)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double ratio = _videoController!.value.aspectRatio;
              double vW = constraints.maxWidth;
              double vH = vW / ratio;
              if (vH > constraints.maxHeight) {
                vH = constraints.maxHeight;
                vW = vH * ratio;
              }
              final double wmW = vW * _watermarkScale;

              return Center(
                child: NeuContainer(
                  padding: EdgeInsets.zero,
                  color: Colors.black,
                  borderRadius: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: vW,
                      height: vH,
                      child: Stack(
                        key: _videoKey,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play()),
                            child: VideoPlayer(_videoController!),
                          ),
                          if (_isTextWatermark && _watermarkText.isNotEmpty || !_isTextWatermark && _watermarkImage != null)
                            Positioned(
                              left: _relativePos.dx * vW,
                              top: _relativePos.dy * vH,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                     double newX = (_relativePos.dx * vW + details.delta.dx).clamp(0.0, vW - wmW);
                                     double newY = (_relativePos.dy * vH + details.delta.dy).clamp(0.0, vH - 30);
                                     _relativePos = Offset(newX / vW, newY / vH);
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(border: Border.all(color: Colors.amber, width: 2), color: Colors.black26),
                                  child: _buildWatermarkPreview(wmW),
                                ),
                              ),
                            ),
                          if (!_videoController!.value.isPlaying)
                            const IgnorePointer(child: Center(child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 80))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ),

        // 2. CONTROLS (SCROLLABLE)
        SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                    _typeToggle("TEXT", Icons.text_fields, _isTextWatermark, () {
                      setState(() {
                        _isTextWatermark = true;
                        if (_watermarkScale < 0.30) _watermarkScale = 0.30;
                      });
                    }),
                    const SizedBox(width: 12),
                    _typeToggle("LOGO", Icons.image, !_isTextWatermark, () {
                      setState(() {
                        _isTextWatermark = false;
                        if (_watermarkScale < 0.30) _watermarkScale = 0.30;
                      });
                    }),
                ]),
                const SizedBox(height: 16),
                if (_isTextWatermark)
                   NeuTextField(
                     controller: _watermarkTextController, 
                     hintText: StringHelper.typeWatermark, 
                     onChanged: (v) => setState(() => _watermarkText = v),
                   )
                else
                  NeuButton(onTap: _pickWatermarkImage, height: 48, child: Text(_watermarkImage != null ? StringHelper.tagWatermarked : StringHelper.chooseMedia)),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(StringHelper.size, style: TextStyle(fontWeight: FontWeight.w900, color: textColor)), Text("${(_watermarkScale * 100).toInt()}%", style: const TextStyle(color: NeuColors.primary, fontWeight: FontWeight.bold))]),
                Slider(
                  value: _watermarkScale.clamp(0.30, 1.0), 
                  min: 0.30, 
                  max: 1.0, 
                  activeColor: NeuColors.accent, 
                  onChanged: (v) => setState(() => _watermarkScale = v),
                ),
                const SizedBox(height: 16),
                NeuButton(onTap: _isProcessing ? null : _handleAddWatermark, color: NeuColors.primary, child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : Text(StringHelper.generateVideo.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                const SizedBox(height: 8),
                Center(child: TextButton(onPressed: _pickVideo, child: Text(StringHelper.changeVideo, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWatermarkPreview(double width) {
    if (_isTextWatermark) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(_watermarkText.isEmpty ? "Brand" : _watermarkText, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: width * 0.2)),
      );
    } else if (_watermarkImage != null) {
      return Image.file(_watermarkImage!, width: width, fit: BoxFit.contain);
    }
    return const SizedBox.shrink();
  }

  Widget _typeToggle(String label, IconData icon, bool active, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap, child: NeuContainer(padding: const EdgeInsets.symmetric(vertical: 12), color: active ? NeuColors.secondary : null, child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 8), Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))]))));
  }
}
