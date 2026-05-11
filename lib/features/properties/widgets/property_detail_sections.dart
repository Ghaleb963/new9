import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:io';
import '../models/property_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';

class AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const AppBarAction({
    super.key,
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

class ImageGallery extends StatefulWidget {
  final List<String> images;
  const ImageGallery({super.key, required this.images});

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
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
                        : Colors.white.withValues(alpha: 0.4),
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

class HeroHeader extends StatelessWidget {
  final PropertyModel property;
  final Color entryColor;
  const HeroHeader(
      {super.key, required this.property, required this.entryColor});

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
            entryColor.withValues(alpha: 0.06),
            AppTheme.bgPage,
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp12,
              vertical: AppTheme.sp4,
            ),
            decoration: BoxDecoration(
              color: entryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: entryColor.withValues(alpha: 0.35),
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
                    fontWeight: AppTheme.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.sp12),
          Text(
            '${property.propertyType} — ${property.adType}',
            style: const TextStyle(
              fontSize: AppTheme.font2xl,
              fontWeight: AppTheme.w800,
              color: AppTheme.textHigh,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppTheme.sp8),
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
                  PriceFormatter.format(property.price, precision: 2),
                  style: TextStyle(
                    fontSize: AppTheme.font2xl,
                    fontWeight: AppTheme.w800,
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
                      color: entryColor.withValues(alpha: 0.6),
                      fontWeight: AppTheme.w600,
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

class SpecData {
  final IconData icon;
  final String label;
  final String value;
  const SpecData(
      {required this.icon, required this.label, required this.value});
}

class SpecsGrid extends StatelessWidget {
  final PropertyModel property;
  const SpecsGrid({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final specs = <SpecData>[];
    if (property.area > 0) {
      specs.add(SpecData(
        icon: Icons.straighten_rounded,
        label: 'المساحة',
        value: '${property.area.toStringAsFixed(0)} م²',
      ));
    }
    if (property.rooms > 0) {
      specs.add(SpecData(
        icon: Icons.bed_rounded,
        label: 'الغرف',
        value: '${property.rooms}',
      ));
    }
    if (property.floor.isNotEmpty) {
      specs.add(SpecData(
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
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: specs.map((s) => Expanded(child: SpecCell(data: s))).toList(),
      ),
    );
  }
}

class SpecCell extends StatelessWidget {
  final SpecData data;
  const SpecCell({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.sp8),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(data.icon, size: 20, color: AppTheme.accentGreen),
        ),
        const SizedBox(height: AppTheme.sp8),
        Text(
          data.value,
          style: const TextStyle(
            fontSize: AppTheme.fontLg,
            fontWeight: AppTheme.w700,
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

class DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const DetailSection({
    super.key,
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
                    fontWeight: AppTheme.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
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

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const InfoRow({
    super.key,
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
                fontWeight: AppTheme.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.fontMd,
                color: valueColor ?? AppTheme.textHigh,
                fontWeight: AppTheme.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeaturesSection extends StatelessWidget {
  final List<String> features;
  final Color color;
  const FeaturesSection(
      {super.key, required this.features, required this.color});

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
                    fontWeight: AppTheme.w700,
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
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: 0.5,
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
                            fontWeight: AppTheme.w600,
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

class ContactSection extends StatelessWidget {
  final PropertyModel property;
  final bool isOffer;
  final Color entryColor;
  const ContactSection({
    super.key,
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
                    fontWeight: AppTheme.w700,
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
              border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (property.ownerName.isNotEmpty)
                  ContactRow(
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
                  ContactRow(
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
                  ContactRow(
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
                  ContactRow(
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

class ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData? actionIcon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const ContactRow({
    super.key,
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
                  fontWeight: AppTheme.w500,
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

class NotesSection extends StatelessWidget {
  final String notes;
  final Color color;
  const NotesSection({super.key, required this.notes, required this.color});

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
                    fontWeight: AppTheme.w700,
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
              border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
            ),
            child: Text(
              notes,
              style: const TextStyle(
                fontSize: AppTheme.fontMd,
                color: AppTheme.textMedium,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
