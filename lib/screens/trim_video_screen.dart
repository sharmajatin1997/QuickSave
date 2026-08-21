import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:go_router/go_router.dart';
import '../utils/string_helper.dart';
import '../utils/language_notifier.dart';
import '../widgets/neubrutal.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../models/video_info.dart';

class TrimVideoScreen extends StatefulWidget {
  const TrimVideoScreen({super.key});

  @override
  State<TrimVideoScreen> createState() => _TrimVideoScreenState();
}

class _TrimVideoScreenState extends State<TrimVideoScreen> {
  final VideoTrimmer _nativeTrimmer = VideoTrimmer();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final ApiService _api = ApiService();
  final HistoryService _history = HistoryService();
  final ImagePicker _picker = ImagePicker();

  File? _currentFile;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  bool _isTrimming = false;
  bool _isCustomTimer = false;
  String? _statusText;

  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  
  List<Uint8List> _thumbnails = [];

  @override
  void dispose() {
    _urlController.dispose();
    _startController.dispose();
    _endController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDuration(double ms) {
    if (ms < 0) ms = 0;
    Duration duration = Duration(milliseconds: ms.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  double _parseDuration(String text) {
    try {
      final parts = text.split(':');
      if (parts.length == 2) {
        final m = int.parse(parts[0]);
        final s = int.parse(parts[1]);
        return (m * 60 + s) * 1000.0;
      }
    } catch (_) {}
    return 0.0;
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? selected = await _picker.pickVideo(source: ImageSource.gallery);
      if (!mounted) return;
      if (selected != null) {
        await _loadVideo(File(selected.path));
      }
    } catch (e) {
      showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.galleryAccessFailed);
    }
  }

  Future<void> _loadVideo(File file) async {
    setState(() {
      _isLoading = true;
      _currentFile = file;
      _statusText = StringHelper.generatingPreview;
      _thumbnails = [];
    });

    try {
      if (_videoController != null) await _videoController!.dispose();
      
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      await _nativeTrimmer.loadVideo(file.path);

      final durationMs = _videoController!.value.duration.inMilliseconds;
      for (int i = 0; i < 10; i++) {
        final timeMs = (durationMs / 10 * i).toInt();
        final thumb = await VideoThumbnail.thumbnailData(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 150,
          quality: 20,
          timeMs: timeMs,
        );
        _thumbnails.add(thumb);
      }
      
      setState(() {
        _startValue = 0.0;
        _endValue = _videoController!.value.duration.inMilliseconds.toDouble();
        _startController.text = _formatDuration(_startValue);
        _endController.text = _formatDuration(_endValue);
        _isLoading = false;
        _statusText = null;
      });
    } catch (e) {
      if (mounted) {
        showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.failedToLoadVideo);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUrlTrim() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusText = '${StringHelper.downloading}...';
    });

    try {
      await _api.fetchVideoInfo(url);
      final fileUrl = await _api.requestDownload(url: url, formatId: '18');
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/trim_src_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _api.downloadFile(fileUrl: fileUrl, savePath: savePath);
      await _loadVideo(File(savePath));
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVideo() async {
    if (_currentFile == null) return;
    setState(() => _isTrimming = true);
    try {
      final String? outputPath = await _nativeTrimmer.trimVideo(
        startTimeMs: _startValue.toInt(),
        endTimeMs: _endValue.toInt(),
      );

      if (outputPath != null) {
        await GallerySaver.saveVideo(outputPath);
        
        // Add to history
        await _history.addItem(HistoryItem(
          title: _currentFile!.path.split('/').last,
          localPath: outputPath,
          savedAt: DateTime.now().millisecondsSinceEpoch,
          audioOnly: false,
          actionType: StringHelper.tagTrim,
        ));

        if (mounted) {
          showNeuDialog(
            context: context,
            title: StringHelper.success,
            body: StringHelper.trimmedSavedSuccess,
            onConfirm: () {
              Navigator.pop(context);
              context.go('/');
            },
          );
        }
      }
    } catch (e) {
      if (mounted) showNeuDialog(context: context, title: StringHelper.error, body: StringHelper.trimmingFailed);
    } finally {
      if (mounted) setState(() => _isTrimming = false);
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
            title: StringHelper.trimVideo,
            actions: const [],
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: _isLoading
              ? _buildLoading()
              : _currentFile == null
                  ? _buildPicker(textColor)
                  : _buildTrimmer(textColor, isDark),
        );
      }
    );
  }

