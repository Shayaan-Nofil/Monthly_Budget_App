import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/haptics.dart';

/// Full-screen receipt viewer: pinch-zoom image; tap outside image to dismiss.
class ReceiptViewer {
  ReceiptViewer._();

  static Future<void> showNetwork(BuildContext context, String url) {
    return _show(
      context,
      CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, _) => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        errorWidget: (_, _, _) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white70,
          size: 48,
        ),
      ),
    );
  }

  static Future<void> showFile(BuildContext context, String path) {
    return _show(
      context,
      Image.file(File(path), fit: BoxFit.contain),
    );
  }

  static Future<void> _show(BuildContext context, Widget image) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close receipt',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ReceiptViewerPage(image: image);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _ReceiptViewerPage extends StatelessWidget {
  const _ReceiptViewerPage({required this.image});

  final Widget image;

  void _close(BuildContext context) {
    AppHaptics.light();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            // Tap dimmed area (outside image) to close.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _close(context),
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: GestureDetector(
                // Absorb taps on the image so they don't dismiss.
                onTap: () {},
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                    ),
                    child: image,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => _close(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
