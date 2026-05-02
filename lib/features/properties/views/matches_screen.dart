import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_provider.dart';
import '../services/matching_service.dart';
import '../models/property_model.dart';
import 'property_detail_view.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

// ════════════════════════════════════════════════════════
// MatchesScreen — لوحة التوافقات الدائمة (مُعاد تصميمها)
//
// تعرض جميع أزواج (عرض ↔ طلب) المتوافقة في الوقت الفعلي.
// تتحدث تلقائياً عند أي تغيير في البيانات عبر allMatchesProvider.
// ════════════════════════════════════════════════════════
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  _ScoreFilter _scoreFilter = _ScoreFilter.all;
  String? _selectedProvince;

  @override
  Widget build(BuildContext context) {
    final allMatches = ref.watch(allMatchesProvider);
    final filtered = _applyFilters(allMatches);

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ─────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.bgPage,
            expandedHeight: allMatches.isEmpty ? 60 : 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(
                AppTheme.sp16,
                0,
                AppTheme.sp16,
                AppTheme.sp12,
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    color: AppTheme.accentGreen,
                    size: 18,
                  ),
                  const SizedBox(width: AppTheme.sp8),
                  const Text(
                    'لوحة التوافقات',
                    style: TextStyle(fontSize: AppTheme.fontLg),
                  ),
                  const Spacer(),
                  if (allMatches.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sp8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(
                          color: AppTheme.accentGreen.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${allMatches.length} توافق',
                        style: const TextStyle(
                          fontSize: AppTheme.fontXs,
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.bgPage, AppTheme.bgPage],
                  ),
                ),
                child: allMatches.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.sp16,
                          AppTheme.sp16,
                          AppTheme.sp16,
                          56,
                        ),
                        child: _StatsRow(matches: allMatches),
                      ),
              ),
            ),
          ),

          // ── شريط الفلاتر ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterBar(
              scoreFilter: _scoreFilter,
              selectedProvince: _selectedProvince,
              onScoreChanged: (f) => setState(() => _scoreFilter = f),
              onProvinceChanged: (p) => setState(() => _selectedProvince = p),
              availableProvinces: _extractProvinces(allMatches),
            ),
          ),

          // ── حالة فارغة ─────────────────────────────────────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(hasData: allMatches.isNotEmpty),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.sp16,
                  AppTheme.sp8,
                  AppTheme.sp16,
                  4,
                ),
                child: Text(
                  'يعرض ${filtered.length} من ${allMatches.length} توافق',
                  style: const TextStyle(
                    fontSize: AppTheme.fontXs,
                    color: AppTheme.textLow,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _MatchPairCard(
                  match: filtered[index],
                  index: index,
                ),
                childCount: filtered.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.sp32)),
          ],
        ],
      ),
    );
  }

  List<MatchResult> _applyFilters(List<MatchResult> all) {
    return all.where((m) {
      switch (_scoreFilter) {
        case _ScoreFilter.excellent:
          if (m.score < 0.85) return false;
          break;
        case _ScoreFilter.good:
          if (m.score < 0.70 || m.score >= 0.85) return false;
          break;
        case _ScoreFilter.partial:
          if (m.score >= 0.70) return false;
          break;
        case _ScoreFilter.all:
          break;
      }
      if (_selectedProvince != null && m.offer.province != _selectedProvince) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> _extractProvinces(List<MatchResult> matches) {
    return matches.map((m) => m.offer.province).toSet().toList()..sort();
  }
}

// ── تعداد فلتر الدرجة ────────────────────────────────────────────────────────
enum _ScoreFilter { all, excellent, good, partial }

extension _ScoreFilterExt on _ScoreFilter {
  String get label {
    switch (this) {
      case _ScoreFilter.all:
        return 'الكل';
      case _ScoreFilter.excellent:
        return 'ممتاز ≥85%';
      case _ScoreFilter.good:
        return 'جيد 70-84%';
      case _ScoreFilter.partial:
        return 'جزئي <70%';
    }
  }

  Color get color {
    switch (this) {
      case _ScoreFilter.all:
        return AppTheme.textHigh;
      case _ScoreFilter.excellent:
        return AppTheme.accentGreen;
      case _ScoreFilter.good:
        return AppTheme.accentGreenGlow;
      case _ScoreFilter.partial:
        return AppTheme.accentAmber;
    }
  }
}

// ── شريط الإحصائيات ──────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<MatchResult> matches;
  const _StatsRow({required this.matches});

  @override
  Widget build(BuildContext context) {
    final excellent = matches.where((m) => m.score >= 0.85).length;
    final good = matches.where((m) => m.score >= 0.70 && m.score < 0.85).length;
    final partial = matches.where((m) => m.score < 0.70).length;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: AppTheme.sp8,
        children: [
          _StatBadge(
              label: 'ممتاز', count: excellent, color: AppTheme.accentGreen),
          _StatBadge(
              label: 'جيد', count: good, color: AppTheme.accentGreenGlow),
          _StatBadge(
              label: 'جزئي', count: partial, color: AppTheme.accentAmber),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp10,
        vertical: AppTheme.sp4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontXs,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── شريط الفلاتر ──────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final _ScoreFilter scoreFilter;
  final String? selectedProvince;
  final List<String> availableProvinces;
  final void Function(_ScoreFilter) onScoreChanged;
  final void Function(String?) onProvinceChanged;

  const _FilterBar({
    required this.scoreFilter,
    required this.selectedProvince,
    required this.availableProvinces,
    required this.onScoreChanged,
    required this.onProvinceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // فلاتر الدرجة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.sp16,
              AppTheme.sp10,
              AppTheme.sp16,
              AppTheme.sp4,
            ),
            child: Row(
              children: _ScoreFilter.values.map((f) {
                final isSelected = scoreFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(left: AppTheme.sp8),
                  child: GestureDetector(
                    onTap: () => onScoreChanged(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sp12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? f.color.withValues(alpha: 0.15)
                            : AppTheme.bgRaised,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(
                          color: isSelected
                              ? f.color.withValues(alpha: 0.6)
                              : AppTheme.borderMedium,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        f.label,
                        style: TextStyle(
                          color: isSelected ? f.color : AppTheme.textLow,
                          fontSize: AppTheme.fontXs,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // فلتر المحافظة
          if (availableProvinces.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.sp16,
                AppTheme.sp4,
                AppTheme.sp16,
                AppTheme.sp10,
              ),
              child: Row(
                children: [
                  _ProvinceChip(
                    label: 'كل المحافظات',
                    isSelected: selectedProvince == null,
                    onTap: () => onProvinceChanged(null),
                  ),
                  ...availableProvinces.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: AppTheme.sp8),
                      child: _ProvinceChip(
                        label: p,
                        isSelected: selectedProvince == p,
                        onTap: () => onProvinceChanged(p),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: AppTheme.sp8),
          const Divider(height: 1, color: AppTheme.borderSubtle),
        ],
      ),
    );
  }
}

class _ProvinceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ProvinceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: AppTheme.sp8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp12,
          vertical: AppTheme.sp4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentBlue.withValues(alpha: 0.12)
              : AppTheme.bgRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentBlue.withValues(alpha: 0.5)
                : AppTheme.borderMedium,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentBlue : AppTheme.textLow,
            fontSize: AppTheme.fontXs,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── بطاقة زوج التوافق ────────────────────────────────────────────────────────
class _MatchPairCard extends StatelessWidget {
  final MatchResult match;
  final int index;
  const _MatchPairCard({required this.match, required this.index});

  Color _scoreColor(double s) {
    if (s >= 0.85) return AppTheme.accentGreen;
    if (s >= 0.70) return AppTheme.accentGreenGlow;
    return AppTheme.accentAmber;
  }

  @override
  Widget build(BuildContext context) {
    final sc = _scoreColor(match.score);

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
        border: Border.all(color: sc.withValues(alpha: 0.22), width: 1),
        boxShadow: AppTheme.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── رأس البطاقة ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp14,
              vertical: AppTheme.sp10,
            ),
            color: sc.withValues(alpha: 0.07),
            child: Row(
              children: [
                // رقم التسلسل
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: sc,
                        fontSize: AppTheme.fontXs,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.sp10),
                // معايير التوافق
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.scoreLabel,
                        style: TextStyle(
                          color: sc,
                          fontWeight: FontWeight.w700,
                          fontSize: AppTheme.fontSm,
                        ),
                      ),
                      Wrap(
                        spacing: AppTheme.sp8,
                        children: match.matchedCriteria
                            .map((c) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_rounded,
                                        size: 10, color: AppTheme.accentGreen),
                                    const SizedBox(width: 2),
                                    Text(c,
                                        style: const TextStyle(
                                          fontSize: AppTheme.fontXs,
                                          color: AppTheme.textLow,
                                        )),
                                  ],
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                // دائرة النسبة
                _ScoreCircle(score: match.score, color: sc),
              ],
            ),
          ),

          // ── الجسم: عرض ↔ طلب ────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SidePanel(
                    property: match.offer,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PropertyDetailView(property: match.offer),
                      ),
                    ),
                  ),
                ),
                // فاصل مركزي
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: VerticalDivider(
                          color: sc.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.sp8),
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: sc,
                          size: 14,
                        ),
                      ),
                      Expanded(
                        child: VerticalDivider(
                          color: sc.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _SidePanel(
                    property: match.requirement,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PropertyDetailView(property: match.requirement),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── ذيل البطاقة: زرا الإجراء ────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.sp12,
              AppTheme.sp8,
              AppTheme.sp12,
              AppTheme.sp10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.bgRaised.withValues(alpha: 0.6),
              border: const Border(
                top: BorderSide(color: AppTheme.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'العرض',
                    icon: Icons.home_work_rounded,
                    color: AppTheme.accentGreen,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PropertyDetailView(property: match.offer),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.sp8),
                Expanded(
                  child: _ActionButton(
                    label: 'الطلب',
                    icon: Icons.search_rounded,
                    color: AppTheme.accentAmber,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PropertyDetailView(property: match.requirement),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── لوحة جانب واحد ───────────────────────────────────────────────────────────
class _SidePanel extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  const _SidePanel({required this.property, required this.onTap});

  String _formatPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}م';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}ك';
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isOffer = property.entryType == EntryType.offer;
    final color = isOffer ? AppTheme.accentGreen : AppTheme.accentAmber;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.sp12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نوع السجل
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                property.entryType.label,
                style: TextStyle(
                  fontSize: AppTheme.fontXs,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.sp4),
            // نوع العقار
            Text(
              property.propertyType,
              style: const TextStyle(
                fontSize: AppTheme.fontSm,
                fontWeight: FontWeight.w700,
                color: AppTheme.textHigh,
              ),
            ),
            // المنطقة
            Text(
              property.province,
              style: const TextStyle(
                fontSize: AppTheme.fontXs,
                color: AppTheme.textMedium,
              ),
            ),
            if (property.region.isNotEmpty)
              Text(
                property.region,
                style: const TextStyle(
                  fontSize: AppTheme.fontXs,
                  color: AppTheme.textLow,
                ),
              ),
            const SizedBox(height: AppTheme.sp4),
            // السعر أو الميزانية
            if (property.price > 0)
              Text(
                '${_formatPrice(property.price)} ${property.currency}',
                style: TextStyle(
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── دائرة النسبة ─────────────────────────────────────────────────────────────
class _ScoreCircle extends StatelessWidget {
  final double score;
  final Color color;
  const _ScoreCircle({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${(score * 100).toInt()}',
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            '%',
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 8,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── زر الإجراء ───────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.sp8,
            horizontal: AppTheme.sp12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppTheme.sp4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: AppTheme.fontXs,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── الحالة الفارغة ───────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasData;
  const _EmptyState({required this.hasData});

  @override
  Widget build(BuildContext context) {
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
                Icons.compare_arrows_rounded,
                size: 48,
                color: AppTheme.textLow,
              ),
            ),
            const SizedBox(height: AppTheme.sp20),
            Text(
              hasData ? 'لا نتائج تطابق الفلتر' : 'لا توجد توافقات بعد',
              style: const TextStyle(
                fontSize: AppTheme.fontXl,
                fontWeight: FontWeight.w700,
                color: AppTheme.textHigh,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.sp8),
            Text(
              hasData
                  ? 'جرّب تغيير معايير الفلترة'
                  : 'أضف عروضاً وطلبات، وسيجري النظام التوافق تلقائياً',
              style: const TextStyle(
                fontSize: AppTheme.fontMd,
                color: AppTheme.textMedium,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
