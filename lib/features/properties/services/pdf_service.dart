import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
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

const _kWeakDeviceConfig = _PdfImageConfig(
  maxWidth: 400,
  jpegQuality: 45,
  maxImagesInPdf: 4,
);

const _kNormalConfig = _PdfImageConfig(
  maxWidth: 600,
  jpegQuality: 60,
  maxImagesInPdf: 8,
);

// ════════════════════════════════════════════════════════
// Singleton queue for sequential PDF generation
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

    if (Platform.isAndroid) {
      _isWeakDevice = true;
    } else if (Platform.isIOS) {
      _isWeakDevice = false;
    } else {
      _isWeakDevice = false;
    }

    return _isWeakDevice!;
  }
}

// ════════════════════════════════════════════════════════
// ISOLATE ENTRY POINTS — Top-level functions for compute/Isolate.run
//
// ALL heavy work happens here:
// 1. File I/O (readAsBytes) — inside isolate, not on main thread
// 2. Image decoding, resizing, compression — inside isolate
// 3. PDF document construction — inside isolate
//
// Main thread only handles: font loading (Flutter API), cache I/O, UI updates
// ════════════════════════════════════════════════════════

/// Complete PDF generation inside an isolate.
/// Receives font bytes and property data as serializable types.
/// Returns the final PDF bytes.
///
/// This function does ALL heavy work:
/// - Reads image files from disk
/// - Decodes, resizes, compresses images
/// - Builds the PDF document with Arabic text
/// - Serializes the PDF to bytes
Future<Uint8List> _generatePdfInIsolate(_IsolatePdfInput input) async {
  final config = input.isWeakDevice ? _kWeakDeviceConfig : _kNormalConfig;

  // Step 1: Read and process images FROM DISK inside the isolate
  final imageBytes = <Uint8List>[];
  final limitedPaths = input.imagePaths.take(config.maxImagesInPdf).toList();

  for (final path in limitedPaths) {
    try {
      final rawBytes = await File(path).readAsBytes();
      final processed = _processImageBytesIsolated(rawBytes, config);
      if (processed != null) {
        imageBytes.add(processed);
      }
    } catch (_) {
      // Skip failed images
    }
  }

  // Step 2: Build PDF document inside the isolate
  final pdf = await _buildPdfDocument(
    imageBytes: imageBytes,
    propertyMap: input.propertyMap,
    officeName: input.officeName,
    officePhone: input.officePhone,
    isOffer: input.isOffer,
    fontBytes: input.fontBytes,
    boldFontBytes: input.boldFontBytes,
  );

  return pdf;
}

