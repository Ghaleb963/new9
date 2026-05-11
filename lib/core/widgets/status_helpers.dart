import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusHelpers {
  static Color color(String status) {
    switch (status) {
      case 'متاح':
        return AppTheme.accentTeal;
      case 'مؤجر':
        return AppTheme.accentAmber;
      case 'مباع':
        return AppTheme.accentRed;
      case 'محجوز':
        return AppTheme.accentBlue;
      case 'تحت الدراسة':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.textLow;
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case 'متاح':
        return Icons.check_circle_rounded;
      case 'مؤجر':
        return Icons.vpn_key_rounded;
      case 'مباع':
        return Icons.sell_rounded;
      case 'محجوز':
        return Icons.bookmark_rounded;
      case 'تحت الدراسة':
        return Icons.pending_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = StatusHelpers.color(status);
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: AppTheme.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class TappableStatusBadge extends StatelessWidget {
  final String status;
  final VoidCallback onTap;

  const TappableStatusBadge({
    super.key,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = StatusHelpers.color(status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sp16,
            vertical: AppTheme.sp8,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: color.withValues(alpha: 0.30),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(StatusHelpers.icon(status), color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: AppTheme.w700,
                  fontSize: AppTheme.fontMd,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: color.withValues(alpha: 0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
