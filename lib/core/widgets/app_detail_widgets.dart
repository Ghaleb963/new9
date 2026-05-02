import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ════════════════════════════════════════════════════════
// Detail & Filter Widgets — مُعاد تصميمها
// ════════════════════════════════════════════════════════

// ── صف تفاصيل العقار مع أيقونة ──────────────────────────────────────────────
class AppDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const AppDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp16,
          vertical: AppTheme.sp12,
        ),
        decoration: BoxDecoration(
          color: AppTheme.bgRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.borderSubtle, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label side
            SizedBox(
              width: 110,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: AppTheme.textLow),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textLow,
                        fontSize: AppTheme.fontSm,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Value side
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.textHigh,
                  fontSize: AppTheme.fontMd,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── قسم في نموذج الفلترة ─────────────────────────────────────────────────────
class AppFilterSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AppFilterSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppTheme.sp16,
              bottom: AppTheme.sp8,
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textHigh,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ── Choice Chips للفلترة المتقدمة ───────────────────────────────────────────
class AppChoiceChips extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final void Function(String?) onSelected;

  const AppChoiceChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.sp8,
      runSpacing: AppTheme.sp8,
      children: items.map((t) {
        final isSelected = selected == t;
        return GestureDetector(
          onTap: () => onSelected(isSelected ? null : t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp12,
              vertical: AppTheme.sp8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentGreen.withValues(alpha: 0.15)
                  : AppTheme.bgRaised,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentGreen.withValues(alpha: 0.6)
                    : AppTheme.borderMedium,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              t,
              style: TextStyle(
                color:
                    isSelected ? AppTheme.accentGreen : AppTheme.textMedium,
                fontSize: AppTheme.fontSm,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Range Filter (من - إلى) ──────────────────────────────────────────────────
class AppRangeFilter extends StatelessWidget {
  final String fromHint;
  final String toHint;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;

  const AppRangeFilter({
    super.key,
    this.fromHint = 'من',
    this.toHint = 'إلى',
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RangeField(hint: fromHint, onChanged: onFromChanged),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp8),
          child: Container(
            width: 20,
            height: 1,
            color: AppTheme.borderMedium,
          ),
        ),
        Expanded(
          child: _RangeField(hint: toHint, onChanged: onToChanged),
        ),
      ],
    );
  }
}

class _RangeField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _RangeField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(
        color: AppTheme.textHigh,
        fontSize: AppTheme.fontSm,
      ),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp12,
          vertical: AppTheme.sp12,
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }
}