  Widget _buildLoading() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: NeuColors.secondary),
          const SizedBox(height: 24),
          Text(_statusText ?? '${StringHelper.processing}...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
        ],
      ),
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
          NeuButton(onTap: _pickVideo, color: const Color(0xFFE1F5FE), child: Text(StringHelper.uploadFromGallery, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black))),
          const SizedBox(height: 32),
          Row(children: [Expanded(child: Divider(color: textColor, thickness: 2)), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(StringHelper.or, style: TextStyle(fontWeight: FontWeight.w900, color: textColor))), Expanded(child: Divider(color: textColor, thickness: 2))]),
          const SizedBox(height: 32),
          NeuTextField(controller: _urlController, hintText: StringHelper.pasteUrlHint, prefixIcon: Icons.link),
          const SizedBox(height: 16),
          NeuButton(onTap: _handleUrlTrim, color: NeuColors.secondary, child:  Text(StringHelper.loadFromUrl, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black))),
        ],
      ),
    );
  }

  Widget _buildTrimmer(Color textColor, bool isDark) {
    final double maxDuration = _videoController?.value.duration.inMilliseconds.toDouble() ?? 1.0;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: NeuContainer(
              padding: const EdgeInsets.all(4),
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_videoController != null) AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)),
                  Center(
                    child: IconButton(
                      icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 64, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _isPlaying ? _videoController?.pause() : _videoController?.play();
                          _isPlaying = !_isPlaying;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCustomTimer = !_isCustomTimer;
                      if (!_isCustomTimer) {
                        _startController.text = _formatDuration(_startValue);
                        _endController.text = _formatDuration(_endValue);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _isCustomTimer ? StringHelper.slider : StringHelper.customTimer,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDF7A0C), decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ),

              if (!_isCustomTimer)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Column(
                      children: [
                        NeuContainer(
                          padding: EdgeInsets.zero,
                          color: isDark ? const Color(0xFF333333) : Colors.white,
                          borderRadius: 12,
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 70,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Row(
                                    children: _thumbnails.map((t) => Expanded(child: Image.memory(t, fit: BoxFit.cover))).toList(),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 70,
                                    rangeThumbShape: CustomNeuRangeThumbShape(),
                                    rangeTrackShape: NoPaddingRangeSliderTrackShape(),
                                    activeTrackColor: Colors.transparent,
                                    inactiveTrackColor: Colors.black.withValues(alpha: 0.5),
                                    overlayColor: Colors.transparent,
                                  ),
                                  child: RangeSlider(
                                    values: RangeValues(_startValue, _endValue),
                                    min: 0.0,
                                    max: maxDuration,
                                    onChanged: (values) {
                                      setState(() {
                                        _startValue = values.start;
                                        _endValue = values.end;
                                        _startController.text = _formatDuration(_startValue);
                                        _endController.text = _formatDuration(_endValue);
                                      });
                                      _videoController?.seekTo(Duration(milliseconds: values.start.toInt()));
                                    },
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: Container(
                                  height: 70,
                                  margin: EdgeInsets.only(
                                    left: (_startValue / maxDuration) * width,
                                    right: width - ((_endValue / maxDuration) * width),
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.amber, width: 4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_startValue), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)),
                            Text(_formatDuration(_endValue), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)),
                          ],
                        ),
                      ],
                    );
                  },
                )
              else
                NeuContainer(
                  padding: const EdgeInsets.all(20),
                  color: isDark ? const Color(0xFF333333) : Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(StringHelper.startTimeLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                            const SizedBox(height: 8),
                            NeuTextField(
                              controller: _startController,
                              hintText: "00:00",
                              prefixIcon: Icons.timer_outlined,
                              onChanged: (val) {
                                double ms = _parseDuration(val);
                                if (ms <= _endValue) {
                                  setState(() {
                                    _startValue = ms;
                                  });
                                  _videoController?.seekTo(Duration(milliseconds: ms.toInt()));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(StringHelper.endTimeLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                            const SizedBox(height: 8),
                            NeuTextField(
                              controller: _endController,
                              hintText: "00:00",
                              prefixIcon: Icons.timer_off_outlined,
                              onChanged: (val) {
                                double ms = _parseDuration(val);
                                if (ms >= _startValue && ms <= maxDuration) {
                                  setState(() {
                                    _endValue = ms;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(24),
          child: NeuButton(
            onTap: _isTrimming ? null : _saveVideo,
            color: NeuColors.primary,
            child: _isTrimming ? const CircularProgressIndicator(color: Colors.white) : Text(StringHelper.saveTrimmedVideo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class NoPaddingRangeSliderTrackShape extends RangeSliderTrackShape {
  @override
  Rect getPreferredRect({required RenderBox parentBox, Offset offset = Offset.zero, required SliderThemeData sliderTheme, bool isEnabled = false, bool isDiscrete = false}) {
    return Rect.fromLTWH(offset.dx, offset.dy, parentBox.size.width, sliderTheme.trackHeight!);
  }
  @override
  void paint(PaintingContext context, Offset offset, {required RenderBox parentBox, required SliderThemeData sliderTheme, required Animation<double> enableAnimation, required Offset startThumbCenter, required Offset endThumbCenter, bool isEnabled = false, bool isDiscrete = false, required TextDirection textDirection}) {}
}

class CustomNeuRangeThumbShape extends RangeSliderThumbShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(12, 70);
  @override
  void paint(PaintingContext context, Offset center, {required Animation<double> activationAnimation, required Animation<double> enableAnimation, bool isDiscrete = false, bool isEnabled = false, bool? isOnTop, required SliderThemeData sliderTheme, TextDirection textDirection = TextDirection.ltr, Thumb thumb = Thumb.start, bool isPressed = false}) {
    final Canvas canvas = context.canvas;
    final paint = Paint()..color = Colors.amber..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3;
    final rect = Rect.fromCenter(center: center, width: 12, height: 70);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(4)), Paint()..color = Colors.black);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);
  }
}
