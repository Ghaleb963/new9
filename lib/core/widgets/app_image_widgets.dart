import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_theme.dart';

// ════════════════════════════════════════════════════════
// Image Widgets — مكوّنات الصور المُعاد تصميمها
// ════════════════════════════════════════════════════════

// ── بلاطة صورة مع زر حذف ────────────────────────────────────────────────────
class AppImageTile extends StatelessWidget {
  final Widget image;
  final VoidCallback onRemove;

  const AppImageTile({
    super.key,
    required this.image,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: SizedBox(width: 80, height: 80, child: image),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppTheme.accentRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── placeholder للصور الغائبة ────────────────────────────────────────────────
class AppImagePlaceholder extends StatelessWidget {
  final double height;
  const AppImagePlaceholder({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppTheme.bgRaised,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 48,
          color: AppTheme.textLow,
        ),
      ),
    );
  }
}

// ── صورة من ملف محلي مع fallback ────────────────────────────────────────────
class AppNetworkImage extends StatelessWidget {
  final String         filePath;
  final double?        height;
  final double?        width;
  final BoxFit         fit;
  final int?           cacheWidth;
  final FilterQuality  filterQuality;

  const AppNetworkImage({
    super.key,
    required this.filePath,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.filterQuality = FilterQuality.low,
  });

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(filePath),
      height: height,
      width:  width,
      fit:    fit,
      cacheWidth:      cacheWidth,
      filterQuality:   filterQuality,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width:  width,
        color:  AppTheme.bgRaised,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 48,
            color: AppTheme.textLow,
          ),
        ),
      ),
    );
  }
}
