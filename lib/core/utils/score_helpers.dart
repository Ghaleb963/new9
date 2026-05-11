import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScoreHelpers {
  static Color notificationScoreColor(double score) {
    if (score >= 0.85) return Colors.green;
    if (score >= 0.70) return Colors.lightGreen;
    return Colors.orange;
  }

  static Color matchCardScoreColor(double score) {
    if (score >= 0.85) return AppTheme.accentGreen;
    if (score >= 0.70) return AppTheme.accentGreenGlow;
    return AppTheme.accentAmber;
  }
}
