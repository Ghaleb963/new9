import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_detail_widgets.dart';

class FilterContent extends ConsumerWidget {
  final ScrollController scrollController;

  const FilterContent({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(propertyFilterProvider);

    return Column(
      children: [
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
              bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
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
                      fontWeight: AppTheme.w700,
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
                      child: ToggleTile(
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
                      child: ToggleTile(
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

class ToggleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  const ToggleTile({
    super.key,
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
              ? AppTheme.accentGreen.withValues(alpha: 0.10)
              : AppTheme.bgRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isOn
                ? AppTheme.accentGreen.withValues(alpha: 0.35)
                : AppTheme.borderMedium,
            width: isOn ? 1.5 : 0.5,
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
                fontWeight: isOn ? AppTheme.w700 : AppTheme.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
