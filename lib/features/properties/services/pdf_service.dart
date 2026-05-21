import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import 'package:arabic_reshaper/arabic_reshaper.dart';
import '../models/property_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../settings/providers/settings_provider.dart';

// ════════════════════════════════════════════════════════
// Image processing configuration for weak devices
// ════════════════════════════════════════════════════════
class _PdfImageConfig {
  final int maxWidth;
  final int jpegQuality;
  final int maxImagesInPdf;

  const _PdfImageConfig({
    required this.maxWidth,
    required this.jpegQuality,
    required this.maxImagesInPdf,
  });
}

// Aggressive optimization for weak devices
const _kWeakDeviceConfig = _PdfImageConfig(
  maxWidth: 400,
  jpegQuality: 45,
  maxImagesInPdf: 4,
);

// Balanced config for normal devices
const _kNormalConfig = _PdfImageConfig(
  maxWidth: 600,
  jpegQuality: 60,
  maxImagesInPdf: 8,
);

// ════════════════════════════════════════════════════════
// Singleton queue for sequential PDF generation
// Prevents CPU overload when multiple PDFs are requested
// ════════════════════════════════════════════════════════
class _PdfGenerationQueue {
  static final _PdfGenerationQueue _instance = _PdfGenerationQueue._();
  factory _PdfGenerationQueue() => _instance;
  _PdfGenerationQueue._();

  final Queue<_PdfTask> _queue = Queue();
  bool _isProcessing = false;

  Future<Uint8List?> enqueue(_PdfTask task) {
    final completer = Completer<Uint8List?>();
    task.completer = completer;
    _queue.add(task);
    _processNext();
    return completer.future;
  }

  void _processNext() {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    final task = _queue.removeFirst();

    task.execute().then((result) {
      task.completer.complete(result);
    }).catchError((error) {
      task.completer.complete(null);
    }).whenComplete(() {
      _isProcessing = false;
      _processNext();
    });
  }

  int get pendingCount => _queue.length;

  void clear() {
    for (final task in _queue) {
      task.completer.complete(null);
    }
    _queue.clear();
  }
}

class _PdfTask {
  final PropertyModel property;
  final SettingsState settings;
  late Completer<Uint8List?> completer;

  _PdfTask({required this.property, required this.settings});

  Future<Uint8List?> execute() async {
    return await PdfService.generatePropertyPdf(
      property: property,
      settings: settings,
    );
  }
}

// ════════════════════════════════════════════════════════
// Adaptive device capability detection
// ════════════════════════════════════════════════════════
class _DeviceCapability {
  static bool? _isWeakDevice;

  static bool get isWeak {
    if (_isWeakDevice != null) return _isWeakDevice!;

    // Detect weak devices by checking platform and available info
    if (Platform.isAndroid) {
      // Android devices are more likely to be weak
      _isWeakDevice = true;
    } else if (Platform.isIOS) {
      _isWeakDevice = false;
    } else {
      // Desktop: assume capable
      _isWeakDevice = false;
    }

    return _isWeakDevice!;
  }

  static _PdfImageConfig get config =>
      isWeak ? _kWeakDeviceConfig : _kNormalConfig;
}

// ════════════════════════════════════════════════════════
// Image processing — runs on isolate
// ════════════════════════════════════════════════════════
Uint8List? _processImageBytes(Uint8List rawBytes) {
  try {
    final image = img.decodeImage(rawBytes);
    if (image == null) return null;

    final config = _DeviceCapability.config;

    img.Image resized = image;
    if (image.width > config.maxWidth) {
      resized = img.copyResize(image, width: config.maxWidth);
    }

    return Uint8List.fromList(
      img.encodeJpg(resized, quality: config.jpegQuality),
    );
  } catch (_) {
    return null;
  }
}

String _ar(String text) {
  try {
    return ArabicReshaper.instance.reshape(text);
  } catch (_) {
    return text;
  }
}

pw.Widget _row(String title, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          _ar(title),
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          _ar(value),
          style: const pw.TextStyle(color: PdfColors.black),
        ),
      ],
    ),
  );
}

