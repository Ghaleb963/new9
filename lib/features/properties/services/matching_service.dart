import '../models/property_model.dart';
import '../../../core/constants/app_constants.dart';

// ════════════════════════════════════════════════════════
// MatchResult — نتيجة مطابقة بين عرض وطلب
// نموذج بيانات نظيف يحمل كل ما يحتاجه الـ UI لعرض التنبيه
// ════════════════════════════════════════════════════════
class MatchResult {
  final PropertyModel offer;       // العرض المطابق
  final PropertyModel requirement; // الطلب المطابق
  final double score;              // درجة التوافق من 0.0 إلى 1.0
  final List<String> matchedCriteria; // معايير التوافق المحققة

  const MatchResult({
    required this.offer,
    required this.requirement,
    required this.score,
    required this.matchedCriteria,
  });

  String get scoreLabel {
    if (score >= 0.90) return 'توافق ممتاز';
    if (score >= 0.75) return 'توافق جيد جداً';
    if (score >= 0.60) return 'توافق جيد';
    return 'توافق جزئي';
  }

  // العقار الآخر من وجهة نظر عقار معروف
  PropertyModel otherSide(PropertyModel fromProperty) {
    return fromProperty.entryType == EntryType.offer ? requirement : offer;
  }
}

// ════════════════════════════════════════════════════════
// MatchingService — محرك المطابقة الفورية
//
// مبادئ التصميم:
// - Pure Dart: لا يعتمد على Flutter أو أي dependency خارجي
// - Stateless: جميع الدوال static — سهل الاختبار
// - منفصل تماماً عن الـ UI وعن قاعدة البيانات
// - يعمل على قائمة العقارات المحملة في الذاكرة (من الـ Provider)
//   لتفادي round-trips إضافية إلى DB
// ════════════════════════════════════════════════════════
class MatchingService {
  // نسبة التسامح في السعر: الباحث يقبل عروضاً أعلى من ميزانيته بـ 20%
  // (احتمال التفاوض أو المرونة)
  static const double _priceTolerance = 0.20;

  // الحد الأدنى للدرجة لاعتبار المطابقة صالحة
  static const double _minimumScore = 0.60;

  /// الدالة الرئيسية:
  /// تأخذ العقار/الطلب الجديد + قائمة كل السجلات،
  /// وترجع قائمة مرتبة تنازلياً بالدرجة من التوافقات الصالحة.
  ///
  /// كفاءة: O(n) — تمر على كل العناصر مرة واحدة
  static List<MatchResult> findMatches(
    PropertyModel newEntry,
    List<PropertyModel> allProperties,
  ) {
    // المرشحون: فقط العناصر من النوع المعاكس ولا نطابق السجل مع نفسه
    final candidates = allProperties.where((p) {
      if (p.id == newEntry.id) return false;
      return p.entryType != newEntry.entryType;
    }).toList();

    if (candidates.isEmpty) return [];

    final results = <MatchResult>[];

    for (final candidate in candidates) {
      // تحديد أيهما العرض وأيهما الطلب بوضوح
      final PropertyModel offer;
      final PropertyModel requirement;

      if (newEntry.entryType == EntryType.offer) {
        offer = newEntry;
        requirement = candidate;
      } else {
        offer = candidate;
        requirement = newEntry;
      }

      final result = _evaluate(offer, requirement);
      if (result != null) results.add(result);
    }

    // ترتيب تنازلي بالدرجة — أفضل التوافقات أولاً
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  /// تقييم التوافق بين عرض واحد وطلب واحد.
  /// ترجع null إذا لم تنجح المعايير الإلزامية (Hard Criteria).
  static MatchResult? _evaluate(
    PropertyModel offer,
    PropertyModel requirement,
  ) {
    // ══════════════════════════════════════════════════
    // المعايير الإلزامية (Hard Criteria)
    // إذا فشل أي منها → لا توافق
    // ══════════════════════════════════════════════════

    // 1. المحافظة متطابقة
    if (offer.province.isEmpty ||
        requirement.province.isEmpty ||
        offer.province != requirement.province) {
      return null;
    }

    // 2. نوع العقار متطابق
    if (offer.propertyType.isEmpty ||
        requirement.propertyType.isEmpty ||
        offer.propertyType != requirement.propertyType) {
      return null;
    }

    // 3. نوع الإعلان متطابق (بيع ↔ بيع، إيجار ↔ إيجار)
    if (offer.adType.isEmpty ||
        requirement.adType.isEmpty ||
        offer.adType != requirement.adType) {
      return null;
    }

    // ══════════════════════════════════════════════════
    // المعايير التحسينية (Soft Criteria) — تؤثر على الدرجة
    // ══════════════════════════════════════════════════

    double score = 0.60; // الدرجة الأساسية لاجتياز المعايير الإلزامية
    final matched = <String>['المحافظة', 'نوع العقار', 'نوع الإعلان'];

    // 4. توافق السعر مع الميزانية (+20%)
    if (offer.price > 0 && requirement.price > 0) {
      final maxAcceptable = requirement.price * (1 + _priceTolerance);
      if (offer.price <= maxAcceptable) {
        score += 0.20;
        matched.add('السعر ضمن الميزانية');
      }
      // عقوبة خفيفة إذا تجاوز السعر الميزانية بكثير
      else if (offer.price > maxAcceptable * 1.5) {
        score -= 0.05;
      }
    } else {
      // إذا لم يحدد أحدهما السعر → لا عقوبة، منح نصف النقاط
      score += 0.10;
    }

    // 5. تطابق المنطقة (+15%)
    if (offer.region.isNotEmpty &&
        requirement.region.isNotEmpty &&
        _normalizeRegion(offer.region) ==
            _normalizeRegion(requirement.region)) {
      score += 0.15;
      matched.add('المنطقة');
    }

    // 6. توافق عدد الغرف (+5%)
    if (offer.rooms > 0 && requirement.rooms > 0) {
      if ((offer.rooms - requirement.rooms).abs() <= 1) {
        score += 0.05;
        matched.add('عدد الغرف');
      }
    }

    final finalScore = score.clamp(0.0, 1.0);

    // رفض التوافقات الضعيفة جداً
    if (finalScore < _minimumScore) return null;

    return MatchResult(
      offer: offer,
      requirement: requirement,
      score: finalScore,
      matchedCriteria: matched,
    );
  }

  /// حساب جميع التوافقات الممكنة بين كل العروض وكل الطلبات.
  /// تُستخدم من قِبَل allMatchesProvider لعرض لوحة التوافقات.
  ///
  /// كفاءة: O(offers × requirements) — مقبول لأن العمل يجري في الذاكرة
  /// دون أي قراءة من قاعدة البيانات.
  static List<MatchResult> findAllMatches(
    List<PropertyModel> allProperties,
  ) {
    final offers = allProperties
        .where((p) => p.entryType == EntryType.offer)
        .toList();
    final requirements = allProperties
        .where((p) => p.entryType == EntryType.requirement)
        .toList();

    if (offers.isEmpty || requirements.isEmpty) return [];

    final results = <MatchResult>[];

    for (final offer in offers) {
      for (final req in requirements) {
        final result = _evaluate(offer, req);
        if (result != null) results.add(result);
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  // تطبيع نص المنطقة للمقارنة: إزالة المسافات والحركات
  static String _normalizeRegion(String region) {
    return region.trim().toLowerCase();
  }
}
