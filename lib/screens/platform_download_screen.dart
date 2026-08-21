import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../widgets/neubrutal.dart';
import '../utils/string_helper.dart';
import '../utils/language_notifier.dart';

class PlatformDownloadScreen extends StatefulWidget {
  final String platformName;
  final IconData platformIcon;
  final Color platformColor;

  const PlatformDownloadScreen({
    super.key,
    required this.platformName,
    required this.platformIcon,
    required this.platformColor,
  });

  @override
  State<PlatformDownloadScreen> createState() => _PlatformDownloadScreenState();
}

class _PlatformDownloadScreenState extends State<PlatformDownloadScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _api = ApiService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteOrClear() async {
    if (_controller.text.isNotEmpty) {
      _controller.clear();
      return;
    }
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() => _controller.text = data!.text!);
    }
  }

  bool _isUrlValid(String url) {
    if (widget.platformName == 'Other') return true;

    final lowerUrl = url.toLowerCase();
    if (widget.platformName == 'Instagram' &&
        (lowerUrl.contains('instagram.com') ||
            lowerUrl.contains('instagr.am'))) {
      return true;
    }
    if (widget.platformName == 'Facebook' &&
        (lowerUrl.contains('facebook.com') || lowerUrl.contains('fb.watch') ||
            lowerUrl.contains('fb.com'))) {
      return true;
    }
    if (widget.platformName == 'YouTube' &&
        (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be'))) {
      return true;
    }
    if (widget.platformName == 'TikTok' && (lowerUrl.contains('tiktok.com') ||
        lowerUrl.contains('vmtiktok.com'))) {
      return true;
    }
    return false;
  }

  Future<void> _handleContinue() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      _showAlert(StringHelper.pasteLinkFirst,
          '${StringHelper.copyVideoLinkFrom} ${widget.platformName}.');
      return;
    }

    if (!_isUrlValid(url)) {
      _showAlert(
          StringHelper.invalidLink, '${StringHelper.pleasePasteAValid} ${widget.platformName} ${StringHelper.link}.');
      return;
    }

    setState(() => _loading = true);
    try {
      final info = await _api.fetchVideoInfo(url);
      if (!mounted) return;
      context.push('/format', extra: {'url': url, 'info': info});
    } catch (e) {
      _showAlert(
          StringHelper.couldNotReadLink, StringHelper.checkLinkRetry);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAlert(String title, String message) {
    showNeuDialog(
      context: context,
      title: title,
      body: message,
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
            title: widget.platformName,
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                NeuContainer(
                  padding: const EdgeInsets.all(24),
                  color: widget.platformColor,
                  borderRadius: 30,
                  shadowOffset: 6,
                  child: Icon(widget.platformIcon, color: Colors.black, size: 64),
                ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                const SizedBox(height: 32),
                Text(
                  '${widget.platformName} ${StringHelper.downloaderBtn}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                Text(
                  '${StringHelper.downloadSubtitle.split(' ').first} ${StringHelper.your} ${widget.platformName} ${StringHelper.linkBelowToStart}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 32),
                NeuTextField(
                  controller: _controller,
                  hintText: '${StringHelper.paste} ${widget.platformName} ${StringHelper.linkHere}',
                  prefixIcon: Icons.link,
                ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: NeuButton(
                        onTap: _pasteOrClear,
                        color: _controller.text.isEmpty ? NeuColors.secondary : const Color(0xFFFFEBEE),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _controller.text.isEmpty ? Icons.paste : Icons.clear_all_rounded,
                              size: 20, color: Colors.black
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _controller.text.isEmpty ? StringHelper.pasteLinkBtn : StringHelper.clearTextBtn,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: NeuButton(
                        onTap: _loading ? null : _handleContinue,
                        color: NeuColors.accent,
                        child: _loading
                            ? const CircularProgressIndicator(color: NeuColors.secondary)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.download, size: 20, color: Colors.black),
                                  const SizedBox(width: 8),
                                  Text(StringHelper.downloadBtn, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        );
      }
    );
  }
}
