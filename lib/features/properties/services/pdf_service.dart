import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import 'package:arabic_reshaper/arabic_reshaper.dart';
import '../models/property_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../settings/providers/settings_provider.dart';

/// Decodes [rawBytes], conditionally resizes (if width > 1000), and
/// JPEG‑encodes at quality 75.
Uint8List? _processImageBytes(Uint8List rawBytes) {
  try {
    final image = img.decodeImage(rawBytes);
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

pw.Widget _buildPdfContent(
  List<pw.Widget> imageWidgets,
  Map<String, dynamic> p,
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
  );
}

/// ---------------------------------------------------------------------------
/// Public API
/// ---------------------------------------------------------------------------
class PdfService {
  /// Generates a professional property PDF directly on the main thread.
  /// No isolates, no computes — just straightforward async/await.
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
      final regularFont = await PdfGoogleFonts.notoSansArabicRegular();
      final boldFont = await PdfGoogleFonts.notoSansArabicBold();
      return _generateSync(property, settings, regularFont, boldFont);
    }

    final arabicFont = pw.Font.ttf(fontRegular.buffer.asByteData());
    final arabicBoldFont = pw.Font.ttf(fontBold.buffer.asByteData());

    final isOffer = property.entryType == EntryType.offer;
    final pdf = pw.Document();

    final entryPdfColor = isOffer ? PdfColors.green900 : PdfColors.orange900;
    final dividerColor = isOffer ? PdfColors.green : PdfColors.orange;

    // Process each image directly on the main thread.
    final imageWidgets = <pw.Widget>[];
    for (final imagePath in property.images) {
      try {
        final bytes = await File(imagePath).readAsBytes();
        final processed = _processImageBytes(bytes);
        if (processed != null) {
          imageWidgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Center(
                child: pw.Image(
                  pw.MemoryImage(processed),
                  fit: pw.BoxFit.contain,
                  width: 450,
                ),
              ),
            ),
          );
        }
      } catch (_) {}
    }

    // Build property data map for the shared content builder.
    final p = <String, dynamic>{
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
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        build: (_) => [
          _buildPdfContent(
              imageWidgets, p, isOffer, arabicBoldFont, entryPdfColor, dividerColor),
        ],
      ),
    );

    return pdf.save();
  }

  /// Test-only fallback when rootBundle fonts are unavailable.
  static Future<Uint8List> _generateSync(
    PropertyModel property,
    SettingsState settings,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) async {
    final isOffer = property.entryType == EntryType.offer;
    final pdf = pw.Document();

    final entryPdfColor = isOffer ? PdfColors.green900 : PdfColors.orange900;
    final dividerColor = isOffer ? PdfColors.green : PdfColors.orange;

    final imageWidgets = <pw.Widget>[];
    for (final imagePath in property.images) {
      try {
        final raw = await File(imagePath).readAsBytes();
        final processed = _processImageBytes(raw);
        if (processed != null) {
          imageWidgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Center(
                child: pw.Image(
                  pw.MemoryImage(processed),
                  fit: pw.BoxFit.contain,
                  width: 450,
                ),
              ),
            ),
          );
        }
      } catch (_) {}
    }

    final p = <String, dynamic>{
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
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        build: (_) => [
          _buildPdfContent(
              imageWidgets, p, isOffer, arabicBoldFont, entryPdfColor, dividerColor),
        ],
      ),
    );

    return pdf.save();
  }
}
