import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan lokal (di HP, via shared_preferences) untuk semua kredensial
/// dan pilihan user.
///
/// API key YouTube dan token Facebook HANYA tersimpan di HP user. Tidak ada
/// key/token yang di-embed di kode, tidak ada yang dikirim ke server lain.
class SettingsStorage {
  static const keyYouTubeApiKey = 'youtube_api_key';
  static const keyFacebookToken = 'facebook_token';
  static const keyRegion = 'region_code';
  static const keyYouTubeKeyStatus = 'youtube_key_status';

  /// Status key YouTube: 'belum' (belum diisi/dites), 'valid', 'tidak_valid'.
  static const statusBelum = 'belum';
  static const statusValid = 'valid';
  static const statusTidakValid = 'tidak_valid';

  final SharedPreferences _prefs;

  SettingsStorage(this._prefs);

  static Future<SettingsStorage> load() async {
    return SettingsStorage(await SharedPreferences.getInstance());
  }

  String get youTubeApiKey => _prefs.getString(keyYouTubeApiKey) ?? '';
  String get facebookToken => _prefs.getString(keyFacebookToken) ?? '';
  String get regionCode => _prefs.getString(keyRegion) ?? 'ID';
  String get youTubeKeyStatus =>
      _prefs.getString(keyYouTubeKeyStatus) ?? statusBelum;

  Future<void> setYouTubeApiKey(String value) =>
      _prefs.setString(keyYouTubeApiKey, value.trim());

  Future<void> setFacebookToken(String value) =>
      _prefs.setString(keyFacebookToken, value.trim());

  Future<void> setRegionCode(String value) =>
      _prefs.setString(keyRegion, value);

  Future<void> setYouTubeKeyStatus(String value) =>
      _prefs.setString(keyYouTubeKeyStatus, value);

  Future<void> clearAll() => _prefs.clear();
}
