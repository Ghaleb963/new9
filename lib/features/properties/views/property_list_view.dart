import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../widgets/property_card.dart';
import '../widgets/filter_widgets.dart';

class PropertyListView extends StatefulWidget {
  const PropertyListView({super.key});

  @override
  State<PropertyListView> createState() => _PropertyListViewState();
}

class _PropertyListViewState extends State<PropertyListView> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val, WidgetRef ref) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(propertyFilterProvider.notifier).update(
            (s) => s.copyWith(query: val),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.sp16,
                  0,
                  AppTheme.sp16,
                  AppTheme.sp12,
                ),
                child: _SearchBar(onSearchChanged: _onSearchChanged),
              ),
            ),
          ),
          body: Column(
            children: [
              const _StatsBar(),
              const _EntryTypeTabBar(),
              Expanded(
                child: ref.watch(filteredPropertiesProvider).when(
                  data: (filteredProperties) {
                    if (filteredProperties.isEmpty) {
                      return _buildEmptyState(activeFilterCount, ref);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        top: AppTheme.sp8,
                        bottom: AppTheme.sp24,
                      ),
                      cacheExtent: 600,
                      itemCount: filteredProperties.length,
                      itemBuilder: (context, index) {
                        return PropertyCard(
                          property: filteredProperties[index],
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => _buildEmptyState(activeFilterCount, ref),
                ),
              ),
            ],
          ),
        );
      },
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
        builder: (context, sc) => FilterContent(scrollController: sc),
      ),
    );
  }
}

// ── Search Bar ──────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final void Function(String, WidgetRef) onSearchChanged;
  const _SearchBar({required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
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
            onChanged: (val) => onSearchChanged(val, ref),
          ),
        );
      },
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

// ── Entry Type Tab Bar ──
class _EntryTypeTabBar extends ConsumerWidget {
  const _EntryTypeTabBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      propertyFilterProvider.select((f) => f.selectedEntryType),
    );

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

// ── Stats Bar ──
class _StatsBar extends ConsumerWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(propertyStatsProvider);
    if (stats.total == 0) return const SizedBox.shrink();

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
          _StatChip(
              label: 'الكل', value: stats.total, color: AppTheme.textMedium),
          const _Divider(),
          _StatChip(
              label: 'عروض', value: stats.offers, color: AppTheme.accentGreen),
          const _Divider(),
          _StatChip(
              label: 'طلبات',
              value: stats.requirements,
              color: AppTheme.accentAmber),
          const _Divider(),
          _StatChip(
              label: 'متاح',
              value: stats.available,
              color: AppTheme.accentTeal),
          const _Divider(),
          _StatChip(
              label: 'مباع', value: stats.sold, color: AppTheme.accentRed),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

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

// ── Empty State ───────────────────────────────────────────────────────────────
Widget _buildEmptyState(int activeFilterCount, WidgetRef ref) {
  return AppEmptyState(
    icon: Icons.home_work_outlined,
    title:
        activeFilterCount > 0 ? 'لا نتائج تطابق الفلتر' : 'لا توجد سجلات بعد',
    subtitle: activeFilterCount > 0
        ? 'جرّب تعديل معايير الفلترة'
        : 'اضغط "إضافة" لتسجيل أول عقار أو طلب',
    action: activeFilterCount > 0
        ? TextButton.icon(
            onPressed: () => ref.read(propertyFilterProvider.notifier).state =
                const PropertyFilter(),
            icon: const Icon(Icons.clear_all_rounded, size: 18),
            label: const Text('مسح الفلاتر'),
          )
        : null,
  );
}
