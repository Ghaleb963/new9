import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ════════════════════════════════════════════════════════
// Form Widgets — مكوّنات النماذج المُعاد تصميمها
// شبكة 8pt صارمة + تسلسل بصري واضح
// ════════════════════════════════════════════════════════

// ── قسم في النموذج مع خط جانبي ملوّن ──────────────────────────────────────
class AppFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color? accentColor;

  const AppFormSection({
    super.key,
    required this.title,
    required this.children,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.accentGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp16,
              vertical: AppTheme.sp12,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppTheme.radiusLg),
                topLeft: Radius.circular(AppTheme.radiusLg),
              ),
              border: Border(
                bottom: BorderSide(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppTheme.sp8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.all(AppTheme.sp16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── حقل نص مُحسَّن ──────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumber;
  final int maxLines;
  final bool isRequired;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isNumber = false,
    this.maxLines = 1,
    this.isRequired = false,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: AppTheme.textHigh,
          fontSize: AppTheme.fontMd,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 18, color: AppTheme.textLow)
              : null,
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: validator ??
            (isRequired
                ? (val) =>
                    (val == null || val.isEmpty) ? 'هذا الحقل مطلوب' : null
                : null),
      ),
    );
  }
}

// ── Dropdown مُحسَّن ─────────────────────────────────────────────────────────
class AppDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;
  final IconData? prefixIcon;

  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp12),
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : items.first,
        dropdownColor: AppTheme.bgRaised,
        iconSize: 20,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppTheme.textLow,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 18, color: AppTheme.textLow)
              : null,
        ),
        style: const TextStyle(
          color: AppTheme.textHigh,
          fontSize: AppTheme.fontMd,
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(
                      color: AppTheme.textHigh,
                      fontSize: AppTheme.fontMd,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Smart Buttons (اختيار واحد) ──────────────────────────────────────────────
class AppSmartButtons extends StatelessWidget {
  final String label;
  final List<String> items;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final Color? activeColor;

  const AppSmartButtons({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.accentGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.sp8),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMedium,
                  fontSize: AppTheme.fontXs,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          Wrap(
            spacing: AppTheme.sp8,
            runSpacing: AppTheme.sp8,
            children: items.map((item) {
              final isSelected = selectedValue == item;
              return GestureDetector(
                onTap: () => onChanged(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp16,
                    vertical: AppTheme.sp8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color : AppTheme.bgRaised,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.borderMedium,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? AppTheme.shadowGreen : null,
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.textOnAccent
                          : AppTheme.textMedium,
                      fontSize: AppTheme.fontSm,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Multi-Select (اختيار متعدد) ──────────────────────────────────────────────
class AppMultiSelect extends StatelessWidget {
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<String> onToggle;
  final Color? activeColor;

  const AppMultiSelect({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onToggle,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.accentGreen;
    return Wrap(
      spacing: AppTheme.sp8,
      runSpacing: AppTheme.sp8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return GestureDetector(
          onTap: () => onToggle(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp12,
              vertical: AppTheme.sp8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : AppTheme.bgRaised,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.6)
                    : AppTheme.borderMedium,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_rounded, size: 13, color: color),
                  const SizedBox(width: 4),
                ],
                Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? color : AppTheme.textMedium,
                    fontSize: AppTheme.fontSm,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Section Title (في صفحة الإعدادات) ────────────────────────────────────────
class AppSectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;

  const AppSectionTitle({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppTheme.sp12,
        top: AppTheme.sp8,
        right: AppTheme.sp4,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppTheme.accentGreen),
            const SizedBox(width: AppTheme.sp8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontLg,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentGreen,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
