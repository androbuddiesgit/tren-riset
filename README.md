# Tren Riset

Aplikasi Flutter untuk riset konten trending — **YouTube + Facebook** — untuk
lini YouTube dan profil/page Facebook. Bahasa UI: Bahasa Indonesia. APK
didistribusikan sideload (bukan Play Store).

## Fitur v1

- **Beranda, tab YouTube | Facebook.**
  - YouTube: daftar video trending (`chart=mostPopular`, region Indonesia
    default) atau pencarian per niche, 7 hari terakhir, diurutkan dari views
    terbanyak.
  - Filter niche (chip): Semua, Persib, Motivasi, Fakta Unik, Sepak Bola,
    Motocross Vintage — plus kolom kata kunci sendiri.
  - Setiap item: judul, channel/page, views, likes, komentar, tanggal terbit,
    thumbnail. Ketuk item untuk melihat link asli (tombol "Salin link").
- **Pengaturan:** kolom API key YouTube (tombol "Tes koneksi", status key:
  belum diisi / valid / tidak valid), kolom token Facebook (opsional), pilihan
  region, tombol hapus data tersimpan. Semua tersimpan lokal di HP
  (shared_preferences).
- **Facebook (v1 TERBATAS, jujur):** Facebook tidak menyediakan API trending
  publik. Tanpa token, tab Facebook menampilkan penjelasan batasan ini. Dengan
  token akses user, aplikasi membaca Page yang dikelola akun itu
  (`/me/accounts`) dan feed tiap Page, diurutkan dari engagement. Tidak ada
  daftar trending Facebook palsu/mock di aplikasi ini.

## Cara isi API key YouTube

Key TIDAK di-embed di aplikasi dan tidak ada di repo ini. Isi di Pengaturan
aplikasi saat pertama dipakai:

1. Buka Google Cloud Console di browser HP (`console.cloud.google.com`),
   login akun pemilik project.
2. Pilih project **"Tren Riset"** → APIs & Services → Credentials.
3. Salin **"API key 1"** (key sudah dibatasi hanya untuk YouTube Data API v3).
4. Di aplikasi: Pengaturan → tempel key di kolom "API key YouTube" → Simpan
   → "Tes koneksi" sampai status jadi **Valid**.

Tanpa key yang valid, tab YouTube menampilkan pesan error yang jelas (key
salah / kuota habis / tidak ada internet) — bukan data palsu.

## Kuota YouTube Data API v3 (gratis, 10.000 unit/hari)

- `videos.list` mostPopular: **1 unit** per panggilan.
- `search.list` (dipakai saat memilih niche / kata kunci): **100 unit** per
  panggilan, plus 1 unit untuk melengkapi statistik. Karena itu pencarian
  niche hanya jalan saat user memilih niche — bukan otomatis.

## Cara build APK (GitHub Actions)

APK **tidak** dibangun di VM (RAM VM ~600 MB bebas, tidak cukup untuk Gradle).
Build jalan di GitHub Actions:

1. Push kode ke branch `main` repo ini, atau jalankan manual dari tab
   Actions → "Build APK" → Run workflow.
2. Workflow: checkout → Java 17 (Temurin) → Flutter 3.50.1 stable →
   `flutter pub get` → `flutter analyze` → `flutter build apk --release`.
3. Unduh APK dari artifact **`tren-riset-apk`** (`app-release.apk`), install
   di HP (sideload).

File workflow: `.github/workflows/build-apk.yml`.

## Validasi lokal (tanpa build APK)

```sh
flutter pub get
flutter analyze   # harus 0 error
flutter test      # unit test logika API (respons mock, hanya untuk test)
```

## Batasan v1

- Facebook: hanya Page yang dikelola akun pemilik token, bukan trending
  global (tidak disediakan Meta). Token Facebook diisi manual di Pengaturan.
- Membuka link: v1 memakai tombol "Salin link" (tanpa dependensi
  `url_launcher` — dependensi sengaja minimal: `http` + `shared_preferences`).
- Thumbnail dimuat dari internet; butuh koneksi saat membuka daftar.

## Struktur proyek

```
lib/
  main.dart                  # entry point
  models/trending_item.dart  # model item trending (YouTube + Facebook)
  services/
    youtube_service.dart     # YouTube Data API v3 (mostPopular, search, validasi key)
    facebook_service.dart    # Graph API v18.0 (/me/accounts, /{page}/feed)
    settings_storage.dart    # shared_preferences: key, token, region
  screens/
    home_screen.dart         # tab YouTube | Facebook + filter niche
    settings_screen.dart     # pengaturan + tes koneksi + hapus data
  widgets/trending_card.dart # kartu item trending
test/
  youtube_service_test.dart  # unit test (mock HTTP, hanya untuk test)
.github/workflows/build-apk.yml
```
