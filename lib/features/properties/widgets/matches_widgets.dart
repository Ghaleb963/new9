import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../services/matching_service.dart';
import '../models/property_model.dart';
import '../providers/matches_filter_provider.dart';
import '../views/property_detail_view.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/score_helpers.dart';

class StatsRow extends StatelessWidget {
  final List<MatchResult> matches;
  const StatsRow({super.key, required this.matches});

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
          StatBadge(
              label: 'ممتاز', count: excellent, color: AppTheme.accentGreen),
          StatBadge(label: 'جيد', count: good, color: AppTheme.accentGreenGlow),
          StatBadge(label: 'جزئي', count: partial, color: AppTheme.accentAmber),
        ],
      ),
    );
  }
}

class StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const StatBadge(
      {super.key,
      required this.label,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp10,
        vertical: AppTheme.sp4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.5),
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
              fontWeight: AppTheme.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final ScoreFilter scoreFilter;
  final String? selectedProvince;
  final List<String> availableProvinces;
  final void Function(ScoreFilter) onScoreChanged;
  final void Function(String?) onProvinceChanged;

  const FilterBar({
    super.key,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.sp16,
              AppTheme.sp10,
              AppTheme.sp16,
              AppTheme.sp4,
            ),
            child: Row(
              children: ScoreFilter.values.map((f) {
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
                            ? f.color.withValues(alpha: 0.12)
                            : AppTheme.bgRaised,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(
                          color: isSelected
                              ? f.color.withValues(alpha: 0.5)
                              : AppTheme.borderMedium,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        f.label,
                        style: TextStyle(
                          color: isSelected ? f.color : AppTheme.textLow,
                          fontSize: AppTheme.fontXs,
                          fontWeight:
                              isSelected ? AppTheme.w700 : AppTheme.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
                  ProvinceChip(
                    label: 'كل المحافظات',
                    isSelected: selectedProvince == null,
                    onTap: () => onProvinceChanged(null),
                  ),
                  ...availableProvinces.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: AppTheme.sp8),
                      child: ProvinceChip(
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

class ProvinceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const ProvinceChip({
    super.key,
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
              ? AppTheme.accentBlue.withValues(alpha: 0.10)
              : AppTheme.bgRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentBlue.withValues(alpha: 0.4)
                : AppTheme.borderMedium,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentBlue : AppTheme.textLow,
            fontSize: AppTheme.fontXs,
            fontWeight: isSelected ? AppTheme.w600 : AppTheme.w400,
          ),
        ),
      ),
    );
  }
}

class MatchPairCard extends StatelessWidget {
  final MatchResult match;
  final int index;
  const MatchPairCard({super.key, required this.match, required this.index});

  @override
  Widget build(BuildContext context) {
    final sc = ScoreHelpers.matchCardScoreColor(match.score);

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
        border: Border.all(color: sc.withValues(alpha: 0.18), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp14,
              vertical: AppTheme.sp10,
            ),
            color: sc.withValues(alpha: 0.05),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: sc,
                        fontSize: AppTheme.fontXs,
                        fontWeight: AppTheme.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.sp10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.scoreLabel,
                        style: TextStyle(
                          color: sc,
                          fontWeight: AppTheme.w700,
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
                ScoreCircle(score: match.score, color: sc),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SidePanel(
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
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: VerticalDivider(
                          color: sc.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.sp8),
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.10),
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
                          color: sc.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SidePanel(
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
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.sp12,
              AppTheme.sp8,
              AppTheme.sp12,
              AppTheme.sp10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.bgRaised.withValues(alpha: 0.4),
              border: const Border(
                top: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ActionButton(
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
                  child: ActionButton(
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

class SidePanel extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  const SidePanel({super.key, required this.property, required this.onTap});

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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                property.entryType.label,
                style: TextStyle(
                  fontSize: AppTheme.fontXs,
                  color: color,
                  fontWeight: AppTheme.w700,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.sp4),
            Text(
              property.propertyType,
              style: const TextStyle(
                fontSize: AppTheme.fontSm,
                fontWeight: AppTheme.w700,
                color: AppTheme.textHigh,
              ),
            ),
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
            if (property.price > 0)
              Text(
                '${PriceFormatter.format(property.price)} ${property.currency}',
                style: TextStyle(
                  fontSize: AppTheme.fontSm,
                  fontWeight: AppTheme.w700,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ScoreCircle extends StatelessWidget {
  final double score;
  final Color color;
  const ScoreCircle({super.key, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${(score * 100).toInt()}',
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSm,
              fontWeight: AppTheme.w800,
              height: 1,
            ),
          ),
          Text(
            '%',
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 8,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
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
            border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
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
                  fontWeight: AppTheme.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
