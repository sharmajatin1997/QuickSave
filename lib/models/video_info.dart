class VideoFormat {
  final String formatId;
  final String ext;
  final String resolution;
  final bool hasVideo;
  final bool hasAudio;
  final int? filesize;

  VideoFormat({
    required this.formatId,
    required this.ext,
    required this.resolution,
    required this.hasVideo,
    required this.hasAudio,
    this.filesize,
  });

  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    return VideoFormat(
      formatId: json['format_id']?.toString() ?? '',
      ext: json['ext']?.toString() ?? '',
      resolution: json['resolution']?.toString() ?? 'audio',
      hasVideo: json['hasVideo'] ?? false,
      hasAudio: json['hasAudio'] ?? false,
      filesize: json['filesize'],
    );
  }

  String get sizeLabel {
    if (filesize == null) return '';
    final mb = filesize! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class VideoInfo {
  final String title;
  final String? thumbnail;
  final double? duration;
  final String extractor;
  final List<VideoFormat> formats;

  VideoInfo({
    required this.title,
    this.thumbnail,
    this.duration,
    required this.extractor,
    required this.formats,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      title: json['title']?.toString() ?? 'Untitled',
      thumbnail: json['thumbnail']?.toString(),
      duration: (json['duration'] as num?)?.toDouble(),
      extractor: json['extractor']?.toString() ?? '',
      formats: (json['formats'] as List<dynamic>? ?? [])
          .map((f) => VideoFormat.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HistoryItem {
  final String title;
  final String? thumbnail;
  final String localPath;
  final int savedAt;
  final bool audioOnly;
  final String? actionType; // New field: 'Download', 'Trim', 'Convert'

  HistoryItem({
    required this.title,
    this.thumbnail,
    required this.localPath,
    required this.savedAt,
    required this.audioOnly,
    this.actionType,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'thumbnail': thumbnail,
        'localPath': localPath,
        'savedAt': savedAt,
        'audioOnly': audioOnly,
        'actionType': actionType,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        title: json['title'],
        thumbnail: json['thumbnail'],
        localPath: json['localPath'],
        savedAt: json['savedAt'],
        audioOnly: json['audioOnly'] ?? false,
        actionType: json['actionType'],
      );
}
