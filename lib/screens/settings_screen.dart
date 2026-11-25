import 'package:flutter/material.dart';

import '../services/settings_storage.dart';
import '../services/youtube_service.dart';

/// Pengaturan: API key YouTube, token Facebook (opsional), region.
/// Semua nilai tersimpan lokal di HP (shared_preferences) — tidak ada yang
/// dikirim ke server mana pun selain API resmi saat dipakai.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyController = TextEditingController();
  final _tokenController = TextEditingController();
  final _youTubeService = YouTubeService();

  SettingsStorage? _storage;
  String _region = 'ID';
  String _keyStatus = SettingsStorage.statusBelum;
  bool _testing = false;
  bool _obscureKey = true;
  bool _obscureToken = true;

  static const _regions = {
    'ID': 'Indonesia',
    'MY': 'Malaysia',
    'SG': 'Singapura',
    'US': 'Amerika Serikat',
    'GB': 'Inggris',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final storage = await SettingsStorage.load();
    if (!mounted) return;
    setState(() {
      _storage = storage;
      _keyController.text = storage.youTubeApiKey;
      _tokenController.text = storage.facebookToken;
      _region = storage.regionCode;
      _keyStatus = storage.youTubeKeyStatus;
    });
  }

  String _statusLabel() {
    return switch (_keyStatus) {
      SettingsStorage.statusValid => 'Valid',
      SettingsStorage.statusTidakValid => 'Tidak valid',
      _ => 'Belum diisi / belum dites',
    };
  }

  Color _statusColor() {
    return switch (_keyStatus) {
      SettingsStorage.statusValid => Colors.green,
      SettingsStorage.statusTidakValid => Colors.red,
      _ => Colors.grey,
    };
  }

  Future<void> _save() async {
    final storage = _storage;
    if (storage == null) return;
    await storage.setYouTubeApiKey(_keyController.text);
    await storage.setFacebookToken(_tokenController.text);
    await storage.setRegionCode(_region);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan.')));
    Navigator.of(context).pop(true);
  }

  Future<void> _testKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi API key YouTube dulu.')),
      );
      return;
    }
    setState(() => _testing = true);
    try {
      await _youTubeService.validateKey(key);
      await _storage?.setYouTubeKeyStatus(SettingsStorage.statusValid);
      if (!mounted) return;
      setState(() => _keyStatus = SettingsStorage.statusValid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key valid. Siap dipakai.')),
      );
    } on YouTubeApiException catch (e) {
      await _storage?.setYouTubeKeyStatus(SettingsStorage.statusTidakValid);
      if (!mounted) return;
      setState(() => _keyStatus = SettingsStorage.statusTidakValid);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus data tersimpan?'),
        content: const Text(
          'API key YouTube, token Facebook, dan region akan dihapus dari HP ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _storage?.clearAll();
    if (!mounted) return;
    setState(() {
      _keyController.clear();
      _tokenController.clear();
      _region = 'ID';
      _keyStatus = SettingsStorage.statusBelum;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data tersimpan sudah dihapus.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: _storage == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'YouTube Data API v3',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'API key didapat dari Google Cloud Console (project "Tren Riset"). '
                  'Key hanya tersimpan di HP ini.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    labelText: 'API key YouTube',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Status key: '),
                    Text(
                      _statusLabel(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusColor(),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _testing ? null : _testKey,
                      child: _testing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Tes koneksi'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'Facebook (opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Token akses user Facebook. Dipakai untuk membaca Page yang '
                  'kamu kelola (/me/accounts) dan feed-nya. Tanpa token, tab '
                  'Facebook hanya menampilkan penjelasan batasan.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  decoration: InputDecoration(
                    labelText: 'Token akses Facebook',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureToken = !_obscureToken),
                    ),
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'Region trending YouTube',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _region,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _regions.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text('${e.value} (${e.key})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _region = value);
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Simpan'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _clearAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Hapus data tersimpan'),
                ),
              ],
            ),
    );
  }
}
