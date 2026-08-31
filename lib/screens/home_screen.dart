import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../widgets/neubrutal.dart';
import '../utils/string_helper.dart';
import '../utils/language_notifier.dart';
import '../widgets/responsive_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> _handleContinue() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      _showAlert(StringHelper.error, StringHelper.pickSourceDesc);
      return;
    }

    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T').first;
      final count = prefs.getInt('yt_download_count_$today') ?? 0;
      if (count >= 2) {
        _showAlert('Daily Limit Reached', 'You can only download 2 YouTube videos per day.');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final info = await _api.fetchVideoInfo(url);
      if (!mounted) return;
      context.push('/format', extra: {'url': url, 'info': info});
    } catch (e) {
      _showAlert(StringHelper.couldNotReadLink, StringHelper.checkLinkRetry);
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
            title: StringHelper.appName,
            leading: !ResponsiveLayout.isTablet(context) 
                ? buildCircleIcon(Icons.settings, () => context.push('/settings')).animate().scale(delay: 100.ms)
                : null,
            actions: [
               buildCircleIcon(Icons.history, () => context.push('/history')).animate().scale(delay: 200.ms),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StringHelper.downloadTitle,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                     Text(
                      StringHelper.downloadSubtitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF666666)),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 24),

                    NeuTextField(
                      controller: _controller,
                      hintText: StringHelper.pasteUrlHint,
                      prefixIcon: Icons.link,
                    ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: NeuButton(
                            onTap: _pasteOrClear,
                            color: _controller.text.isEmpty ? NeuColors.secondary : const Color(0xFFFFEBEE),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _controller.text.isEmpty ? Icons.paste : Icons.clear_all_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _controller.text.isEmpty ? StringHelper.pasteLinkBtn : StringHelper.clearTextBtn,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: NeuButton(
                            onTap: _loading ? null : _handleContinue,
                            color: NeuColors.bg,
                            child: _loading
                                ? const CircularProgressIndicator(color: NeuColors.secondary)
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download, size: 20),
                                const SizedBox(width: 8),
                                Text(StringHelper.downloadBtn),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                    const SizedBox(height: 32),
                    Text(StringHelper.platforms, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor))
                        .animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildPlatformItem(StringHelper.instagram, Icons.camera_rounded, const Color(0xFFFF80AB), textColor, 0)),
                        Expanded(child: _buildPlatformItem(StringHelper.facebook, Icons.facebook_rounded, const Color(0xFF82B1FF), textColor, 100)),
                        Expanded(child: _buildPlatformItem(StringHelper.tiktok, Icons.music_note, const Color(0xFF5E5D5D), textColor, 200)),
                        Expanded(child: _buildPlatformItem(StringHelper.youtube, Icons.play_arrow_rounded, const Color(0xFFFF5252), textColor, 300)),
                        Expanded(child: _buildPlatformItem(StringHelper.other, Icons.grid_view_rounded, const Color(0xFFB2FF59), textColor, 400)),
                      ],
                    ),

                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(StringHelper.mediaTools, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                        GestureDetector(
                          onTap: () => context.push('/tools'),
                          child: Text(StringHelper.seeAll, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFDF7A0C))),
                        ),
                      ],
                    ).animate().fadeIn(delay: 900.ms),
                     Text(StringHelper.mediaToolsSubtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))
                        .animate().fadeIn(delay: 950.ms),
                    const SizedBox(height: 16),

                    Column(
                      children: [
                        _buildToolCard(StringHelper.removeWatermark, StringHelper.removeWatermarkDesc, Icons.auto_fix_high_rounded, const Color(0xFFE1F5FE), textColor, onTap: () => context.push('/remove-watermark')),
                        _buildToolCard(StringHelper.addWatermark, StringHelper.addWatermarkDesc, Icons.branding_watermark_rounded, const Color(0xFFF3E5F5), textColor, onTap: () => context.push('/add-watermark')),
                        _buildToolCard(StringHelper.trimVideo, StringHelper.trimVideoDesc, Icons.content_cut, const Color(0xFFE8F5E9), textColor, onTap: () => context.push('/trim')),
                        if (ResponsiveLayout.isTablet(context)) ...[
                          _buildToolCard(StringHelper.convertFormat, StringHelper.convertFormatDesc, Icons.swap_horiz, const Color(0xFFFFF3E0), textColor, onTap: () => context.push('/convert')),
                          _buildToolCard(StringHelper.compress, StringHelper.compressDesc, Icons.compress, const Color(0xFFF1F8E9), textColor, onTap: () => context.push('/compress')),
                        ],
                      ].animate(interval: 100.ms).fadeIn(delay: 1100.ms).slideX(begin: 0.1),
                    ),
                  ],
                ),
                            ),
              )],
          ),
        );
      }
    );
  }

  Widget _buildPlatformItem(String name, IconData icon, Color color, Color textColor, int delay) {
    return GestureDetector(
      onTap: () {
        context.push('/platform', extra: {
          'name': name,
          'icon': icon,
          'color': color,
        });
      },
      child: Column(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(12),
            color: color,
            borderRadius: 16,
            shadowOffset: 3,
            child: Icon(icon, color: Colors.black, size: 28),
          ).animate().scale(curve: Curves.elasticOut, duration: 600.ms, delay: (800 + delay).ms),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: textColor),
            ),
          ).animate().fadeIn(delay: (1000 + delay).ms),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, String subtitle, IconData icon, Color iconBg, Color textColor, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: NeuContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),maxLines: 1,overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textColor.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
