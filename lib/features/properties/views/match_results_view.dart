import 'package:flutter/material.dart';
import '../services/matching_service.dart';
import '../models/property_model.dart';
import 'property_detail_view.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/score_helpers.dart';
import '../../../core/widgets/app_criteria_tag.dart';

class MatchResultsView extends StatelessWidget {
  final List<MatchResult> matches;
  final PropertyModel originProperty;

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
                    color: AppTheme.accentGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  'تم العثور على ${matches.length} توافق محتمل',
                  style: const TextStyle(color: AppTheme.accentGreen),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _OriginCard(property: originProperty),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('التوافقات',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
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
                      builder: (_) => PropertyDetailView(property: other),
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

class _OriginCard extends StatelessWidget {
  final PropertyModel property;
  const _OriginCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final isOffer = property.entryType == EntryType.offer;
    final color = isOffer ? AppTheme.accentGreen : AppTheme.accentAmber;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(isOffer ? Icons.home_work_outlined : Icons.search_rounded,
              color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${property.entryType.label} - ${property.propertyType}',
                  style: TextStyle(
                      fontWeight: AppTheme.w700,
                      color: color,
                      fontSize: AppTheme.fontMd),
                ),
                Text(
                  '${property.province}${property.region.isNotEmpty ? "، ${property.region}" : ""}',
                  style: const TextStyle(
                      color: AppTheme.textMedium, fontSize: AppTheme.fontSm),
                ),
                if (property.price > 0)
                  Text(
                    '${property.price} ${property.currency}',
                    style: const TextStyle(
                        fontSize: AppTheme.fontSm, color: AppTheme.textHigh),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text('المصدر',
                style: TextStyle(
                    color: color,
                    fontSize: AppTheme.fontXs,
                    fontWeight: AppTheme.w700)),
          ),
        ],
      ),
    );
  }
}

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
    final scoreColor = ScoreHelpers.notificationScoreColor(match.score);
    final isOther = otherProperty.entryType == EntryType.offer;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isOther ? Icons.home_work_outlined : Icons.search_rounded,
                    color:
                        isOther ? AppTheme.accentGreen : AppTheme.accentAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${otherProperty.entryType.label}: ${otherProperty.propertyType}',
                      style: const TextStyle(
                          fontWeight: AppTheme.w700,
                          fontSize: AppTheme.fontMd,
                          color: AppTheme.textHigh),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(match.score * 100).round()}%',
                      style: TextStyle(
                          color: scoreColor,
                          fontWeight: AppTheme.w700,
                          fontSize: AppTheme.fontSm),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textLow),
                  const SizedBox(width: 4),
                  Text(
                    '${otherProperty.province}${otherProperty.region.isNotEmpty ? "، ${otherProperty.region}" : ""}',
                    style: const TextStyle(
                        color: AppTheme.textMedium, fontSize: AppTheme.fontSm),
                  ),
                  if (otherProperty.price > 0) ...[
                    const Spacer(),
                    Text(
                      '${otherProperty.price} ${otherProperty.currency}',
                      style: const TextStyle(
                          fontWeight: AppTheme.w600,
                          fontSize: AppTheme.fontSm,
                          color: AppTheme.textHigh),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: match.score,
                  backgroundColor: AppTheme.textLow.withValues(alpha: 0.2),
                  color: scoreColor,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: match.matchedCriteria
                    .map((c) => AppCriteriaTag(label: c))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    match.scoreLabel,
                    style: TextStyle(
                        color: scoreColor,
                        fontSize: AppTheme.fontXs,
                        fontWeight: AppTheme.w600),
                  ),
                  const Row(
                    children: [
                      Text('عرض التفاصيل',
                          style: TextStyle(
                              fontSize: AppTheme.fontXs,
                              color: AppTheme.accentGreen)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppTheme.accentGreen),
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
}
