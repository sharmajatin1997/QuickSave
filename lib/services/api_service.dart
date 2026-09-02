import 'package:dio/dio.dart';
import '../models/video_info.dart';

class ApiService {
  static const String baseUrl = 'https://quicksave-backend-wq7x.onrender.com';
  // static const String baseUrl = 'http://localhost:4000'; // For iOS Simulator

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(minutes: 10),
    ),
  );

  Future<VideoInfo> fetchVideoInfo(String url) async {
    final res = await _dio.post('/api/info', data: {'url': url});
    return VideoInfo.fromJson(res.data as Map<String, dynamic>);
  }

  /// Returns the relative file URL (e.g. "/files/abc123.mp4") to download.
  Future<String> requestDownload({
    required String url,
    String? formatId,
    bool audioOnly = false,
  }) async {
    final res = await _dio.post('/api/download', data: {
      'url': url,
      'format_id': formatId,
      'audioOnly': audioOnly,
    });
    return res.data['fileUrl'] as String;
  }

  String fileUrlToAbsolute(String fileUrl) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    return '$baseUrl$fileUrl';
  }

  /// Downloads the file to [savePath] with progress updates.
  Future<void> downloadFile({
    required String fileUrl,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) async {
    await _dio.download(
      fileUrlToAbsolute(fileUrl),
      savePath,
      onReceiveProgress: onProgress,
    );
  }
}
