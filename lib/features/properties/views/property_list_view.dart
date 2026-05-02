import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_provider.dart';
import '../models/property_model.dart';
import 'property_detail_view.dart';
import 'dart:io';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_helpers.dart';
import '../../../core/widgets/app_detail_widgets.dart';
import '../../../core/widgets/app_image_widgets.dart';

class PropertyListView extends ConsumerWidget {
  const PropertyListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProperties = ref.watch(filteredPropertiesProvider);
    final filter = ref.watch(propertyFilterProvider);
    final activeFilterCount = _countActiveFilters(filter);

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPage,
        title: const Text('عقاراتي'),
        actions: [
          _FilterButton(
            count: activeFilterCount,
            onTap: () => _showFilterBottomSheet(context, ref),
          ),
          const SizedBox(width: AppTheme.sp8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.sp16,
              0,
              AppTheme.sp16,
              AppTheme.sp12,
            ),
            child: _SearchBar(),
          ),
        ),
      ),
      body: Column(
        children: [
          const _StatsBar(),
          const _EntryTypeTabBar(),
          Expanded(
            child: filteredProperties.isEmpty
                ? _EmptyListState(activeFilterCount: activeFilterCount)
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppTheme.sp8,
                      bottom: AppTheme.sp24,
                    ),
                    cacheExtent: 1200,
                    itemCount: filteredProperties.length,
                    itemBuilder: (context, index) {
                      return _PropertyCard(
                        property: filteredProperties[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _countActiveFilters(PropertyFilter filter) {
    int c = 0;
    if (filter.selectedEntryType != null) c++;
    if (filter.minPrice != null) c++;
    if (filter.maxPrice != null) c++;
    if (filter.selectedType != null) c++;
    if (filter.selectedOwnerStatus != null) c++;
    if (filter.selectedProvince != null) c++;
    if (filter.selectedAdType != null) c++;
    if (filter.selectedStatus != null) c++;
    if (filter.selectedFinishing != null) c++;
    if (filter.selectedFacade != null) c++;
    if (filter.selectedDeedType != null) c++;
    if (filter.minRooms != null) c++;
    if (filter.maxRooms != null) c++;
    if (filter.minArea != null) c++;
    if (filter.maxArea != null) c++;
    if (filter.selectedFloor != null && filter.selectedFloor!.isNotEmpty) c++;
    if (filter.hasGarden != null) c++;
    if (filter.isDuplex != null) c++;
    if (filter.selectedCurrency != null) c++;
    if (filter.selectedOwnership != null) c++;
    return c;
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, sc) => _FilterContent(scrollController: sc),
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: TextField(
        style: const TextStyle(
          color: AppTheme.textHigh,
          fontSize: AppTheme.fontMd,
        ),
        decoration: const InputDecoration(
          hintText: 'بحث بالمنطقة، النوع، المالك...',
          hintStyle:
              TextStyle(color: AppTheme.textLow, fontSize: AppTheme.fontSm),
          prefixIcon:
              Icon(Icons.search_rounded, color: AppTheme.textLow, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          filled: false,
        ),
        onChanged: (val) => ref.read(propertyFilterProvider.notifier).update(
              (s) => s.copyWith(query: val),
            ),
      ),
    );
  }
}

// ── Filter Button with badge ──────────────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: count > 0
                  ? AppTheme.accentGreen.withValues(alpha: 0.15)
                  : AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: count > 0
                    ? AppTheme.accentGreen.withValues(alpha: 0.4)
                    : AppTheme.borderSubtle,
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: count > 0 ? AppTheme.accentGreen : AppTheme.textMedium,
              size: 20,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              left: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: AppTheme.accentRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Entry Type Tab Bar ────────────────────────────────────────────────────────
class _EntryTypeTabBar extends ConsumerWidget {
  const _EntryTypeTabBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(propertyFilterProvider).selectedEntryType;

    return Container(
      color: AppTheme.bgPage,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.sp16,
        AppTheme.sp4,
        AppTheme.sp16,
        AppTheme.sp12,
      ),
      child: Row(
        children: [
          _TabChip(
            label: 'الكل',
            isSelected: selected == null,
            onTap: () => ref.read(propertyFilterProvider.notifier).update(
                  (s) => s.copyWith(selectedEntryType: () => null),
                ),
          ),
          const SizedBox(width: AppTheme.sp8),
          _TabChip(
            label: 'عروض',
            color: AppTheme.accentGreen,
            isSelected: selected == EntryType.offer,
            onTap: () => ref.read(propertyFilterProvider.notifier).update(
                  (s) => s.copyWith(selectedEntryType: () => EntryType.offer),
                ),
          ),
          const SizedBox(width: AppTheme.sp8),
          _TabChip(
            label: 'طلبات',
            color: AppTheme.accentAmber,
            isSelected: selected == EntryType.requirement,
            onTap: () => ref.read(propertyFilterProvider.notifier).update(
                  (s) => s.copyWith(
                      selectedEntryType: () => EntryType.requirement),
                ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    this.color = AppTheme.textHigh,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp16,
          vertical: AppTheme.sp8,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : AppTheme.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppTheme.textLow,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            fontSize: AppTheme.fontSm,
          ),
        ),
      ),
    );
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────
class _StatsBar extends ConsumerWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(propertyProvider);
    if (all.isEmpty) return const SizedBox.shrink();

    final total = all.length;
    final offers = all.where((p) => p.entryType == EntryType.offer).length;
    final reqs = all.where((p) => p.entryType == EntryType.requirement).length;
    final avail = all.where((p) => p.status == 'متاح').length;
    final sold = all.where((p) => p.status == 'مباع').length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp16,
        vertical: AppTheme.sp12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(label: 'الكل', value: total, color: AppTheme.textMedium),
          _Divider(),
          _StatChip(label: 'عروض', value: offers, color: AppTheme.accentGreen),
          _Divider(),
          _StatChip(label: 'طلبات', value: reqs, color: AppTheme.accentAmber),
          _Divider(),
          _StatChip(label: 'متاح', value: avail, color: AppTheme.accentTeal),
          _Divider(),
          _StatChip(label: 'مباع', value: sold, color: AppTheme.accentRed),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppTheme.borderSubtle,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: AppTheme.fontLg,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTheme.fontXs,
            color: AppTheme.textLow,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Property Card ─────────────────────────────────────────────────────────────
class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  const _PropertyCard({required this.property});

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
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
        boxShadow: AppTheme.shadowSm,
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
          highlightColor: entryColor.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Media section ──────────────────────────────────────
              _CardMedia(property: property, entryColor: entryColor),

              // ── Info section ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppTheme.sp16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row: type + ad type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${property.propertyType} — ${property.adType}',
                            style: const TextStyle(
                              fontSize: AppTheme.fontLg,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textHigh,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOffer && property.price > 0) ...[
                          const SizedBox(width: AppTheme.sp8),
                          _PriceTag(
                            price: property.price,
                            currency: property.currency,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppTheme.sp8),
                    // Location row
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
                    // Specs row (area / rooms)
                    if (property.area > 0 || property.rooms > 0) ...[
                      const SizedBox(height: AppTheme.sp8),
                      _SpecsRow(property: property),
                    ],
                    // Budget tag for requirements
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
                            'ميزانية: ${_formatPrice(property.price)} ${property.currency}',
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

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}م';
    }
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}ك';
    }
    return price.toStringAsFixed(0);
  }
}

