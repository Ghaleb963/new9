import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class EntryTypeSelector extends StatelessWidget {
  final EntryType selected;
  final ValueChanged<EntryType> onChanged;

  const EntryTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TypeCard(
            entryType: EntryType.offer,
            icon: Icons.home_work_outlined,
            label: 'عرض عقار',
            description: 'بيع أو تأجير عقار',
            color: AppTheme.accentGreen,
            isSelected: selected == EntryType.offer,
            onTap: () => onChanged(EntryType.offer),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TypeCard(
            entryType: EntryType.requirement,
            icon: Icons.search_rounded,
            label: 'طلب عقار',
            description: 'باحث عن عقار بمواصفات',
            color: AppTheme.accentAmber,
            isSelected: selected == EntryType.requirement,
            onTap: () => onChanged(EntryType.requirement),
          ),
        ),
      ],
    );
  }
}

class TypeCard extends StatelessWidget {
  final EntryType entryType;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const TypeCard({
    super.key,
    required this.entryType,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppTheme.bgRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : AppTheme.borderMedium,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : AppTheme.textLow,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: AppTheme.w700,
                fontSize: AppTheme.fontMd,
                color: isSelected ? color : AppTheme.textHigh,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: AppTheme.fontXs,
                color: AppTheme.textLow,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
