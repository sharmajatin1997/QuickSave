import 'package:dio/dio.dart';
import '../models/video_info.dart';

class ApiService {
  // 👉 Change this to your backend's address.
  // - Android emulator -> http://10.0.2.2:4000
  // - iOS simulator    -> http://localhost:4000
  // - Physical phone   -> http://<your-computer-local-ip>:4000
  // - Production       -> https://your-deployed-backend.com
  // static const String baseUrl = 'http://10.0.2.2:4000'; // For Android Emulator
  // static const String baseUrl = 'http://192.168.20.172:4000'; // For Physical Phone
  static const String baseUrl = 'http://localhost:4000'; // For iOS Simulator

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

  String fileUrlToAbsolute(String fileUrl) => '$baseUrl$fileUrl';

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
