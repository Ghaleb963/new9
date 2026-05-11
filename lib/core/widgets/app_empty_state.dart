import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.sp40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.sp20),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
              ),
              child: Icon(icon, size: 40, color: AppTheme.textLow),
            ),
            const SizedBox(height: AppTheme.sp20),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fontXl,
                fontWeight: AppTheme.w700,
                color: AppTheme.textHigh,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.sp8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: AppTheme.fontMd,
                color: AppTheme.textMedium,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppTheme.sp20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
