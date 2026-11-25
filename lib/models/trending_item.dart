/// Satu item trending: video YouTube atau postingan Facebook.
///
/// Model ini sengaja generik supaya daftar YouTube dan Facebook bisa
/// ditampilkan dengan kartu yang sama.
class TrendingItem {
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final DateTime publishedAt;
  final String url;
  final String platform; // 'youtube' atau 'facebook'

  const TrendingItem({
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.publishedAt,
    required this.url,
    required this.platform,
  });

  /// Parse satu item dari respons `videos.list` YouTube Data API v3.
  /// Dipakai untuk chart=mostPopular maupun untuk melengkapi hasil search.
  factory TrendingItem.fromYouTubeVideoJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final statistics = json['statistics'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};

    // `videos.list` mengembalikan id sebagai String, `search.list` sebagai
    // Map {kind, videoId}. Keduanya ditangani di sini.
    final rawId = json['id'];
    final String videoId;
    if (rawId is String) {
      videoId = rawId;
    } else if (rawId is Map<String, dynamic>) {
      videoId = rawId['videoId'] as String? ?? '';
    } else {
      videoId = '';
    }

    return TrendingItem(
      title: snippet['title'] as String? ?? '(tanpa judul)',
      channelName: snippet['channelTitle'] as String? ?? '(channel tidak diketahui)',
      thumbnailUrl: _pickThumbnail(thumbnails),
      viewCount: _parseCount(statistics['viewCount']),
      likeCount: _parseCount(statistics['likeCount']),
      commentCount: _parseCount(statistics['commentCount']),
      publishedAt:
          DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ??
          DateTime.now(),
      url: 'https://www.youtube.com/watch?v=$videoId',
      platform: 'youtube',
    );
  }

  /// Parse satu postingan dari respons `/{page-id}/feed` Graph API.
  /// `pageName` diisi oleh pemanggil karena feed tidak membawa nama Page.
  factory TrendingItem.fromFacebookPostJson(
    Map<String, dynamic> json, {
    required String pageName,
  }) {
    final likes = json['likes'] as Map<String, dynamic>?;
    final comments = json['comments'] as Map<String, dynamic>?;
    return TrendingItem(
      title: (json['message'] as String? ?? '(tanpa teks)').trim(),
      channelName: pageName,
      thumbnailUrl: '',
      viewCount: 0,
      likeCount: (likes?['summary'] as Map?)?['total_count'] as int? ?? 0,
      commentCount:
          (comments?['summary'] as Map?)?['total_count'] as int? ?? 0,
      publishedAt:
          DateTime.tryParse(json['created_time'] as String? ?? '') ??
          DateTime.now(),
      url: json['permalink_url'] as String? ?? '',
      platform: 'facebook',
    );
  }

  static String _pickThumbnail(Map<String, dynamic> thumbnails) {
    for (final key in ['medium', 'high', 'default']) {
      final thumb = thumbnails[key] as Map<String, dynamic>?;
      final url = thumb?['url'] as String?;
      if (url != null && url.isNotEmpty) return url;
    }
    return '';
  }

  static int _parseCount(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
