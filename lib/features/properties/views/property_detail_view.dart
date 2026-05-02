import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_model.dart';
import '../providers/property_provider.dart';
import 'add_property_view.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import '../../settings/providers/settings_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_helpers.dart';

class PropertyDetailView extends ConsumerStatefulWidget {
  final PropertyModel property;
  const PropertyDetailView({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailView> createState() => _PropertyDetailViewState();
}

class _PropertyDetailViewState extends ConsumerState<PropertyDetailView> {
  late PropertyModel _property;
  bool get _isOffer => _property.entryType == EntryType.offer;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
  }

  // ─── PDF Generation ──────────────────────────────────────────────────────
  Future<Uint8List?> _processImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      img.Image resized = image;
      if (image.width > 1000) resized = img.copyResize(image, width: 1000);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
    } catch (e) {
      debugPrint('خطأ في معالجة الصورة: $e');
      return null;
    }
  }

  Future<void> _generateAndSharePdf() async {
    final settings = ref.read(settingsProvider);
    final pdf = pw.Document();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.sp24),
          decoration: BoxDecoration(
            color: AppTheme.bgRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.accentGreen),
              SizedBox(height: AppTheme.sp16),
              Text('جاري إنشاء PDF...',
                  style: TextStyle(color: AppTheme.textMedium)),
            ],
          ),
        ),
      ),
    );

    late pw.Font arabicFont;
    late pw.Font arabicBoldFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      arabicFont = pw.Font.ttf(fontData);
      arabicBoldFont = pw.Font.ttf(fontBoldData);
    } catch (_) {
      arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
      arabicBoldFont = await PdfGoogleFonts.notoSansArabicBold();
    }

    final imageWidgets = <pw.Widget>[];
    if (_isOffer) {
      for (final imagePath in _property.images) {
        final processedBytes = await _processImage(imagePath);
        if (processedBytes != null) {
          imageWidgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Center(
                child: pw.Image(
                  pw.MemoryImage(processedBytes),
                  fit: pw.BoxFit.contain,
                  width: 450,
                ),
              ),
            ),
          );
        }
      }
    }

    final entryPdfColor = _isOffer ? PdfColors.green900 : PdfColors.orange900;
    final dividerColor = _isOffer ? PdfColors.green : PdfColors.orange;

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
                        _isOffer ? 'تقرير العقار الاحترافي' : 'تقرير طلب عقار',
                        style: pw.TextStyle(
                            font: arabicBoldFont,
                            fontSize: 22,
                            color: entryPdfColor),
                      ),
                      pw.Text(
                        'تاريخ التصدير: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
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
                          right: pw.BorderSide(color: dividerColor, width: 4),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(settings.officeName,
                              style: pw.TextStyle(
                                  font: arabicBoldFont, fontSize: 16)),
                          if (settings.officePhone.isNotEmpty)
                            pw.Text('هاتف: ${settings.officePhone}',
                                style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                  pw.Text(
                    _isOffer ? 'تفاصيل ومواصفات العقار' : 'تفاصيل طلب الزبون',
                    style: pw.TextStyle(font: arabicBoldFont, fontSize: 18),
                  ),
                  pw.SizedBox(height: 10),
                  _buildPdfRow('نوع السجل', _property.entryType.label),
                  _buildPdfRow('نوع العقار', _property.propertyType),
                  _buildPdfRow(_isOffer ? 'نوع الإعلان' : 'نوع المطلوب',
                      _property.adType),
                  _buildPdfRow('المحافظة', _property.province),
                  if (_property.region.isNotEmpty)
                    _buildPdfRow('المنطقة', _property.region),
                  if (_property.area > 0)
                    _buildPdfRow('المساحة', '${_property.area} م²'),
                  if (_property.rooms > 0)
                    _buildPdfRow('عدد الغرف', '${_property.rooms}'),
                  if (_property.price > 0)
                    _buildPdfRow(_isOffer ? 'السعر' : 'الميزانية',
                        '${_property.price} ${_property.currency}'),
                  if (_isOffer) ...[
                    if (_property.finishingLevel.isNotEmpty)
                      _buildPdfRow('الإكساء', _property.finishingLevel),
                    if (_property.floor.isNotEmpty)
                      _buildPdfRow('الطابق', _property.floor),
                    if (_property.facade.isNotEmpty)
                      _buildPdfRow('الواجهة', _property.facade),
                    if (_property.ownershipType.isNotEmpty)
                      _buildPdfRow('الملكية', _property.ownershipType),
                    _buildPdfRow('الحالة', _property.status),
                  ],
                  if (_property.notes.isNotEmpty) ...[
                    pw.SizedBox(height: 15),
                    pw.Text('ملاحظات:',
                        style:
                            pw.TextStyle(font: arabicBoldFont, fontSize: 14)),
                    pw.Text(_property.notes,
                        style: const pw.TextStyle(fontSize: 12)),
                  ],
                  if (imageWidgets.isNotEmpty) ...[
                    pw.NewPage(),
                    pw.Text('صور العقار',
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

    if (mounted) Navigator.pop(context);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${_isOffer ? "Property" : "Request"}_${_property.id}.pdf',
    );
  }

  pw.Widget _buildPdfRow(String title, String value) {
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
          pw.Text(title,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.Text(value, style: const pw.TextStyle(color: PdfColors.black)),
        ],
      ),
    );
  }

  // ─── Delete ──────────────────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(_isOffer
            ? 'هل تريد حذف هذا العقار نهائياً؟'
            : 'هل تريد حذف هذا الطلب نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(propertyProvider.notifier).deleteProperty(_property.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  // ─── Change Status ────────────────────────────────────────────────────────
  Future<void> _showStatusSheet() async {
    final newStatus = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.sp16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTheme.sp16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: AppTheme.sp12),
                child: Text(
                  'تغيير حالة العقار',
                  style: TextStyle(
                    fontSize: AppTheme.fontLg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...AppConstants.statusList.map(
                (s) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp24,
                  ),
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: StatusHelpers.color(s),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(s),
                  trailing: _property.status == s
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppTheme.accentGreen,
                          size: 20,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, s),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (newStatus != null && newStatus != _property.status && mounted) {
      await ref
          .read(propertyProvider.notifier)
          .updatePropertyStatus(_property.id!, newStatus);
      setState(() => _property = _property.copyWith(status: newStatus));
    }
  }

  // ─── Open Edit ────────────────────────────────────────────────────────────
  Future<void> _openEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPropertyView(existingProperty: _property),
      ),
    );
    if (updated == true && mounted) {
      final fresh = ref
          .read(propertyProvider)
          .firstWhere((p) => p.id == _property.id, orElse: () => _property);
      setState(() => _property = fresh);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final entryColor = _isOffer ? AppTheme.accentGreen : AppTheme.accentAmber;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPage,
        title: Text(_isOffer ? 'تفاصيل العقار' : 'تفاصيل الطلب'),
        actions: [
          _AppBarAction(
            icon: Icons.picture_as_pdf_rounded,
            tooltip: 'تصدير PDF',
            onTap: _generateAndSharePdf,
          ),
          _AppBarAction(
            icon: Icons.edit_rounded,
            tooltip: 'تعديل',
            onTap: _openEdit,
          ),
          _AppBarAction(
            icon: Icons.delete_rounded,
            tooltip: 'حذف',
            onTap: _confirmDelete,
            color: AppTheme.accentRed.withValues(alpha: 0.8),
          ),
          const SizedBox(width: AppTheme.sp8),
        ],
      ),

      // FAB for status change (offers only)
      floatingActionButton: _isOffer
          ? FloatingActionButton.extended(
              onPressed: _showStatusSheet,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text('الحالة: ${_property.status}'),
              backgroundColor: StatusHelpers.color(_property.status),
              elevation: 0,
            )
          : null,

      body: ListView(
        children: [
          // ── Image Gallery ──────────────────────────────────────────────
          if (_isOffer && _property.images.isNotEmpty)
            _ImageGallery(images: _property.images),

          // ── Hero Header ────────────────────────────────────────────────
          _HeroHeader(property: _property, entryColor: entryColor),

          // ── Details ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.sp16,
              AppTheme.sp8,
              AppTheme.sp16,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Core specs grid
                _SpecsGrid(property: _property),
                const SizedBox(height: AppTheme.sp16),

                // Location
                _DetailSection(
                  title: 'الموقع',
                  icon: Icons.location_on_rounded,
                  color: entryColor,
                  children: [
                    _InfoRow(
                      icon: Icons.map_rounded,
                      label: 'المحافظة',
                      value: _property.province,
                    ),
                    if (_property.region.isNotEmpty)
                      _InfoRow(
                        icon: Icons.place_rounded,
                        label: 'المنطقة',
                        value: _property.region,
                      ),
                    if (_isOffer && _property.addressDetails.isNotEmpty)
                      _InfoRow(
                        icon: Icons.home_rounded,
                        label: 'العنوان',
                        value: _property.addressDetails,
                      ),
                  ],
                ),

                // Property details (offers only)
                if (_isOffer) ...[
                  _DetailSection(
                    title: 'مواصفات العقار',
                    icon: Icons.apartment_rounded,
                    color: entryColor,
                    children: [
                      _InfoRow(
                        icon: Icons.sell_rounded,
                        label: 'نوع الإعلان',
                        value: _property.adType,
                      ),
                      if (_property.deedType.isNotEmpty)
                        _InfoRow(
                          icon: Icons.description_rounded,
                          label: 'نوع السند',
                          value: _property.deedType,
                        ),
                      if (_property.floor.isNotEmpty)
                        _InfoRow(
                          icon: Icons.layers_rounded,
                          label: 'الطابق',
                          value: _property.floor,
                        ),
                      if (_property.facade.isNotEmpty)
                        _InfoRow(
                          icon: Icons.crop_landscape_rounded,
                          label: 'الواجهة',
                          value: _property.facade,
                        ),
                      if (_property.finishingLevel.isNotEmpty)
                        _InfoRow(
                          icon: Icons.auto_fix_high_rounded,
                          label: 'الإكساء',
                          value: _property.finishingLevel,
                        ),
                      if (_property.ownershipType.isNotEmpty)
                        _InfoRow(
                          icon: Icons.gavel_rounded,
                          label: 'الملكية',
                          value: _property.ownershipType,
                        ),
                      _InfoRow(
                        icon: StatusHelpers.icon(_property.status),
                        label: 'الحالة',
                        value: _property.status,
                        valueColor: StatusHelpers.color(_property.status),
                      ),
                      if (_property.hasGarden)
                        const _InfoRow(
                          icon: Icons.park_rounded,
                          label: 'حديقة',
                          value: 'نعم',
                        ),
                      if (_property.isDuplex)
                        const _InfoRow(
                          icon: Icons.stairs_rounded,
                          label: 'دوبلكس',
                          value: 'نعم',
                        ),
                      if (_property.directions.isNotEmpty)
                        _InfoRow(
                          icon: Icons.explore_rounded,
                          label: 'الاتجاهات',
                          value: _property.directions.join(' · '),
                        ),
                    ],
                  ),

                  // Features chips
                  if (_property.features.isNotEmpty)
                    _FeaturesSection(
                      features: _property.features,
                      color: entryColor,
                    ),
                ],

                // Contact info
                _ContactSection(
                  property: _property,
                  isOffer: _isOffer,
                  entryColor: entryColor,
                ),

                // Notes
                if (_property.notes.isNotEmpty)
                  _NotesSection(
                    notes: _property.notes,
                    color: entryColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── AppBar Action Button ──────────────────────────────────────────────────────
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: color ?? AppTheme.textMedium),
        splashRadius: 20,
      ),
    );
  }
}

