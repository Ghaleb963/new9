import 'dart:isolate';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import 'package:arabic_reshaper/arabic_reshaper.dart';
import '../models/property_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../settings/providers/settings_provider.dart';

/// ---------------------------------------------------------------------------
/// Background isolate entry point
/// ---------------------------------------------------------------------------
/// All PDF generation (image decoding, resizing, document assembly) runs
/// here so the main isolate stays free to animate the loading dialog.
/// Only primitive/sendable data is passed through [req].
@pragma('vm:entry-point')
Future<Uint8List> _generatePdfInBackground(Map<String, dynamic> req) async {
  // Fonts were loaded in the main isolate (rootBundle unavailable here)
  final regularData = Uint8List.fromList(req['fontRegular'] as List<int>);
  final boldData = Uint8List.fromList(req['fontBold'] as List<int>);
  final arabicFont = pw.Font.ttf(regularData.buffer.asByteData());
  final arabicBoldFont = pw.Font.ttf(boldData.buffer.asByteData());

  final images = (req['images'] as List).cast<String>();
  final p = req['property'] as Map<String, dynamic>;
  final s = req['settings'] as Map<String, dynamic>;

  final isOffer = s['isOffer'] as bool;
  final pdf = pw.Document();

  // Parallel image processing across CPU cores — each image is decoded,
  // resized, and re-encoded in its own background isolate simultaneously.
  final imageBytesList = await Future.wait(
    images.map((path) => Isolate.run(() => _processImage(path))),
  );

  final imageWidgets = <pw.Widget>[];
  for (final bytes in imageBytesList) {
    if (bytes != null) {
      imageWidgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Center(
            child: pw.Image(
              pw.MemoryImage(bytes),
              fit: pw.BoxFit.contain,
              width: 450,
            ),
          ),
        ),
      );
    }
  }

  final entryPdfColor = isOffer ? PdfColors.green900 : PdfColors.orange900;
  final dividerColor = isOffer ? PdfColors.green : PdfColors.orange;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
      build: (pw.Context context) {
        return [
          pw.Directionality(
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
                if ((p['officeName'] as String? ?? '').isNotEmpty) ...[
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
                        pw.Text(_ar(p['officeName'] as String),
                            style: pw.TextStyle(
                                font: arabicBoldFont, fontSize: 16)),
                        if ((p['officePhone'] as String? ?? '').isNotEmpty)
                          pw.Text(_ar('هاتف: ${p['officePhone']}'),
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
                _row('نوع السجل', p['entryType'] as String? ?? ''),
                _row('نوع العقار', p['propertyType'] as String? ?? ''),
                _row(
                  isOffer ? 'نوع الإعلان' : 'نوع المطلوب',
                  p['adType'] as String? ?? '',
                ),
                _row('المحافظة', p['province'] as String? ?? ''),
                if ((p['region'] as String? ?? '').isNotEmpty)
                  _row('المنطقة', p['region'] as String),
                if ((p['area'] as num?) != null && (p['area'] as num) > 0)
                  _row('المساحة', '${p['area']} م²'),
                if ((p['rooms'] as num?) != null && (p['rooms'] as num) > 0)
                  _row('عدد الغرف', '${p['rooms']}'),
                if ((p['price'] as num?) != null && (p['price'] as num) > 0)
                  _row(
                    isOffer ? 'السعر' : 'الميزانية',
                    '${p['price']} ${p['currency']}',
                  ),
                if (isOffer) ...[
                  if ((p['finishingLevel'] as String? ?? '').isNotEmpty)
                    _row('الإكساء', p['finishingLevel'] as String),
                  if ((p['floor'] as String? ?? '').isNotEmpty)
                    _row('الطابق', p['floor'] as String),
                  if ((p['facade'] as String? ?? '').isNotEmpty)
                    _row('الواجهة', p['facade'] as String),
                  if ((p['ownershipType'] as String? ?? '').isNotEmpty)
                    _row('الملكية', p['ownershipType'] as String),
                  _row('الحالة', p['status'] as String? ?? ''),
                ],
                if ((p['notes'] as String? ?? '').isNotEmpty) ...[
                  pw.SizedBox(height: 15),
                  pw.Text(_ar('ملاحظات:'),
                      style:
                          pw.TextStyle(font: arabicBoldFont, fontSize: 14)),
                  pw.Text(_ar(p['notes'] as String),
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
          ),
        ];
      },
    ),
  );

  return pdf.save();
}

/// Reads, conditionally resizes (if width > 1000), and JPEG-encodes a single
/// image.  Returns the processed bytes so they can be sent across isolates.
/// The original file on disk is never modified.
@pragma('vm:entry-point')
Uint8List? _processImage(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    img.Image resized = image;
    if (image.width > 1000) {
      resized = img.copyResize(image, width: 1000);
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
  } catch (_) {
    return null;
  }
}

String _ar(String text) {
  return ArabicReshaper.instance.reshape(text);
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

/// ---------------------------------------------------------------------------
/// Public API
/// ---------------------------------------------------------------------------
class PdfService {
  /// Generates a professional property PDF.
  ///
  /// Font loading (which depends on [rootBundle]) happens in the main
  /// isolate; the heavy work — image decoding, resizing, and document
  /// assembly — is offloaded to a background [Isolate] so the UI thread
  /// never freezes, even with many high‑resolution photos.
  static Future<Uint8List> generatePropertyPdf({
    required PropertyModel property,
    required SettingsState settings,
  }) async {
    Uint8List fontRegular;
    Uint8List fontBold;
    try {
      fontRegular = (await rootBundle.load('assets/fonts/Cairo-Regular.ttf'))
          .buffer
          .asUint8List();
      fontBold = (await rootBundle.load('assets/fonts/Cairo-Bold.ttf'))
          .buffer
          .asUint8List();
    } catch (_) {
      // Fonts unavailable (e.g. test environment) → fallback to Google Fonts.
      // We retrieve them in the main isolate, then pass the loaded [pw.Font]
      // objects directly to the synchronous fallback (no isolate needed).
      final regularFont = await PdfGoogleFonts.notoSansArabicRegular();
      final boldFont = await PdfGoogleFonts.notoSansArabicBold();
      return _generateSync(property, settings, regularFont, boldFont);
    }

    final request = <String, dynamic>{
      'images': property.images,
      'property': {
        'entryType': property.entryType.label,
        'adType': property.adType,
        'deedType': property.deedType,
        'propertyType': property.propertyType,
        'province': property.province,
        'region': property.region,
        'floor': property.floor,
        'rooms': property.rooms,
        'area': property.area,
        'facade': property.facade,
        'finishingLevel': property.finishingLevel,
        'ownershipType': property.ownershipType,
        'status': property.status,
        'price': property.price,
        'currency': property.currency,
        'notes': property.notes,
        'officeName': settings.officeName,
        'officePhone': settings.officePhone,
      },
      'settings': {
        'isOffer': property.entryType == EntryType.offer,
      },
      'fontRegular': fontRegular,
      'fontBold': fontBold,
    };

    return compute(_generatePdfInBackground, request);
  }

  /// Synchronous fallback — only used when the bundled font files cannot
  /// be loaded (edge case: tests or missing assets).  The Google Fonts
  /// [pw.Font] objects are passed in directly, so no rootBundle call is
  /// needed.  This path still blocks the main thread, but it is only
  /// reached in non‑production scenarios.
  static Future<Uint8List> _generateSync(
    PropertyModel property,
    SettingsState settings,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) async {
    final isOffer = property.entryType == EntryType.offer;
    final pdf = pw.Document();

    final imageWidgets = <pw.Widget>[];
    for (final imagePath in property.images) {
      final bytes = _processImage(imagePath);
      if (bytes != null) {
        imageWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Center(
              child: pw.Image(
                pw.MemoryImage(bytes),
                fit: pw.BoxFit.contain,
                width: 450,
              ),
            ),
          ),
        );
      }
    }

    final entryPdfColor = isOffer ? PdfColors.green900 : PdfColors.orange900;
    final dividerColor = isOffer ? PdfColors.green : PdfColors.orange;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        _ar(isOffer
                            ? 'تقرير العقار الاحترافي'
                            : 'تقرير طلب عقار'),
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
                  if (settings.officeName.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border(
                          right:
                              pw.BorderSide(color: dividerColor, width: 4),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_ar(settings.officeName),
                              style: pw.TextStyle(
                                  font: arabicBoldFont, fontSize: 16)),
                          if (settings.officePhone.isNotEmpty)
                            pw.Text(_ar('هاتف: ${settings.officePhone}'),
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
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
