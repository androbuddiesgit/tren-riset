import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/trending_item.dart';

/// Error dari YouTube Data API v3 yang sudah diterjemahkan ke Bahasa
/// Indonesia yang jelas untuk user. Aplikasi TIDAK PERNAH menampilkan data
/// palsu: kalau panggilan ini gagal, user melihat pesan error, bukan daftar
/// trending karangan.
class YouTubeApiException implements Exception {
  final String message;
  final int? statusCode;

  YouTubeApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class YouTubeService {
  static const _host = 'www.googleapis.com';

  final http.Client _client;

  YouTubeService({http.Client? client}) : _client = client ?? http.Client();

  /// Validasi API key dengan satu panggilan kecil (1 unit kuota):
  /// `videos.list` chart=mostPopular, 1 hasil. Dipakai tombol "Tes koneksi".
  Future<void> validateKey(String apiKey) async {
    final uri = Uri.https(_host, '/youtube/v3/videos', {
      'part': 'snippet',
      'chart': 'mostPopular',
      'regionCode': 'ID',
      'maxResults': '1',
      'key': apiKey,
    });
    final res = await _get(uri);
    if (res.statusCode == 200) return;
    throw _explainError(res);
  }

  /// Video trending (chart=mostPopular). Biaya: 1 unit kuota per panggilan.
  Future<List<TrendingItem>> fetchMostPopular({
    required String apiKey,
    String regionCode = 'ID',
  }) async {
    final uri = Uri.https(_host, '/youtube/v3/videos', {
      'part': 'snippet,statistics',
      'chart': 'mostPopular',
      'regionCode': regionCode,
      'maxResults': '25',
      'key': apiKey,
    });
    final res = await _get(uri);
    if (res.statusCode != 200) throw _explainError(res);
    final items = (jsonDecode(res.body) as Map<String, dynamic>)['items'] as List? ?? [];
    return items
        .map((e) => TrendingItem.fromYouTubeVideoJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Pencarian per niche, video 7 hari terakhir diurutkan dari views terbanyak.
  ///
  /// PERHATIAN KUOTA: `search.list` menghabiskan 100 unit per panggilan
  /// (bandingkan mostPopular yang cuma 1 unit). Karena itu method ini HANYA
  /// dipanggil saat user memilih niche / kata kunci sendiri, bukan otomatis.
  /// Hasil search tidak membawa statistik, jadi id video diambil dulu lalu
  /// dilengkapi lewat `videos.list` (1 unit untuk max 50 id).
  Future<List<TrendingItem>> searchByNiche({
    required String apiKey,
    required String niche,
    String regionCode = 'ID',
  }) async {
    final publishedAfter = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    final uri = Uri.https(_host, '/youtube/v3/search', {
      'part': 'snippet',
      'q': niche,
      'type': 'video',
      'order': 'viewCount',
      'publishedAfter': publishedAfter,
      'regionCode': regionCode,
      'maxResults': '25',
      'key': apiKey,
    });
    final res = await _get(uri);
    if (res.statusCode != 200) throw _explainError(res);
    final items = (jsonDecode(res.body) as Map<String, dynamic>)['items'] as List? ?? [];
    final ids = items
        .map((e) => (e as Map<String, dynamic>)['id']?['videoId'] as String?)
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return [];
    return fetchVideosByIds(apiKey: apiKey, videoIds: ids);
  }

  /// Lengkapi daftar id video menjadi item lengkap (snippet + statistik).
  /// Biaya: 1 unit kuota untuk max 50 id.
  Future<List<TrendingItem>> fetchVideosByIds({
    required String apiKey,
    required List<String> videoIds,
  }) async {
    final uri = Uri.https(_host, '/youtube/v3/videos', {
      'part': 'snippet,statistics',
      'id': videoIds.join(','),
      'maxResults': '50',
      'key': apiKey,
    });
    final res = await _get(uri);
    if (res.statusCode != 200) throw _explainError(res);
    final items = (jsonDecode(res.body) as Map<String, dynamic>)['items'] as List? ?? [];
    return items
        .map((e) => TrendingItem.fromYouTubeVideoJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri);
    } on SocketException {
      throw YouTubeApiException(
        'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.',
      );
    } on http.ClientException {
      throw YouTubeApiException(
        'Tidak bisa menghubungi YouTube. Periksa jaringan lalu coba lagi.',
      );
    }
  }

  YouTubeApiException _explainError(http.Response res) {
    String detail = '';
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      detail = (error?['message'] as String?) ?? '';
    } catch (_) {
      // Badan error bukan JSON — abaikan, pakai pesan standar di bawah.
    }
    switch (res.statusCode) {
      case 400:
        return YouTubeApiException(
          'API key tidak valid atau permintaan ditolak YouTube (400). '
          'Periksa key di Pengaturan.'
          '${detail.isNotEmpty ? ' Detail: $detail' : ''}',
          400,
        );
      case 403:
        return YouTubeApiException(
          'Akses ditolak (403). Kemungkinan kuota harian YouTube Data API '
          'habis, atau key belum diaktifkan untuk YouTube Data API v3.'
          '${detail.isNotEmpty ? ' Detail: $detail' : ''}',
          403,
        );
      default:
        return YouTubeApiException(
          'YouTube mengembalikan error ${res.statusCode}.'
          '${detail.isNotEmpty ? ' $detail' : ''}',
          res.statusCode,
        );
    }
  }
}
