import 'package:flutter/material.dart';

import '../../../core/widgets/sensitive_image.dart';
import '../../../models/vn.dart';

/// Horizontal strip of screenshot thumbnails. Tap one to view full screen.
class ScreenshotSection extends StatelessWidget {
  const ScreenshotSection({super.key, required this.screenshots});

  final List<VnScreenshot> screenshots;

  @override
  Widget build(BuildContext context) {
    if (screenshots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Screenshots (${screenshots.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: screenshots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = screenshots[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 112 * 16 / 9, // most VN screenshots are 16:9 or 4:3
                  child: SensitiveImage(
                    url: s.thumbnail,
                    sensitive: s.isSensitive,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => ScreenshotViewer(
                          screenshots: screenshots,
                          initialIndex: i,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Full-screen screenshots: swipe between them, pinch to zoom.
class ScreenshotViewer extends StatefulWidget {
  const ScreenshotViewer({
    super.key,
    required this.screenshots,
    required this.initialIndex,
  });

  final List<VnScreenshot> screenshots;
  final int initialIndex;

  @override
  State<ScreenshotViewer> createState() => _ScreenshotViewerState();
}

class _ScreenshotViewerState extends State<ScreenshotViewer> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.screenshots.length}'),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.screenshots.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final s = widget.screenshots[i];
          return InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: SensitiveImage(
                url: s.url, // full size here, thumbnail in the strip
                sensitive: s.isSensitive,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
