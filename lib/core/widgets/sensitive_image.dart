import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// A network image (screenshot, character art) that is blurred when VNDB
/// marks it sensitive and "Blur sensitive covers" is on in Settings.
///
/// First tap on a blurred image reveals it; after that, taps go to [onTap].
class SensitiveImage extends ConsumerStatefulWidget {
  const SensitiveImage({
    super.key,
    required this.url,
    required this.sensitive,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  final String url;
  final bool sensitive;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  ConsumerState<SensitiveImage> createState() => _SensitiveImageState();
}

class _SensitiveImageState extends ConsumerState<SensitiveImage> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blurOn = ref.watch(settingsProvider.select((s) => s.blurSensitiveCovers));
    final hidden = blurOn && widget.sensitive && !_revealed;

    Widget placeholder(IconData icon) => Container(
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(icon, color: scheme.outline),
        );

    // Same web workaround as covers: let Chrome draw the image itself.
    final Widget image = kIsWeb
        ? Image.network(
            widget.url,
            fit: widget.fit,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (_, __, ___) => placeholder(Icons.broken_image_outlined),
          )
        : CachedNetworkImage(
            imageUrl: widget.url,
            fit: widget.fit,
            placeholder: (_, __) => placeholder(Icons.image_outlined),
            errorWidget: (_, __, ___) => placeholder(Icons.broken_image_outlined),
          );

    if (!hidden) {
      return GestureDetector(onTap: widget.onTap, child: image);
    }

    return GestureDetector(
      onTap: () => setState(() => _revealed = true),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A browser <img> can't be blurred, so on web hide it instead.
          if (kIsWeb)
            placeholder(Icons.visibility_off)
          else ...[
            ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: image,
              ),
            ),
            const Center(child: Icon(Icons.visibility_off, color: Colors.white)),
          ],
        ],
      ),
    );
  }
}
