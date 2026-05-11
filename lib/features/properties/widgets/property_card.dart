import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:io';
import '../models/property_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_image_widgets.dart';
import '../../../core/widgets/status_helpers.dart';
import '../views/property_detail_view.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final isOffer = property.entryType == EntryType.offer;
    final entryColor = isOffer ? AppTheme.accentGreen : AppTheme.accentAmber;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.sp16,
        0,
        AppTheme.sp16,
        AppTheme.sp12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailView(property: property),
            ),
          ),
          splashColor: entryColor.withValues(alpha: 0.06),
          highlightColor: entryColor.withValues(alpha: 0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardMedia(property: property, entryColor: entryColor),
              Padding(
                padding: const EdgeInsets.all(AppTheme.sp16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${property.propertyType} — ${property.adType}',
                            style: const TextStyle(
                              fontSize: AppTheme.fontLg,
                              fontWeight: AppTheme.w700,
                              color: AppTheme.textHigh,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOffer && property.price > 0) ...[
                          const SizedBox(width: AppTheme.sp8),
                          PriceTag(
                            price: property.price,
                            currency: property.currency,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppTheme.sp8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppTheme.textLow,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              property.province,
                              if (property.region.isNotEmpty) property.region,
                            ].join('، '),
                            style: const TextStyle(
                              fontSize: AppTheme.fontSm,
                              color: AppTheme.textMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (property.area > 0 || property.rooms > 0) ...[
                      const SizedBox(height: AppTheme.sp8),
                      SpecsRow(property: property),
                    ],
                    if (!isOffer && property.price > 0) ...[
                      const SizedBox(height: AppTheme.sp8),
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 13,
                            color: AppTheme.textLow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ميزانية: ${PriceFormatter.format(property.price)} ${property.currency}',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSm,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardMedia extends StatelessWidget {
  final PropertyModel property;
  final Color entryColor;
  const CardMedia(
      {super.key, required this.property, required this.entryColor});

  @override
  Widget build(BuildContext context) {
    final isOffer = property.entryType == EntryType.offer;

    return Stack(
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: RepaintBoundary(
            child: isOffer && property.images.isNotEmpty
                ? Image.file(
                    File(property.images.first),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => const AppImagePlaceholder(),
                  )
                : PlaceholderMedia(
                    isOffer: isOffer,
                    entryColor: entryColor,
                    propertyType: property.propertyType,
                  ),
          ),
        ),
        if (isOffer && property.images.isNotEmpty)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        Positioned(
          top: AppTheme.sp8,
          right: AppTheme.sp8,
          child: EntryBadge(
            isOffer: isOffer,
            color: entryColor,
          ),
        ),
        if (isOffer)
          Positioned(
            top: AppTheme.sp8,
            left: AppTheme.sp8,
            child: StatusBadge(status: property.status),
          ),
      ],
    );
  }
}

class PlaceholderMedia extends StatelessWidget {
  final bool isOffer;
  final Color entryColor;
  final String propertyType;
  const PlaceholderMedia({
    super.key,
    required this.isOffer,
    required this.entryColor,
    required this.propertyType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            entryColor.withValues(alpha: 0.08),
            AppTheme.bgRaised,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffer ? Icons.home_work_outlined : Icons.search_rounded,
              size: 40,
              color: entryColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppTheme.sp8),
            Text(
              propertyType,
              style: TextStyle(
                color: entryColor.withValues(alpha: 0.5),
                fontSize: AppTheme.fontSm,
                fontWeight: AppTheme.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EntryBadge extends StatelessWidget {
  final bool isOffer;
  final Color color;
  const EntryBadge({super.key, required this.isOffer, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffer ? Icons.home_work_rounded : Icons.search_rounded,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isOffer ? 'عرض' : 'طلب',
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTheme.fontXs,
              fontWeight: AppTheme.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SpecsRow extends StatelessWidget {
  final PropertyModel property;
  const SpecsRow({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (property.area > 0)
          SpecItem(
            icon: Icons.straighten_rounded,
            label: '${property.area.toStringAsFixed(0)} م²',
          ),
        if (property.area > 0 && property.rooms > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.sp8),
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: AppTheme.textLow,
              shape: BoxShape.circle,
            ),
          ),
        if (property.rooms > 0)
          SpecItem(
            icon: Icons.bed_rounded,
            label: '${property.rooms} غرف',
          ),
        if (property.floor.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.sp8),
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: AppTheme.textLow,
              shape: BoxShape.circle,
            ),
          ),
          SpecItem(
            icon: Icons.layers_rounded,
            label: 'ط ${property.floor}',
          ),
        ],
      ],
    );
  }
}

class SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const SpecItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textLow),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTheme.fontXs,
            color: AppTheme.textMedium,
          ),
        ),
      ],
    );
  }
}

class PriceTag extends StatelessWidget {
  final double price;
  final String currency;
  const PriceTag({super.key, required this.price, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Text(
        '${PriceFormatter.format(price)} $currency',
        style: const TextStyle(
          color: AppTheme.accentGreen,
          fontSize: AppTheme.fontXs,
          fontWeight: AppTheme.w700,
        ),
      ),
    );
  }
}
