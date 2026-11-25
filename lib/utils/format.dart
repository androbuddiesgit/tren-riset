// Format angka dan tanggal untuk tampilan (Bahasa Indonesia).
// Tidak memakai paket `intl` supaya dependensi tetap minimal.

/// 999 -> "999", 1500 -> "1,5 rb", 2500000 -> "2,5 jt", 1200000000 -> "1,2 M".
String formatCount(int n) {
  if (n >= 1000000000) return '${_trim(n / 1000000000)} M';
  if (n >= 1000000) return '${_trim(n / 1000000)} jt';
  if (n >= 1000) return '${_trim(n / 1000)} rb';
  return n.toString();
}

String _trim(double v) {
  if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1).replaceAll('.', ',');
}

/// "5 mnt lalu" / "3 jam lalu" / "2 hari lalu" / "12 Nov 2026".
String formatTanggal(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${d.day} ${bulan[d.month - 1]} ${d.year}';
}
