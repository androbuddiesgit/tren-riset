import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/trending_item.dart';
import '../utils/format.dart';

/// Satu kartu item trending (video YouTube / postingan Facebook).
///
/// Ketuk kartu untuk melihat detail + link asli. v1 ini belum memakai
/// url_launcher (dependensi minimal), jadi link dibuka lewat tombol
/// "Salin link" — user paste link itu ke browser sendiri.
class TrendingCard extends StatelessWidget {
  final TrendingItem item;

  const TrendingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumbnail(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.channelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        if (item.platform == 'youtube')
                          _stat(Icons.visibility, formatCount(item.viewCount)),
                        _stat(Icons.thumb_up, formatCount(item.likeCount)),
                        _stat(
                          Icons.comment,
                          formatCount(item.commentCount),
                        ),
                        _stat(Icons.schedule, formatTanggal(item.publishedAt)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    if (item.thumbnailUrl.isEmpty) {
      return Container(
        width: 112,
        height: 64,
        color: Colors.grey[300],
        child: const Icon(Icons.article, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        item.thumbnailUrl,
        width: 112,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 112,
          height: 64,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item.channelName} • ${formatTanggal(item.publishedAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 12),
              SelectableText(
                item.url,
                style: const TextStyle(fontSize: 13, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.url));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link disalin.')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Salin link'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }
}
