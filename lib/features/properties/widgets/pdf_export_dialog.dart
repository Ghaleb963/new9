import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PdfExportDialog extends StatefulWidget {
  final int imageCount;
  final Future<Uint8List> Function(void Function(int, int) onProgress) generate;

  const PdfExportDialog({
    super.key,
    required this.imageCount,
    required this.generate,
  });

  @override
  State<PdfExportDialog> createState() => _PdfExportDialogState();
}

class _PdfExportDialogState extends State<PdfExportDialog>
    with SingleTickerProviderStateMixin {
  int _completed = 0;
  int _total = 0;
  bool _building = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );
    _total = widget.imageCount;
    _start();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final bytes = await widget.generate((done, total) {
        if (!mounted) return;
        setState(() {
          _completed = done;
          _total = total;
          _building = done >= total;
        });
      }).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException('PDF generation timeout'),
      );
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _building ? AppTheme.accentGreen : AppTheme.accentAmber;

    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(
            color: AppTheme.bgRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) => Transform.scale(
                  scale: _building ? 1.0 : _pulseAnim.value,
                  child: child,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _building
                          ? const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AppTheme.accentGreen,
                              size: 32,
                              key: ValueKey('pdf'),
                            )
                          : const SizedBox(
                              width: 28,
                              height: 28,
                              key: ValueKey('spinner'),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppTheme.accentAmber,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey('status_$_building'),
                  _building
                      ? 'جاري إنشاء التقرير...'
                      : 'جاري معالجة الصور...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey('sub_${_building}_$_completed'),
                  _building
                      ? 'يتم تجميع البيانات في ملف PDF'
                      : _total > 0
                          ? '$_completed من $_total صور'
                          : '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMedium,
                  ),
                ),
              ),
              if (_total > 0)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _completed / _total,
                          minHeight: 6,
                          backgroundColor: AppTheme.borderMedium,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          key: ValueKey('pct_${(_completed / _total * 100).round()}'),
                          '${(_completed / _total * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
