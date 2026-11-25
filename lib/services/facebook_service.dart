import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Error dari Graph API Facebook yang sudah diterjemahkan ke Bahasa
/// Indonesia. Pesan error ditampilkan apa adanya di aplikasi — tidak pernah
/// diganti dengan data palsu.
class FacebookApiException implements Exception {
  final String message;
  final int? statusCode;

  FacebookApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Satu Page Facebook yang dikelola akun pemilik token.
class FacebookPage {
  final String id;
  final String name;
  final String accessToken;

  const FacebookPage({
    required this.id,
    required this.name,
    required this.accessToken,
  });

  factory FacebookPage.fromJson(Map<String, dynamic> json) {
    return FacebookPage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      accessToken: json['access_token'] as String? ?? '',
    );
  }
}

/// Akses baca ke Graph API Facebook (v18.0).
///
/// JUJUR SOAL BATASAN: Facebook TIDAK punya endpoint trending publik.
/// Yang bisa dibaca dengan token user adalah Page yang dikelola akun itu
/// (`/me/accounts`) dan feed tiap Page. Jadi tab Facebook di aplikasi ini
/// menampilkan postingan terbaru dari Page yang diikuti/dikelola, diurutkan
/// dari engagement — BUKAN daftar "trending Facebook" global, karena data
/// seperti itu tidak disediakan Meta.
class FacebookService {
  static const _host = 'graph.facebook.com';

  final http.Client _client;

  FacebookService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /me/accounts — daftar Page yang dikelola akun pemilik token.
  Future<List<FacebookPage>> fetchAccounts(String token) async {
    final uri = Uri.https(_host, '/v18.0/me/accounts', {
      'access_token': token,
      'limit': '50',
    });
    final res = await _get(uri);
    if (res.statusCode != 200) throw _explainError(res);
    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'] as List? ?? [];
    return data
        .map((e) => FacebookPage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /{page-id}/feed — postingan terbaru sebuah Page (max 25).
  /// Token yang dipakai adalah page access token dari /me/accounts.
  Future<List<Map<String, dynamic>>> fetchPageFeed({
    required String pageId,
    required String pageToken,
  }) async {
    final uri = Uri.https(_host, '/v18.0/$pageId/feed', {
      'fields':
          'message,created_time,permalink_url,likes.summary(true),comments.summary(true)',
      'limit': '25',
      'access_token': pageToken,
    });
    final res = await _get(uri);
    if (res.statusCode != 200) throw _explainError(res);
    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri);
    } on SocketException {
      throw FacebookApiException(
        'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.',
      );
    } on http.ClientException {
      throw FacebookApiException(
        'Tidak bisa menghubungi Graph API Facebook. Periksa jaringan lalu coba lagi.',
      );
    }
  }

  FacebookApiException _explainError(http.Response res) {
    String detail = '';
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      final msg = error?['message'] as String?;
      final code = error?['code'];
      if (msg != null) detail = ' (kode $code: $msg)';
    } catch (_) {
      // Badan error bukan JSON — abaikan, pakai pesan standar di bawah.
    }
    return FacebookApiException(
      'Graph API mengembalikan error ${res.statusCode}$detail',
      res.statusCode,
    );
  }
}
