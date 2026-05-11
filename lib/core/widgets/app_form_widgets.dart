import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.sp16,
              AppTheme.sp12,
              AppTheme.sp16,
              AppTheme.sp10,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: color.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 2.5,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: AppTheme.sp8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSm,
                    fontWeight: AppTheme.w600,
                    color: color,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
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
                  fontWeight: AppTheme.w500,
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
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : AppTheme.bgRaised,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.4)
                          : AppTheme.borderMedium,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected ? color : AppTheme.textMedium,
                      fontSize: AppTheme.fontSm,
                      fontWeight: isSelected ? AppTheme.w600 : AppTheme.w400,
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
                  ? color.withValues(alpha: 0.12)
                  : AppTheme.bgRaised,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.4)
                    : AppTheme.borderMedium,
                width: isSelected ? 1.5 : 0.5,
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
                    fontWeight: isSelected ? AppTheme.w600 : AppTheme.w400,
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
              fontWeight: AppTheme.w700,
              color: AppTheme.accentGreen,
            ),
          ),
        ],
      ),
    );
  }
}
