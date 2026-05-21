import 'dart:io';
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

Uint8List? _processImageBytes(Uint8List rawBytes) {
  try {
    final image = img.decodeImage(rawBytes);
    if (image == null) return null;

    img.Image resized = image;
    if (image.width > 800) {
      resized = img.copyResize(image, width: 800);
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
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
        pw.Text(_ar(title),
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        pw.Text(_ar(value), style: const pw.TextStyle(color: PdfColors.black)),
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
              _ar('تاريخ التصدير: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700),
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
                pw.Text(_ar(officeName),
                    style: pw.TextStyle(
                        font: arabicBoldFont, fontSize: 16)),
                if (officePhone.isNotEmpty)
                  pw.Text(_ar('هاتف: $officePhone'),
                      style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text(
          _ar(isOffer
              ? 'تفاصيل ومواصفات العقار'
              : 'تفاصيل طلب الزبون'),
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
        if (property.region.isNotEmpty)
          _row('المنطقة', property.region),
        if (property.area > 0)
          _row('المساحة', '${property.area} م²'),
        if (property.rooms > 0)
          _row('عدد الغرف', '${property.rooms}'),
        if (property.price > 0)
          _row(
            isOffer ? 'السعر' : 'الميزانية',
            '${property.price} ${property.currency}',
          ),
        if (isOffer) ...[
          if (property.finishingLevel.isNotEmpty)
            _row('الإكساء', property.finishingLevel),
          if (property.floor.isNotEmpty)
            _row('الطابق', property.floor),
          if (property.facade.isNotEmpty)
            _row('الواجهة', property.facade),
          if (property.ownershipType.isNotEmpty)
            _row('الملكية', property.ownershipType),
          _row('الحالة', property.status),
        ],
        if (property.notes.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          pw.Text(_ar('ملاحظات:'),
              style:
                  pw.TextStyle(font: arabicBoldFont, fontSize: 14)),
          pw.Text(_ar(property.notes),
              style: const pw.TextStyle(fontSize: 12)),
        ],
        if (imageWidgets.isNotEmpty) ...[
          pw.NewPage(),
          pw.Text(_ar('صور العقار'),
              style:
                  pw.TextStyle(font: arabicBoldFont, fontSize: 18)),
          pw.SizedBox(height: 15),
          ...imageWidgets,
        ],
      ],
    ),
  );
}

class PdfService {
  static pw.Font? _cachedFont;
  static pw.Font? _cachedBoldFont;

  static Future<Uint8List> generatePropertyPdf({
    required PropertyModel property,
    required SettingsState settings,
    void Function(int completed, int total)? onProgress,
  }) async {
    try {
      final (arabicFont, arabicBoldFont) = await _loadFonts();
      return await _generate(property, settings, arabicFont, arabicBoldFont, onProgress: onProgress);
    } catch (e, stack) {
      debugPrint('PdfService: generatePropertyPdf failed: $e\n$stack');
      final (arabicFont, arabicBoldFont) = await _loadFonts();
      final emergency = pw.Document();
      emergency.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
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
  }

  static Future<void> generateAndCachePdf({
    required PropertyModel property,
    required SettingsState settings,
  }) async {
    try {
      final bytes = await generatePropertyPdf(property: property, settings: settings);
      await _saveToCache(property.id, bytes);
    } catch (e) {
      debugPrint('PdfService: generateAndCachePdf failed: $e');
    }
  }

  static Future<void> _saveToCache(int? propertyId, Uint8List bytes) async {
    if (propertyId == null) return;
    try {
      final dir = await _getCacheDir();
      await File('${dir.path}/${_cacheFileName(propertyId)}').writeAsBytes(bytes);
    } catch (e) {
      debugPrint('PdfService: failed to save background cache: $e');
    }
  }

  static Future<(pw.Font, pw.Font)> _loadFonts() async {
    if (_cachedFont != null && _cachedBoldFont != null) {
      return (_cachedFont!, _cachedBoldFont!);
    }

    try {
      final regular = (await rootBundle.load('assets/fonts/Cairo-Regular.ttf'))
          .buffer
          .asUint8List();
      final bold = (await rootBundle.load('assets/fonts/Cairo-Bold.ttf'))
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
        debugPrint('PdfService: Google Fonts error: $e2, using built-in fallback');
        _cachedFont = pw.Font.helvetica();
        _cachedBoldFont = pw.Font.helveticaBold();
        return (_cachedFont!, _cachedBoldFont!);
      }
    }
  }

  static Future<Uint8List> _generate(
    PropertyModel property,
    SettingsState settings,
    pw.Font arabicFont,
    pw.Font arabicBoldFont, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final isOffer = property.entryType == EntryType.offer;
    final entryPdfColor = isOffer ? PdfColors.green900 : PdfColors.orange900;
    final dividerColor = isOffer ? PdfColors.green : PdfColors.orange;

    try {
      final pdf = pw.Document(
        title: '${isOffer ? 'Property' : 'Request'}_${property.id}',
        author: settings.officeName.isNotEmpty ? settings.officeName : 'Real Estate App',
        subject: '${property.propertyType} - ${property.province}',
      );

      final imageWidgets = <pw.Widget>[];
      if (property.images.isNotEmpty) {
        final results = await _processImagesConcurrently(
          property.images,
          onProgress: onProgress,
        );
        for (final processed in results) {
          if (processed != null) {
            imageWidgets.add(_buildImageWidget(processed));
          }
        }
      }

      await Future.delayed(Duration.zero);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
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
    } catch (e, stack) {
      debugPrint('PdfService: _generate failed with images: $e\n$stack');

      final fallbackPdf = pw.Document(
        title: '${isOffer ? 'Property' : 'Request'}_${property.id}',
        author: settings.officeName.isNotEmpty ? settings.officeName : 'Real Estate App',
        subject: '${property.propertyType} - ${property.province}',
      );

      fallbackPdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
          build: (_) => [
            _buildPdfContent(
              [],
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

      debugPrint('PdfService: trying fallback without images');
      return fallbackPdf.save();
    }
  }

  // ─── PDF Cache ─────────────────────────────────────────────────────────

  static Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/pdf_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _cacheFileName(int propertyId) =>
      'property_$propertyId.pdf';

  /// Returns cached PDF if available, otherwise generates and caches it.
  static Future<Uint8List> getCachedPdf({
    required PropertyModel property,
    required SettingsState settings,
    void Function(int completed, int total)? onProgress,
  }) async {
    final id = property.id;
    if (id == null) {
      return generatePropertyPdf(property: property, settings: settings);
    }

    final dir = await _getCacheDir();
    final file = File('${dir.path}/${_cacheFileName(id)}');

    if (await file.exists()) {
      try {
        return await file.readAsBytes();
      } catch (e) {
        debugPrint(
            'PdfService: corrupted cache for property $id, regenerating: $e');
      }
    }

    final bytes = await generatePropertyPdf(
      property: property,
      settings: settings,
      onProgress: onProgress,
    );

    try {
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('PdfService: failed to write cache for property $id: $e');
    }

    return bytes;
  }

  static Future<List<Uint8List?>> _processImagesConcurrently(
    List<String> paths, {
    void Function(int completed, int total)? onProgress,
  }) async {
    if (paths.isEmpty) return [];

    final results = List<Uint8List?>.filled(paths.length, null);

    for (int i = 0; i < paths.length; i++) {
      try {
        final bytes = await File(paths[i]).readAsBytes();
        results[i] = await compute(_processImageBytes, bytes);
      } catch (e) {
        debugPrint('PdfService: failed image $i: $e');
      }

      onProgress?.call(i + 1, paths.length);
    }

    return results;
  }

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

  static pw.Widget _buildImageWidget(Uint8List processed) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Center(
        child: pw.Image(
          pw.MemoryImage(processed),
          fit: pw.BoxFit.contain,
          width: 400,
        ),
      ),
    );
  }
}