pw.Widget _buildPdfContent(
  List<pw.Widget> imageWidgets,
  PropertyModel property,
  String officeName,
  String officePhone,
  bool isOffer,
  pw.Font arabicBoldFont,
  PdfColor entryPdfColor,
  PdfColor dividerColor,
) {
  return pw.Directionality(
    textDirection: pw.TextDirection.rtl,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              _ar(isOffer ? 'تقرير العقار الاحترافي' : 'تقرير طلب عقار'),
              style: pw.TextStyle(
                font: arabicBoldFont,
                fontSize: 22,
                color: entryPdfColor,
              ),
            ),
            pw.Text(
              _ar(
                'تاريخ التصدير: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              ),
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Divider(color: dividerColor, thickness: 2),
        pw.SizedBox(height: 10),
        if (officeName.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border(
                right: pw.BorderSide(color: dividerColor, width: 4),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _ar(officeName),
                  style: pw.TextStyle(
                    font: arabicBoldFont,
                    fontSize: 16,
                  ),
                ),
                if (officePhone.isNotEmpty)
                  pw.Text(
                    _ar('هاتف: $officePhone'),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text(
          _ar(
            isOffer ? 'تفاصيل ومواصفات العقار' : 'تفاصيل طلب الزبون',
          ),
          style: pw.TextStyle(font: arabicBoldFont, fontSize: 18),
        ),
        pw.SizedBox(height: 10),
        _row('نوع السجل', property.entryType.label),
        _row('نوع العقار', property.propertyType),
        _row(
          isOffer ? 'نوع الإعلان' : 'نوع المطلوب',
          property.adType,
        ),
        _row('المحافظة', property.province),
        if (property.region.isNotEmpty) _row('المنطقة', property.region),
        if (property.area > 0) _row('المساحة', '${property.area} م²'),
        if (property.rooms > 0) _row('عدد الغرف', '${property.rooms}'),
        if (property.price > 0)
          _row(
            isOffer ? 'السعر' : 'الميزانية',
            '${property.price} ${property.currency}',
          ),
        if (isOffer) ...[
          if (property.finishingLevel.isNotEmpty)
            _row('الإكساء', property.finishingLevel),
          if (property.floor.isNotEmpty) _row('الطابق', property.floor),
          if (property.facade.isNotEmpty) _row('الواجهة', property.facade),
          if (property.ownershipType.isNotEmpty)
            _row('الملكية', property.ownershipType),
          _row('الحالة', property.status),
        ],
        if (property.notes.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          pw.Text(
            _ar('ملاحظات:'),
            style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
          ),
          pw.Text(
            _ar(property.notes),
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
        if (imageWidgets.isNotEmpty) ...[
          pw.NewPage(),
          pw.Text(
            _ar('صور العقار'),
            style: pw.TextStyle(font: arabicBoldFont, fontSize: 18),
          ),
          pw.SizedBox(height: 15),
          ...imageWidgets,
        ],
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════
// PdfService — Professional optimized PDF generation
//
// تحسينات الأداء:
// 1. طابور تسلسلي لتوليد PDF — يمنع ازدحام CPU
// 2. توليد عند الطلب فقط (Lazy) — لا توليد تلقائي عند الإضافة
// 3. معالجة صور متكيفة مع الجهاز — جودة أقل للأجهزة الضعيفة
// 4. حد أقصى لعدد الصور في PDF — 4 للضعيفة، 8 للعادية
// 5. ذاكرة تخزين مؤقت مع حد حجم — حذف الملفات القديمة تلقائياً
// 6. إعادة استخدام الخطوط المحمّلة — لا إعادة تحميل
// 7. مهلة زمنية لعملية التوليد — منع التعليق
// ════════════════════════════════════════════════════════
class PdfService {
  static pw.Font? _cachedFont;
  static pw.Font? _cachedBoldFont;

  // Cache size limit: 50 MB
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024;

  // Generation timeout: 30 seconds
  static const Duration _generationTimeout = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════
  // Public API — Lazy generation (on-demand only)
  // ═══════════════════════════════════════════════════

  /// Generates PDF with timeout protection.
  /// No automatic background generation — only when user explicitly requests.
  static Future<Uint8List> generatePropertyPdf({
    required PropertyModel property,
    required SettingsState settings,
    void Function(int completed, int total)? onProgress,
  }) async {
    try {
      final (arabicFont, arabicBoldFont) = await _loadFonts();
      return await _generate(
        property,
        settings,
        arabicFont,
        arabicBoldFont,
        onProgress: onProgress,
      ).timeout(_generationTimeout);
    } catch (e, stack) {
      debugPrint('PdfService: generatePropertyPdf failed: $e\n$stack');
      return _emergencyPdf(property);
    }
  }

  /// Enqueues PDF generation in the sequential queue.
  /// Used for background pre-generation without blocking the UI.
  /// Returns immediately — PDF is generated when queue is ready.
  static Future<void> enqueueForBackgroundCache({
    required PropertyModel property,
    required SettingsState settings,
  }) async {
    // Don't enqueue if device is weak — save CPU for UI responsiveness
    if (_DeviceCapability.isWeak) return;

    // Don't enqueue if queue is already backed up
    if (_PdfGenerationQueue().pendingCount >= 3) return;

    final task = _PdfTask(property: property, settings: settings);
    final result = await _PdfGenerationQueue().enqueue(task);

    if (result != null) {
      await _saveToCache(property.id, result);
    }
  }

  /// Gets cached PDF or generates on-demand.
  /// Primary method for user-initiated PDF export.
  static Future<Uint8List> getCachedPdf({
    required PropertyModel property,
    required SettingsState settings,
    void Function(int completed, int total)? onProgress,
  }) async {
    final id = property.id;
    if (id == null) {
      return generatePropertyPdf(
        property: property,
        settings: settings,
        onProgress: onProgress,
      );
    }

    final dir = await _getCacheDir();
    final file = File('${dir.path}/${_cacheFileName(id)}');

    if (await file.exists()) {
      try {
        return await file.readAsBytes();
      } catch (e) {
        debugPrint(
          'PdfService: corrupted cache for property $id, regenerating: $e',
        );
      }
    }

    final bytes = await generatePropertyPdf(
      property: property,
      settings: settings,
      onProgress: onProgress,
    );

    try {
      await file.writeAsBytes(bytes);
      await _enforceCacheLimit();
    } catch (e) {
      debugPrint('PdfService: failed to write cache for property $id: $e');
    }

    return bytes;
  }

  // ═══════════════════════════════════════════════════
  // Internal — PDF generation engine
  // ═══════════════════════════════════════════════════

  static Future<Uint8List> _generate(
    PropertyModel property,
    SettingsState settings,
    pw.Font arabicFont,
    pw.Font arabicBoldFont, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final isOffer = property.entryType == EntryType.offer;

    final imageList = <Uint8List>[];
    final config = _DeviceCapability.config;

    if (property.images.isNotEmpty) {
      // Limit images to config max — skip extras for performance
      final limitedPaths = property.images.take(config.maxImagesInPdf).toList();

      final results = await _processImagesConcurrently(
        limitedPaths,
        onProgress: onProgress,
      );
      for (final r in results) {
        if (r != null) imageList.add(r);
      }
    }

    onProgress?.call(1, 1);
    await Future.delayed(Duration.zero);

    final entryPdfColor = isOffer ? PdfColors.green900 : PdfColors.orange900;
    final dividerColor = isOffer ? PdfColors.green : PdfColors.orange;

    final imageWidgets = imageList
        .map(
          (b) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Center(
              child: pw.Image(
                pw.MemoryImage(b),
                fit: pw.BoxFit.contain,
                width: 400,
              ),
            ),
          ),
        )
        .toList();

    final pdf = pw.Document(
      title: '${isOffer ? 'Property' : 'Request'}_${property.id}',
      author:
          settings.officeName.isNotEmpty ? settings.officeName : 'Real Estate App',
      subject: '${property.propertyType} - ${property.province}',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBoldFont,
        ),
        build: (_) => [
          _buildPdfContent(
            imageWidgets,
            property,
            settings.officeName,
            settings.officePhone,
            isOffer,
            arabicBoldFont,
            entryPdfColor,
            dividerColor,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _emergencyPdf(PropertyModel property) async {
    final (arabicFont, arabicBoldFont) = await _loadFonts();
    final emergency = pw.Document();
    emergency.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBoldFont,
        ),
        build: (_) => pw.Center(
          child: pw.Text(
            '${_ar(property.propertyType)}\n${property.province}\n${_ar('تقرير عقار')}',
            style: pw.TextStyle(font: arabicBoldFont, fontSize: 18),
          ),
        ),
      ),
    );
    return emergency.save();
  }

  // ═══════════════════════════════════════════════════
  // Internal — Image processing
  // ═══════════════════════════════════════════════════

  static Future<List<Uint8List?>> _processImagesConcurrently(
    List<String> paths, {
    void Function(int completed, int total)? onProgress,
  }) async {
    if (paths.isEmpty) return [];

    final results = List<Uint8List?>.filled(paths.length, null);

    // Process images one-by-one on weak devices to avoid memory pressure
    // Process in parallel (up to 2 concurrent) on capable devices
    if (_DeviceCapability.isWeak) {
      for (int i = 0; i < paths.length; i++) {
        try {
          final bytes = await File(paths[i]).readAsBytes();
          results[i] = await compute(_processImageBytes, bytes);
        } catch (e) {
          debugPrint('PdfService: failed image $i: $e');
        }
        onProgress?.call(i + 1, paths.length);
      }
    } else {
      // Capable device: process up to 2 images concurrently
      const concurrencyLimit = 2;
      for (int start = 0; start < paths.length; start += concurrencyLimit) {
        final end = min(start + concurrencyLimit, paths.length);
        final futures = <Future<void>>[];

        for (int i = start; i < end; i++) {
          final index = i;
          futures.add(
            File(paths[i])
                .readAsBytes()
                .then((bytes) => compute(_processImageBytes, bytes))
                .then((result) => results[index] = result)
                .catchError((e) {
                  debugPrint('PdfService: failed image $i: $e');
                  return null;
                })
                .whenComplete(() => onProgress?.call(index + 1, paths.length)),
          );
        }

        await Future.wait(futures);
      }
    }

    return results;
  }

  // ═══════════════════════════════════════════════════
  // Internal — Font loading (cached)
  // ═══════════════════════════════════════════════════

  static Future<(pw.Font, pw.Font)> _loadFonts() async {
    if (_cachedFont != null && _cachedBoldFont != null) {
      return (_cachedFont!, _cachedBoldFont!);
    }

    try {
      final regular =
          (await rootBundle.load('assets/fonts/Cairo-Regular.ttf'))
              .buffer
              .asUint8List();
      final bold =
          (await rootBundle.load('assets/fonts/Cairo-Bold.ttf'))
              .buffer
              .asUint8List();
      _cachedFont = pw.Font.ttf(regular.buffer.asByteData());
      _cachedBoldFont = pw.Font.ttf(bold.buffer.asByteData());
      return (_cachedFont!, _cachedBoldFont!);
    } catch (e) {
      debugPrint('PdfService: Cairo font error: $e, trying Google Fonts');
      try {
        _cachedFont = await PdfGoogleFonts.notoSansArabicRegular();
        _cachedBoldFont = await PdfGoogleFonts.notoSansArabicBold();
        return (_cachedFont!, _cachedBoldFont!);
      } catch (e2) {
        debugPrint(
          'PdfService: Google Fonts error: $e2, using built-in fallback',
        );
        _cachedFont = pw.Font.helvetica();
        _cachedBoldFont = pw.Font.helveticaBold();
        return (_cachedFont!, _cachedBoldFont!);
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // Internal — Cache management with size limits
  // ═══════════════════════════════════════════════════

  static Future<void> _saveToCache(int? propertyId, Uint8List bytes) async {
    if (propertyId == null) return;
    try {
      final dir = await _getCacheDir();
      await File('${dir.path}/${_cacheFileName(propertyId)}')
          .writeAsBytes(bytes);
    } catch (e) {
      debugPrint('PdfService: failed to save background cache: $e');
    }
  }

  static Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/pdf_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _cacheFileName(int propertyId) => 'property_$propertyId.pdf';

  /// Enforces cache size limit by deleting oldest files first.
  static Future<void> _enforceCacheLimit() async {
    try {
      final dir = await _getCacheDir();
      if (!await dir.exists()) return;

      final files = await dir.list().toList();
      int totalSize = 0;
      final fileSizes = <File, int>{};

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          final size = await entity.length();
          totalSize += size;
          fileSizes[entity] = size;
        }
      }

      if (totalSize <= _maxCacheSizeBytes) return;

      // Sort by modification time (oldest first)
      final sortedFiles = fileSizes.keys.toList();
      sortedFiles.sort((a, b) {
        final aStat = a.lastModifiedSync();
        final bStat = b.lastModifiedSync();
        return aStat.compareTo(bStat);
      });

      // Delete oldest files until under limit
      for (final file in sortedFiles) {
        if (totalSize <= _maxCacheSizeBytes) break;
        final size = fileSizes[file]!;
        await file.delete();
        totalSize -= size;
      }
    } catch (e) {
      debugPrint('PdfService: cache limit enforcement failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // Public API — Cache invalidation
  // ═══════════════════════════════════════════════════

  /// Deletes cached PDF for a specific property.
  static Future<void> invalidateCache(int propertyId) async {
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/${_cacheFileName(propertyId)}');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('PdfService: failed to invalidate cache: $e');
    }
  }

  /// Deletes all cached PDFs (e.g., when office info changes).
  static Future<void> invalidateAllCache() async {
    try {
      final dir = await _getCacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('PdfService: failed to clear all cache: $e');
    }
  }
}
