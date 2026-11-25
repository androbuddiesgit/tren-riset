import 'package:flutter/material.dart';

import '../models/trending_item.dart';
import '../services/facebook_service.dart';
import '../services/settings_storage.dart';
import '../services/youtube_service.dart';
import '../widgets/trending_card.dart';
import 'settings_screen.dart';

/// Niche siap pakai. "Semua" memakai chart mostPopular (1 unit kuota),
/// niche lain memakai search.list (100 unit kuota) — jadi search hanya jalan
/// saat user memang memilih niche / kata kunci.
const List<String> niches = [
  'Semua',
  'Persib',
  'Motivasi',
  'Fakta Unik',
  'Sepak Bola',
  'Motocross Vintage',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _keywordController = TextEditingController();

  SettingsStorage? _storage;
  String _apiKey = '';
  String _region = 'ID';
  String _fbToken = '';

  String _selectedNiche = 'Semua';
  Future<List<TrendingItem>>? _youtubeFuture;

  Future<List<FacebookPage>>? _pagesFuture;
  FacebookPage? _selectedPage;
  Future<List<TrendingItem>>? _feedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final storage = await SettingsStorage.load();
    if (!mounted) return;
    setState(() {
      _storage = storage;
      _apiKey = storage.youTubeApiKey;
      _region = storage.regionCode;
      _fbToken = storage.facebookToken;
    });
    if (_apiKey.isNotEmpty) _loadYouTube();
    if (_fbToken.isNotEmpty) _loadFacebookPages();
  }

  void _loadYouTube() {
    final keyword = _keywordController.text.trim();
    final service = YouTubeService();
    setState(() {
      if (keyword.isNotEmpty) {
        _youtubeFuture = service.searchByNiche(
          apiKey: _apiKey,
          niche: keyword,
          regionCode: _region,
        );
      } else if (_selectedNiche == 'Semua') {
        _youtubeFuture = service.fetchMostPopular(
          apiKey: _apiKey,
          regionCode: _region,
        );
      } else {
        _youtubeFuture = service.searchByNiche(
          apiKey: _apiKey,
          niche: _selectedNiche,
          regionCode: _region,
        );
      }
    });
  }

  void _loadFacebookPages() {
    setState(() {
      _pagesFuture = FacebookService().fetchAccounts(_fbToken);
      _selectedPage = null;
      _feedFuture = null;
    });
  }

  void _loadFeed(FacebookPage page) {
    setState(() {
      _selectedPage = page;
      _feedFuture = FacebookService()
          .fetchPageFeed(pageId: page.id, pageToken: page.accessToken)
          .then((posts) {
            final items = posts
                .map(
                  (p) => TrendingItem.fromFacebookPostJson(
                    p,
                    pageName: page.name,
                  ),
                )
                .toList();
            // Urutkan dari engagement (like + komentar) terbanyak.
            items.sort(
              (a, b) => (b.likeCount + b.commentCount).compareTo(
                a.likeCount + a.commentCount,
              ),
            );
            return items;
          });
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    if (!mounted) return;
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tren Riset'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'YouTube'),
            Tab(text: 'Facebook'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: () {
              if (_tabController.index == 0) {
                if (_apiKey.isNotEmpty) _loadYouTube();
              } else {
                if (_fbToken.isNotEmpty) _loadFacebookPages();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_youtubeTab(), _facebookTab()],
      ),
    );
  }

  // ------------------------------ YouTube ------------------------------

  Widget _youtubeTab() {
    if (_storage == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_apiKey.isEmpty) {
      return _infoCard(
        title: 'API key YouTube belum diisi',
        body:
            'Aplikasi ini memakai YouTube Data API v3 untuk mengambil daftar '
            'video trending. Isi API key di Pengaturan dulu — key tersimpan '
            'hanya di HP ini.',
        buttonLabel: 'Buka Pengaturan',
        onButton: _openSettings,
      );
    }
    return Column(
      children: [
        _nicheFilter(),
        Expanded(
          child: FutureBuilder<List<TrendingItem>>(
            future: _youtubeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _errorView(snapshot.error.toString());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Text('Tidak ada video ditemukan.'),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  _loadYouTube();
                  await _youtubeFuture;
                },
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => TrendingCard(item: items[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _nicheFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: niches.map((niche) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(niche),
                    selected: _selectedNiche == niche,
                    onSelected: (_) {
                      setState(() {
                        _selectedNiche = niche;
                        _keywordController.clear();
                      });
                      _loadYouTube();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keywordController,
                  decoration: const InputDecoration(
                    hintText: 'Kata kunci sendiri...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    setState(() => _selectedNiche = '');
                    _loadYouTube();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  setState(() => _selectedNiche = '');
                  _loadYouTube();
                },
                child: const Text('Cari'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------- Facebook ------------------------------

  Widget _facebookTab() {
    if (_storage == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fbToken.isEmpty) {
      return _infoCard(
        title: 'Tab Facebook masih terbatas',
        body:
            'Facebook tidak menyediakan API trending publik, jadi aplikasi '
            'ini tidak bisa menampilkan "yang lagi trending di Facebook" '
            'seperti di YouTube.\n\nYang bisa dibaca (dengan token akses '
            'Facebook): postingan terbaru dari Page yang kamu kelola, '
            'diurutkan dari engagement (like + komentar). Isi token di '
            'Pengaturan untuk mengaktifkan tab ini.',
        buttonLabel: 'Buka Pengaturan',
        onButton: _openSettings,
      );
    }
    return FutureBuilder<List<FacebookPage>>(
      future: _pagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }
        final pages = snapshot.data ?? [];
        if (pages.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Tidak ada Page yang dikelola akun pemilik token ini.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: DropdownButtonFormField<FacebookPage>(
                initialValue: _selectedPage,
                decoration: const InputDecoration(
                  labelText: 'Pilih Page',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: pages
                    .map(
                      (p) =>
                          DropdownMenuItem(value: p, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: (page) {
                  if (page != null) _loadFeed(page);
                },
              ),
            ),
            Expanded(
              child: _feedFuture == null
                  ? const Center(
                      child: Text('Pilih Page untuk melihat postingannya.'),
                    )
                  : FutureBuilder<List<TrendingItem>>(
                      future: _feedFuture,
                      builder: (context, feedSnapshot) {
                        if (feedSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (feedSnapshot.hasError) {
                          return _errorView(feedSnapshot.error.toString());
                        }
                        final items = feedSnapshot.data ?? [];
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('Belum ada postingan.'),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: () async {
                            if (_selectedPage != null) {
                              _loadFeed(_selectedPage!);
                              await _feedFuture;
                            }
                          },
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, i) =>
                                TrendingCard(item: items[i]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------ Bersama ------------------------------

  Widget _infoCard({
    required String title,
    required String body,
    required String buttonLabel,
    required VoidCallback onButton,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.indigo),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onButton, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_tabController.index == 0) {
                  _loadYouTube();
                } else {
                  _loadFacebookPages();
                }
              },
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
