import 'package:flutter/material.dart';
import '../../features/properties/services/matching_service.dart';
import '../utils/score_helpers.dart';
import 'app_criteria_tag.dart';

// ════════════════════════════════════════════════════════
// showMatchNotification — الدالة العامة لإظهار تنبيه المطابقة
//
// التصميم:
// - OverlayEntry: يظهر فوق كل شيء دون كسر التنقل
// - Animation: Slide-Up + Fade-In عند الظهور، Fade-Out عند الإخفاء
// - Auto-dismiss: بعد 8 ثواني إذا لم يتفاعل المستخدم
// - يُظهر أفضل توافق بالدرجة مع عدد التوافقات الكلي
// ════════════════════════════════════════════════════════
void showMatchNotification(
  BuildContext context, {
  required List<MatchResult> matches,
  required void Function(List<MatchResult> matches) onViewMatches,
}) {
  if (matches.isEmpty) return;

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _MatchToastWidget(
      matches: matches,
      onViewMatches: () {
        _safeRemove(entry);
        onViewMatches(matches);
      },
      onDismiss: () => _safeRemove(entry),
    ),
  );

  overlay.insert(entry);

  // إزالة تلقائية بعد 8 ثواني
  Future.delayed(const Duration(seconds: 8), () => _safeRemove(entry));
}

void _safeRemove(OverlayEntry entry) {
  try {
    if (entry.mounted) entry.remove();
  } catch (_) {}
}

// ════════════════════════════════════════════════════════
// _MatchToastWidget — الـ Widget الداخلي للتنبيه
// StatefulWidget لإدارة Animation الظهور والإخفاء
// ════════════════════════════════════════════════════════
class _MatchToastWidget extends StatefulWidget {
  final List<MatchResult> matches;
  final VoidCallback onViewMatches;
  final VoidCallback onDismiss;

  const _MatchToastWidget({
    required this.matches,
    required this.onViewMatches,
    required this.onDismiss,
  });

  @override
  State<_MatchToastWidget> createState() => _MatchToastWidgetState();
}

class _MatchToastWidgetState extends State<_MatchToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final best = widget.matches.first;
    final count = widget.matches.length;

    return Positioned(
      bottom: 90,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── شريط الرأس ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.link_rounded,
                              color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تم اكتشاف توافق فوري!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                count == 1
                                    ? 'عرض وطلب متوافقان'
                                    : '$count توافق محتمل',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[300]),
                              ),
                            ],
                          ),
                        ),
                        // زر الإغلاق
                        GestureDetector(
                          onTap: _dismiss,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                color: Colors.grey[500], size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── تفاصيل أفضل توافق ────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Row(
                      children: [
                        _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: best.offer.province),
                        const SizedBox(width: 8),
                        _InfoChip(
                            icon: Icons.home_outlined,
                            label: best.offer.propertyType),
                        const SizedBox(width: 8),
                        _InfoChip(
                            icon: Icons.sell_outlined,
                            label: best.offer.adType),
                      ],
                    ),
                  ),

                  // ── شريط الدرجة ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: best.score,
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.3),
                              color: ScoreHelpers.notificationScoreColor(best.score),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          best.scoreLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: ScoreHelpers.notificationScoreColor(best.score),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── معايير التطابق ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: best.matchedCriteria
                           .map((c) => AppCriteriaTag(label: c))
                          .toList(),
                    ),
                  ),

                  // ── أزرار الإجراء ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _dismiss,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.5)),
                              foregroundColor: Colors.grey[400],
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('لاحقاً',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: widget.onViewMatches,
                            icon: const Icon(Icons.arrow_forward_ios,
                                size: 14),
                            label: Text(
                              count == 1 ? 'عرض التوافق' : 'عرض الكل ($count)',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
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
        ),
      ),
    );
  }

}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[300])),
        ],
      ),
    );
  }
}


