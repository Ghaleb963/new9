import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showAppLoadingDialog(BuildContext context, {String message = 'جاري...'}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.sp24),
        decoration: BoxDecoration(
          color: AppTheme.bgRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.accentGreen),
            const SizedBox(height: AppTheme.sp16),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
          ],
        ),
      ),
    ),
  );
}