// ── Card Media (image or requirement placeholder) ─────────────────────────────
class _CardMedia extends StatelessWidget {
  final PropertyModel property;
  final Color entryColor;
  const _CardMedia({required this.property, required this.entryColor});

  @override
  Widget build(BuildContext context) {
    final isOffer = property.entryType == EntryType.offer;

    return Stack(
      children: [
        // Image or placeholder
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
                : _PlaceholderMedia(
                    isOffer: isOffer,
                    entryColor: entryColor,
                    propertyType: property.propertyType,
                  ),
          ),
        ),
        // Gradient overlay (for images) for text readability
        if (isOffer && property.images.isNotEmpty)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
        // Entry type badge (top right in RTL = top start)
        Positioned(
          top: AppTheme.sp8,
          right: AppTheme.sp8,
          child: _EntryBadge(
            isOffer: isOffer,
            color: entryColor,
          ),
        ),
        // Status badge (top left in RTL = top end)
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

class _PlaceholderMedia extends StatelessWidget {
  final bool isOffer;
  final Color entryColor;
  final String propertyType;
  const _PlaceholderMedia({
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
            entryColor.withValues(alpha: 0.12),
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
              size: 44,
              color: entryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.sp8),
            Text(
              propertyType,
              style: TextStyle(
                color: entryColor.withValues(alpha: 0.6),
                fontSize: AppTheme.fontSm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryBadge extends StatelessWidget {
  final bool isOffer;
  final Color color;
  const _EntryBadge({required this.isOffer, required this.color});

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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Specs Row (area + rooms) ──────────────────────────────────────────────────
class _SpecsRow extends StatelessWidget {
  final PropertyModel property;
  const _SpecsRow({required this.property});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (property.area > 0)
          _SpecItem(
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
          _SpecItem(
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
          _SpecItem(
            icon: Icons.layers_rounded,
            label: 'ط ${property.floor}',
          ),
        ],
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecItem({required this.icon, required this.label});

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

// ── Price Tag ─────────────────────────────────────────────────────────────────
class _PriceTag extends StatelessWidget {
  final double price;
  final String currency;
  const _PriceTag({required this.price, required this.currency});

  String get _formatted {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}م';
    }
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}ك';
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '$_formatted $currency',
        style: const TextStyle(
          color: AppTheme.accentGreen,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyListState extends ConsumerWidget {
  final int activeFilterCount;
  const _EmptyListState({required this.activeFilterCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.sp40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.sp24),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 48,
                color: AppTheme.textLow,
              ),
            ),
            const SizedBox(height: AppTheme.sp20),
            Text(
              activeFilterCount > 0
                  ? 'لا نتائج تطابق الفلتر'
                  : 'لا توجد سجلات بعد',
              style: const TextStyle(
                fontSize: AppTheme.fontXl,
                fontWeight: FontWeight.w700,
                color: AppTheme.textHigh,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.sp8),
            Text(
              activeFilterCount > 0
                  ? 'جرّب تعديل معايير الفلترة'
                  : 'اضغط "إضافة" لتسجيل أول عقار أو طلب',
              style: const TextStyle(
                fontSize: AppTheme.fontMd,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (activeFilterCount > 0) ...[
              const SizedBox(height: AppTheme.sp20),
              TextButton.icon(
                onPressed: () => ref
                    .read(propertyFilterProvider.notifier)
                    .state = const PropertyFilter(),
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('مسح الفلاتر'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Filter Bottom Sheet Content ───────────────────────────────────────────────
class _FilterContent extends ConsumerWidget {
  final ScrollController scrollController;
  const _FilterContent({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(propertyFilterProvider);

    return Column(
      children: [
        // Handle + Header
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.sp20,
            AppTheme.sp12,
            AppTheme.sp20,
            AppTheme.sp8,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
            border: Border(
              bottom: BorderSide(color: AppTheme.borderSubtle),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.sp12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'فلترة متقدمة',
                    style: TextStyle(
                      fontSize: AppTheme.fontXl,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textHigh,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(propertyFilterProvider.notifier).state =
                          const PropertyFilter();
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('إعادة تعيين'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Filter options
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp20,
              vertical: AppTheme.sp8,
            ),
            children: [
              AppFilterSection(title: 'نوع السجل', children: [
                AppChoiceChips(
                  items: EntryType.values.map((e) => e.label).toList(),
                  selected: filter.selectedEntryType?.label,
                  onSelected: (val) {
                    final type = val == null
                        ? null
                        : EntryType.values.firstWhere((e) => e.label == val);
                    ref.read(propertyFilterProvider.notifier).update(
                          (s) => s.copyWith(selectedEntryType: () => type),
                        );
                  },
                ),
              ]),
              AppFilterSection(title: 'نوع الإعلان', children: [
                AppChoiceChips(
                  items: AppConstants.adTypes,
                  selected: filter.selectedAdType,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedAdType: () => v)),
                ),
              ]),
              AppFilterSection(title: 'نوع العقار', children: [
                AppChoiceChips(
                  items: AppConstants.propertyTypes,
                  selected: filter.selectedType,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedType: () => v)),
                ),
              ]),
              AppFilterSection(title: 'المحافظة', children: [
                AppChoiceChips(
                  items: AppConstants.provinces,
                  selected: filter.selectedProvince,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedProvince: () => v)),
                ),
              ]),
              AppFilterSection(title: 'حالة العقار', children: [
                AppChoiceChips(
                  items: AppConstants.statusList,
                  selected: filter.selectedStatus,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedStatus: () => v)),
                ),
              ]),
              AppFilterSection(title: 'نطاق السعر', children: [
                AppRangeFilter(
                  fromHint: 'الحد الأدنى',
                  toHint: 'الحد الأعلى',
                  onFromChanged: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) =>
                          s.copyWith(minPrice: () => double.tryParse(v))),
                  onToChanged: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) =>
                          s.copyWith(maxPrice: () => double.tryParse(v))),
                ),
              ]),
              AppFilterSection(title: 'العملة', children: [
                AppChoiceChips(
                  items: AppConstants.currencies,
                  selected: filter.selectedCurrency,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedCurrency: () => v)),
                ),
              ]),
              AppFilterSection(title: 'عدد الغرف', children: [
                AppRangeFilter(
                  fromHint: 'من',
                  toHint: 'إلى',
                  onFromChanged: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update(
                          (s) => s.copyWith(minRooms: () => int.tryParse(v))),
                  onToChanged: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update(
                          (s) => s.copyWith(maxRooms: () => int.tryParse(v))),
                ),
              ]),
              AppFilterSection(title: 'المساحة (م²)', children: [
                AppRangeFilter(
                  fromHint: 'من م²',
                  toHint: 'إلى م²',
                  onFromChanged: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update(
                          (s) => s.copyWith(minArea: () => double.tryParse(v))),
                  onToChanged: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update(
                          (s) => s.copyWith(maxArea: () => double.tryParse(v))),
                ),
              ]),
              AppFilterSection(title: 'نوع السند', children: [
                AppChoiceChips(
                  items: AppConstants.deedTypes,
                  selected: filter.selectedDeedType,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedDeedType: () => v)),
                ),
              ]),
              AppFilterSection(title: 'الواجهة', children: [
                AppChoiceChips(
                  items: AppConstants.facadeTypes,
                  selected: filter.selectedFacade,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedFacade: () => v)),
                ),
              ]),
              AppFilterSection(title: 'مستوى الإكساء', children: [
                AppChoiceChips(
                  items: AppConstants.finishingLevels,
                  selected: filter.selectedFinishing,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedFinishing: () => v)),
                ),
              ]),
              AppFilterSection(title: 'نوع الملكية', children: [
                AppChoiceChips(
                  items: AppConstants.ownershipTypes,
                  selected: filter.selectedOwnership,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedOwnership: () => v)),
                ),
              ]),
              AppFilterSection(title: 'حالة الملكية', children: [
                AppChoiceChips(
                  items: AppConstants.ownerStatuses,
                  selected: filter.selectedOwnerStatus,
                  onSelected: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(selectedOwnerStatus: () => v)),
                ),
              ]),
              AppFilterSection(title: 'الطابق', children: [
                TextField(
                  style: const TextStyle(
                    color: AppTheme.textHigh,
                    fontSize: AppTheme.fontMd,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'مثال: أرضي، 1، 2...',
                  ),
                  onChanged: (v) => ref
                      .read(propertyFilterProvider.notifier)
                      .update((s) => s.copyWith(
                          selectedFloor: () => v.isEmpty ? null : v)),
                ),
              ]),
              AppFilterSection(title: 'خصائص إضافية', children: [
                Row(
                  children: [
                    Expanded(
                      child: _ToggleTile(
                        label: 'حديقة',
                        icon: Icons.park_rounded,
                        value: filter.hasGarden,
                        onChanged: (v) => ref
                            .read(propertyFilterProvider.notifier)
                            .update((s) => s.copyWith(
                                hasGarden: () => v == true ? true : null)),
                      ),
                    ),
                    const SizedBox(width: AppTheme.sp8),
                    Expanded(
                      child: _ToggleTile(
                        label: 'دوبلكس',
                        icon: Icons.stairs_rounded,
                        value: filter.isDuplex,
                        onChanged: (v) => ref
                            .read(propertyFilterProvider.notifier)
                            .update((s) => s.copyWith(
                                isDuplex: () => v == true ? true : null)),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: AppTheme.sp16),
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('تطبيق الفلاتر'),
                ),
              ),
              const SizedBox(height: AppTheme.sp32),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Toggle Tile for filters ───────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  const _ToggleTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = value == true;
    return GestureDetector(
      onTap: () => onChanged(isOn ? null : true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp12,
          vertical: AppTheme.sp12,
        ),
        decoration: BoxDecoration(
          color: isOn
              ? AppTheme.accentGreen.withValues(alpha: 0.12)
              : AppTheme.bgRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isOn
                ? AppTheme.accentGreen.withValues(alpha: 0.4)
                : AppTheme.borderMedium,
            width: isOn ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isOn ? AppTheme.accentGreen : AppTheme.textLow,
            ),
            const SizedBox(width: AppTheme.sp8),
            Text(
              label,
              style: TextStyle(
                color: isOn ? AppTheme.accentGreen : AppTheme.textMedium,
                fontSize: AppTheme.fontSm,
                fontWeight: isOn ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
