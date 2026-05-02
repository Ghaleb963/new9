import 'package:flutter/material.dart';
import '../services/matching_service.dart';
import '../models/property_model.dart';
import 'property_detail_view.dart';
import '../../../core/constants/app_constants.dart';

// ════════════════════════════════════════════════════════
// MatchResultsView — شاشة عرض كل التوافقات المكتشفة
//
// تُعرض عند الضغط على "عرض الكل" في تنبيه المطابقة.
// تُظهر قائمة مرتبة بالدرجة مع تفاصيل كل توافق.
// ════════════════════════════════════════════════════════
class MatchResultsView extends StatelessWidget {
  final List<MatchResult> matches;
  final PropertyModel originProperty; // العقار/الطلب الذي أطلق عملية المطابقة

  const MatchResultsView({
    super.key,
    required this.matches,
    required this.originProperty,
  });

  @override
  Widget build(BuildContext context) {
    final isOffer = originProperty.entryType == EntryType.offer;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOffer ? 'طلبات مطابقة للعرض' : 'عروض مطابقة للطلب'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.link_rounded,
                    color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'تم العثور على ${matches.length} توافق محتمل',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── بطاقة السجل المصدر ──────────────────────────
          _OriginCard(property: originProperty),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('التوافقات', style: TextStyle(fontSize: 12)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),

          // ── قائمة التوافقات ──────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final other = match.otherSide(originProperty);
                return _MatchCard(
                  match: match,
                  otherProperty: other,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PropertyDetailView(property: other),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── بطاقة العقار/الطلب المصدر (الذي أطلق المطابقة) ──────────────────────────
class _OriginCard extends StatelessWidget {
  final PropertyModel property;
  const _OriginCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final isOffer = property.entryType == EntryType.offer;
    final color = isOffer ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
              isOffer ? Icons.home_work_outlined : Icons.search_rounded,
              color: color,
              size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${property.entryType.label} - ${property.propertyType}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16),
                ),
                Text(
                  '${property.province}${property.region.isNotEmpty ? "، ${property.region}" : ""}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                if (property.price > 0)
                  Text(
                    '${property.price} ${property.currency}',
                    style: const TextStyle(fontSize: 13),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('المصدر',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── بطاقة توافق فردي ─────────────────────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final MatchResult match;
  final PropertyModel otherProperty;
  final VoidCallback onTap;

  const _MatchCard({
    required this.match,
    required this.otherProperty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(match.score);
    final isOther = otherProperty.entryType == EntryType.offer;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isOther
                        ? Icons.home_work_outlined
                        : Icons.search_rounded,
                    color: isOther ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${otherProperty.entryType.label}: ${otherProperty.propertyType}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  // درجة التوافق
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(match.score * 100).round()}%',
                      style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${otherProperty.province}${otherProperty.region.isNotEmpty ? "، ${otherProperty.region}" : ""}',
                    style:
                        TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  if (otherProperty.price > 0) ...[
                    const Spacer(),
                    Text(
                      '${otherProperty.price} ${otherProperty.currency}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // شريط التقدم
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: match.score,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  color: scoreColor,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              // معايير التطابق
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: match.matchedCriteria
                    .map((c) => _SmallTag(label: c))
                    .toList(),
              ),
              const SizedBox(height: 8),
              // نص التوافق
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    match.scoreLabel,
                    style: TextStyle(
                        color: scoreColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const Row(
                    children: [
                      Text('عرض التفاصيل',
                          style: TextStyle(
                              fontSize: 12, color: Colors.green)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: Colors.green),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.85) return Colors.green;
    if (score >= 0.70) return Colors.lightGreen;
    return Colors.orange;
  }
}

class _SmallTag extends StatelessWidget {
  final String label;
  const _SmallTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 10, color: Colors.green),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.green)),
        ],
      ),
    );
  }
}
