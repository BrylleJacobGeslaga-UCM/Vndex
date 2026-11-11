import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom of the VN page: open this VN's discussion board or page on VNDB.
/// VNDB doesn't share forums through its API, so these open in the browser.
class VndbLinksCard extends StatelessWidget {
  const VndbLinksCard({super.key, required this.vnId});

  final String vnId; // "v17"

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.forum_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Join the discussion', style: text.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Talk about this VN with other readers on VNDB.',
              style: text.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Discussions'),
                  onPressed: () => _open(context, 'https://vndb.org/t/$vnId'),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View on VNDB'),
                  onPressed: () => _open(context, 'https://vndb.org/$vnId'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
