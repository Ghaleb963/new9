import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBottomSheetHandle extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const AppBottomSheetHandle({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          color: AppTheme.borderMedium,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