/// Image processing — runs entirely inside isolate.
/// Receives raw bytes, returns compressed JPEG.
Uint8List? _processImageBytesIsolated(
  Uint8List rawBytes,
  _PdfImageConfig config,
) {
  try {
    final image = img.decodeImage(rawBytes);
    if (image == null) return null;

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

/// Builds the complete PDF document inside the isolate.
/// All parameters are serializable types (no Flutter objects).
Future<Uint8List> _buildPdfDocument({
  required List<Uint8List> imageBytes,
  required Map<String, dynamic> propertyMap,
  required String officeName,
  required String officePhone,
  required bool isOffer,
  required Uint8List fontBytes,
  required Uint8List boldFontBytes,
}) {
  final property = PropertyModel.fromMap(propertyMap);
  final arabicFont = pw.Font.ttf(fontBytes.buffer.asByteData());
  final arabicBoldFont = pw.Font.ttf(boldFontBytes.buffer.asByteData());

  final entryPdfColor = isOffer ? PdfColors.green900 : PdfColors.orange900;
  final dividerColor = isOffer ? PdfColors.green : PdfColors.orange;

  final imageWidgets = imageBytes
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
    author: officeName.isNotEmpty ? officeName : 'Real Estate App',
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
          officeName,
          officePhone,
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

/// Input data package for isolate PDF generation.
/// All fields are serializable across isolate boundaries.
class _IsolatePdfInput {
  final Map<String, dynamic> propertyMap;
  final List<String> imagePaths;
  final String officeName;
  final String officePhone;
  final bool isOffer;
  final bool isWeakDevice;
  final Uint8List fontBytes;
  final Uint8List boldFontBytes;

  _IsolatePdfInput({
    required this.propertyMap,
    required this.imagePaths,
    required this.officeName,
    required this.officePhone,
    required this.isOffer,
    required this.isWeakDevice,
    required this.fontBytes,
    required this.boldFontBytes,
  });
}

// ════════════════════════════════════════════════════════
// PDF content builder (pure layout, runs inside isolate)
// ════════════════════════════════════════════════════════

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
// PdfService — Public API
// ════════════════════════════════════════════════════════
class PdfService {
  static Uint8List? _cachedFontBytes;
  static Uint8List? _cachedBoldFontBytes;

  // Cache size limit: 50 MB
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024;

  // Generation timeout: 45 seconds (isolate adds slight overhead)
  static const Duration _generationTimeout = Duration(seconds: 45);

  // ═══════════════════════════════════════════════════
  // Font loading (main thread — requires Flutter APIs)
  // ═══════════════════════════════════════════════════

  static Future<(Uint8List, Uint8List)> _loadFontBytes() async {
    if (_cachedFontBytes != null && _cachedBoldFontBytes != null) {
      return (_cachedFontBytes!, _cachedBoldFontBytes!);
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
      _cachedFontBytes = regular;
      _cachedBoldFontBytes = bold;
      return (regular, bold);
    } catch (e) {
      debugPrint('PdfService: Cairo font error: $e, trying Google Fonts');
      try {
        await PdfGoogleFonts.notoSansArabicRegular();
        await PdfGoogleFonts.notoSansArabicBold();
        _cachedFontBytes = Uint8List(0);
        _cachedBoldFontBytes = Uint8List(0);
        return (Uint8List(0), Uint8List(0));
      } catch (e2) {
        debugPrint(
          'PdfService: Google Fonts error: $e2, using built-in fallback',
        );
        _cachedFontBytes = Uint8List(0);
        _cachedBoldFontBytes = Uint8List(0);
        return (Uint8List(0), Uint8List(0));
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // Public API — Full isolate-based generation
  // ═══════════════════════════════════════════════════

  /// Generates PDF with ALL heavy work in an isolate:
  /// - File I/O (reading images from disk)
  /// - Image decoding, resizing, compression
  /// - PDF document construction
  ///
  /// Main thread only loads fonts (Flutter API) and manages cache.
  static Future<Uint8List> generatePropertyPdf({
    required PropertyModel property,
    required SettingsState settings,
    void Function(int completed, int total)? onProgress,
  }) async {
    try {
      final (fontBytes, boldFontBytes) = await _loadFontBytes();
      final isOffer = property.entryType == EntryType.offer;

      final input = _IsolatePdfInput(
        propertyMap: property.toMap(),
        imagePaths: property.images,
        officeName: settings.officeName,
        officePhone: settings.officePhone,
        isOffer: isOffer,
        isWeakDevice: _DeviceCapability.isWeak,
        fontBytes: fontBytes,
        boldFontBytes: boldFontBytes,
      );

      onProgress?.call(0, 1);

      // ALL heavy work runs in background isolate — zero main-thread blocking
      final bytes = await Isolate.run<Uint8List>(
        () => _generatePdfInIsolate(input),
      ).timeout(_generationTimeout);

      onProgress?.call(1, 1);
      return bytes;
    } catch (e, stack) {
      debugPrint('PdfService: generatePropertyPdf failed: $e\n$stack');
      return _emergencyPdf(property);
    }
  }

  /// Enqueues PDF generation in the sequential queue.
  static Future<void> enqueueForBackgroundCache({
    required PropertyModel property,
    required SettingsState settings,
  }) async {
    if (_DeviceCapability.isWeak) return;
    if (_PdfGenerationQueue().pendingCount >= 3) return;

    final task = _PdfTask(property: property, settings: settings);
    final result = await _PdfGenerationQueue().enqueue(task);

    if (result != null) {
      await _saveToCache(property.id, result);
    }
  }

  /// Gets cached PDF or generates on-demand.
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
  // Emergency PDF (main thread fallback)
  // ═══════════════════════════════════════════════════

  static Future<Uint8List> _emergencyPdf(PropertyModel property) async {
    try {
      final (fontBytes, boldFontBytes) = await _loadFontBytes();
      final arabicFont = pw.Font.ttf(fontBytes.buffer.asByteData());
      final arabicBoldFont = pw.Font.ttf(boldFontBytes.buffer.asByteData());

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
    } catch (_) {
      // Absolute last resort — return empty PDF
      return Uint8List.fromList([
        0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34,
      ]);
    }
  }

  // ═══════════════════════════════════════════════════
  // Cache management
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

      final sortedFiles = fileSizes.keys.toList();
      sortedFiles.sort((a, b) {
        final aStat = a.lastModifiedSync();
        final bStat = b.lastModifiedSync();
        return aStat.compareTo(bStat);
      });

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
