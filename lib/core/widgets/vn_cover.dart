import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../models/vn.dart';

/// VN cover art. Sensitive covers are blurred until the user taps them.
/// Covers are cached on the device after the first load.
class VnCover extends StatefulWidget {
  const VnCover({super.key, required this.vn, this.width = 64});

  final Vn vn;
  final double width;

  @override
  State<VnCover> createState() => _VnCoverState();
}

class _VnCoverState extends State<VnCover> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.width * 1.4; // typical VN cover ratio
    final scheme = Theme.of(context).colorScheme;
    final url = widget.vn.imageUrl;

    Widget placeholder([IconData icon = Icons.image_outlined]) => Container(
          color: scheme.surfaceContainerHighest,
          child: Icon(icon, color: scheme.outline),
        );

    final Widget image;
    if (url == null) {
      image = placeholder(Icons.image_not_supported_outlined);
    } else if (kIsWeb) {
      // Chrome blocks Flutter from reading VNDB's image bytes (CORS).
      // `prefer` makes Flutter show the cover as a plain browser <img> tag,
      // which isn't blocked. Web only — Android uses the cached branch below.
      image = Image.network(
        url,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, __, ___) => placeholder(Icons.broken_image_outlined),
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder(),
        errorWidget: (_, __, ___) => placeholder(Icons.broken_image_outlined),
      );
    }

    Widget cover = image;
    if (widget.vn.isCoverSensitive && !_revealed) {
      cover = GestureDetector(
        onTap: () => setState(() => _revealed = true),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // On web the <img> can't be blurred, so hide it fully instead.
            if (kIsWeb)
              placeholder(Icons.visibility_off)
            else ...[
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: image,
              ),
              Icon(Icons.visibility_off,
                  color: Colors.white.withValues(alpha: 0.9)),
            ],
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: widget.width, height: height, child: cover),
    );
  }
}