// ── Image Gallery ─────────────────────────────────────────────────────────────
class _ImageGallery extends StatefulWidget {
  final List<String> images;
  const _ImageGallery({required this.images});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) => Image.file(
              File(widget.images[index]),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.bgRaised,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 60,
                    color: AppTheme.textLow,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Page indicator
        if (widget.images.length > 1)
          Positioned(
            bottom: AppTheme.sp12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? AppTheme.accentGreen
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Hero Header (price + type) ────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final PropertyModel property;
  final Color entryColor;
  const _HeroHeader({required this.property, required this.entryColor});

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}م';
    }
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}ك';
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isOffer = property.entryType == EntryType.offer;
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            entryColor.withValues(alpha: 0.10),
            AppTheme.bgPage,
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp12,
              vertical: AppTheme.sp4,
            ),
            decoration: BoxDecoration(
              color: entryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: entryColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOffer ? Icons.home_work_rounded : Icons.search_rounded,
                  size: 13,
                  color: entryColor,
                ),
                const SizedBox(width: 5),
                Text(
                  property.entryType.label,
                  style: TextStyle(
                    color: entryColor,
                    fontSize: AppTheme.fontXs,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.sp12),
          // Title
          Text(
            '${property.propertyType} — ${property.adType}',
            style: const TextStyle(
              fontSize: AppTheme.font2xl,
              fontWeight: FontWeight.w800,
              color: AppTheme.textHigh,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppTheme.sp8),
          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppTheme.textLow,
              ),
              const SizedBox(width: 4),
              Text(
                [
                  property.province,
                  if (property.region.isNotEmpty) property.region,
                ].join('، '),
                style: const TextStyle(
                  fontSize: AppTheme.fontMd,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
          // Price
          if (property.price > 0) ...[
            const SizedBox(height: AppTheme.sp16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isOffer ? 'السعر:' : 'الميزانية:',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSm,
                    color: AppTheme.textLow,
                  ),
                ),
                const SizedBox(width: AppTheme.sp8),
                Text(
                  _formatPrice(property.price),
                  style: TextStyle(
                    fontSize: AppTheme.font2xl,
                    fontWeight: FontWeight.w800,
                    color: entryColor,
                    height: 1,
                  ),
                ),
                const SizedBox(width: AppTheme.sp4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    property.currency,
                    style: TextStyle(
                      fontSize: AppTheme.fontSm,
                      color: entryColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Specs Grid (area, rooms, floor) ──────────────────────────────────────────
class _SpecsGrid extends StatelessWidget {
  final PropertyModel property;
  const _SpecsGrid({required this.property});

  @override
  Widget build(BuildContext context) {
    final specs = <_SpecData>[];
    if (property.area > 0) {
      specs.add(_SpecData(
        icon: Icons.straighten_rounded,
        label: 'المساحة',
        value: '${property.area.toStringAsFixed(0)} م²',
      ));
    }
    if (property.rooms > 0) {
      specs.add(_SpecData(
        icon: Icons.bed_rounded,
        label: 'الغرف',
        value: '${property.rooms}',
      ));
    }
    if (property.floor.isNotEmpty) {
      specs.add(_SpecData(
        icon: Icons.layers_rounded,
        label: 'الطابق',
        value: property.floor,
      ));
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            specs.map((s) => Expanded(child: _SpecCell(data: s))).toList(),
      ),
    );
  }
}

class _SpecData {
  final IconData icon;
  final String label;
  final String value;
  const _SpecData(
      {required this.icon, required this.label, required this.value});
}

class _SpecCell extends StatelessWidget {
  final _SpecData data;
  const _SpecCell({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.sp8),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(data.icon, size: 20, color: AppTheme.accentGreen),
        ),
        const SizedBox(height: AppTheme.sp8),
        Text(
          data.value,
          style: const TextStyle(
            fontSize: AppTheme.fontLg,
            fontWeight: FontWeight.w700,
            color: AppTheme.textHigh,
          ),
        ),
        Text(
          data.label,
          style: const TextStyle(
            fontSize: AppTheme.fontXs,
            color: AppTheme.textLow,
          ),
        ),
      ],
    );
  }
}

// ── Detail Section ────────────────────────────────────────────────────────────
class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppTheme.sp8,
              top: AppTheme.sp4,
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: AppTheme.sp8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: children
                  .asMap()
                  .entries
                  .map((e) => Column(
                        children: [
                          e.value,
                          if (e.key < children.length - 1)
                            const Divider(
                              height: 1,
                              indent: AppTheme.sp16,
                              endIndent: AppTheme.sp16,
                            ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp16,
        vertical: AppTheme.sp12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.textLow),
          const SizedBox(width: AppTheme.sp12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppTheme.fontSm,
                color: AppTheme.textLow,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.fontMd,
                color: valueColor ?? AppTheme.textHigh,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Features Section ──────────────────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  final List<String> features;
  final Color color;
  const _FeaturesSection({required this.features, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.sp8),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 15, color: color),
                const SizedBox(width: AppTheme.sp8),
                Text(
                  'الميزات',
                  style: TextStyle(
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppTheme.sp8,
            runSpacing: AppTheme.sp8,
            children: features
                .map(
                  (f) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp12,
                      vertical: AppTheme.sp8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          f,
                          style: TextStyle(
                            color: color,
                            fontSize: AppTheme.fontXs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Contact Section ───────────────────────────────────────────────────────────
class _ContactSection extends StatelessWidget {
  final PropertyModel property;
  final bool isOffer;
  final Color entryColor;
  const _ContactSection({
    required this.property,
    required this.isOffer,
    required this.entryColor,
  });

  void _copyToClipboard(BuildContext ctx, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('تم نسخ: $value'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasContact = property.ownerName.isNotEmpty ||
        property.contactPhone.isNotEmpty ||
        property.ownerWhatsapp.isNotEmpty ||
        (isOffer && property.officeName.isNotEmpty);

    if (!hasContact) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.sp8),
            child: Row(
              children: [
                Icon(Icons.contact_page_rounded, size: 15, color: entryColor),
                const SizedBox(width: AppTheme.sp8),
                Text(
                  isOffer ? 'معلومات التواصل (خاصة)' : 'معلومات الباحث',
                  style: TextStyle(
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w700,
                    color: entryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (property.ownerName.isNotEmpty)
                  _ContactRow(
                    icon: Icons.person_rounded,
                    label: isOffer ? 'المالك' : 'الباحث',
                    value: property.ownerName,
                    onTap: () => _copyToClipboard(context, property.ownerName),
                  ),
                if (property.ownerName.isNotEmpty &&
                    (property.contactPhone.isNotEmpty ||
                        property.ownerWhatsapp.isNotEmpty))
                  const Divider(
                      height: 1,
                      indent: AppTheme.sp16,
                      endIndent: AppTheme.sp16),
                if (property.contactPhone.isNotEmpty)
                  _ContactRow(
                    icon: Icons.phone_rounded,
                    label: 'الهاتف',
                    value: property.contactPhone,
                    actionIcon: Icons.copy_rounded,
                    onTap: () =>
                        _copyToClipboard(context, property.contactPhone),
                  ),
                if (property.contactPhone.isNotEmpty &&
                    property.ownerWhatsapp.isNotEmpty)
                  const Divider(
                      height: 1,
                      indent: AppTheme.sp16,
                      endIndent: AppTheme.sp16),
                if (property.ownerWhatsapp.isNotEmpty)
                  _ContactRow(
                    icon: Icons.chat_rounded,
                    label: 'واتساب',
                    value: property.ownerWhatsapp,
                    actionIcon: Icons.copy_rounded,
                    iconColor: const Color(0xFF25D366),
                    onTap: () =>
                        _copyToClipboard(context, property.ownerWhatsapp),
                  ),
                if (isOffer && property.officeName.isNotEmpty) ...[
                  const Divider(
                      height: 1,
                      indent: AppTheme.sp16,
                      endIndent: AppTheme.sp16),
                  _ContactRow(
                    icon: Icons.business_rounded,
                    label: 'المكتب',
                    value: property.officeName,
                    onTap: () => _copyToClipboard(context, property.officeName),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData? actionIcon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actionIcon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp16,
          vertical: AppTheme.sp12,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor ?? AppTheme.textMedium),
            const SizedBox(width: AppTheme.sp12),
            SizedBox(
              width: 70,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: AppTheme.fontSm,
                  color: AppTheme.textLow,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: AppTheme.fontMd,
                  color: AppTheme.textHigh,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (actionIcon != null)
              Icon(actionIcon, size: 14, color: AppTheme.textLow),
          ],
        ),
      ),
    );
  }
}

// ── Notes Section ─────────────────────────────────────────────────────────────
class _NotesSection extends StatelessWidget {
  final String notes;
  final Color color;
  const _NotesSection({required this.notes, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.sp8),
            child: Row(
              children: [
                Icon(Icons.notes_rounded, size: 15, color: color),
                const SizedBox(width: AppTheme.sp8),
                Text(
                  'ملاحظات',
                  style: TextStyle(
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.sp16),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Text(
              notes,
              style: const TextStyle(
                fontSize: AppTheme.fontMd,
                color: AppTheme.textMedium,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
