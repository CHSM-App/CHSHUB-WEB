import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Opens a profile photo full size, pinch-to-zoom, over a dimmed backdrop.
///
/// Shared by the profile screen and the editor: the editor has a freshly picked
/// [file] that is not on the server yet, the profile screen has a stored [url].
/// Exactly one of the two is given.
Future<void> showPhotoViewer(
  BuildContext context,
  String? url, {
  File? file,
}) {
  if (url == null && file == null) return Future.value();

  return showDialog<void>(
    context: context,
    // The photo is the whole dialog, so the usual white sheet behind it would
    // only show as a border around the image.
    barrierColor: Colors.black87,
    builder: (dialogContext) => _PhotoViewer(url: url, file: file),
  );
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url, required this.file});

  final String? url;
  final File? file;

  @override
  Widget build(BuildContext context) {
    final local = file;

    final image = local != null
        ? Image.file(local, fit: BoxFit.contain)
        : Image.network(
            url!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const _Unavailable(),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: AppTheme.white),
                  ),
          );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppTheme.space4),
      child: Stack(
        children: [
          // Tapping anywhere off the photo closes it, the way a lightbox does.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              // A transparent child still has to be hit-testable.
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: image,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, color: AppTheme.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: AppTheme.white, size: 40),
          SizedBox(height: AppTheme.space3),
          Text(
            'That photo could not be loaded.',
            style: TextStyle(color: AppTheme.white),
          ),
        ],
      ),
    );
  }
}
