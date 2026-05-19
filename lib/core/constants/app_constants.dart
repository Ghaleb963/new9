// ─── تصنيف نوع الإدخال ─────────────────────────────────────────────────────
// EntryType يُمثّل التصنيف الجذري لكل سجل في النظام.
// Offer  = عرض عقار (صاحب العقار يعرضه للبيع أو الإيجار).
// Requirement = طلب عقار (زبون يبحث عن عقار بمواصفات معينة).
// تم تعريفه هنا كـ top-level enum لتوفره لكافة طبقات التطبيق دون اقتران.
enum EntryType {
  offer,       // عرض
  requirement, // طلب
}

// Extension لتحويل EntryType إلى String مخزّن في قاعدة البيانات والعكس.
// فصل هذا المنطق في Extension يحافظ على نظافة الـ enum نفسه.
extension EntryTypeExtension on EntryType {
  String get value => name; // 'offer' | 'requirement'

  String get label {
    switch (this) {
      case EntryType.offer:
        return 'عرض';
      case EntryType.requirement:
        return 'طلب';
    }
  }
}

extension EntryTypeParser on String {
  EntryType toEntryType() {
    return EntryType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => EntryType.offer, // قيمة افتراضية آمنة للسجلات القديمة
    );
  }
}

class AppConstants {
  // ─── قوائم البيانات الثابتة ─────────────────────────────────────────────────
  static const List<String> provinces = [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'إدلب',
    'دير الزور',
    'الرقة',
    'الحسكة',
    'درعا',
    'السويداء',
    'القنيطرة',
  ];

  static const List<String> propertyTypes = [
    'شقة',
    'بيت عربي',
    'محضر',
    'فيلا',
    'معمل',
    'ورشة',
    'مستودع',
    'أرض',
    'محل تجاري',
    'مكتب',
    'عمارة',
  ];

  static const List<String> facadeTypes = [
    'أمامي',
    'خلفي',
    'جانبي',
    'حشوة',
    'زاوية حرة',
    'زاوية',
    'نصف بلاطة',
    'شريحة خلفية',
    'بلاطة',
  ];

  static const List<String> finishingLevels = [
    'عظم',
    'معرا',
    'وسط',
    'جيد',
    'جيد جداً',
    'ممتاز',
    'سوبر',
  ];

  static const List<String> directions = [
    'غربي',
    'قبلي',
    'شرقي',
    'شمالي',
  ];

  static const List<String> featuresList = [
    'استطراق خارجي',
    'السطح المشترك',
    'مدخل فخم',
    'بناء فخم',
    'مصعد',
    'تدفئة',
    'تكييف',
    'طاقة شمسية',
    'خزان ماء',
    'موقف سيارات',
  ];

  static const List<String> ownershipTypes = [
    'طابو أخضر',
    'طابو أبيض',
    'فراغات جمعيات',
  ];

  static const List<String> currencies = [
    'ليرة سورية',
    'دولار',
  ];

  static const List<String> statusList = [
    'متاح',
    'مؤجر',
    'مباع',
  ];

  static const List<String> adTypes = [
    'بيع',
    'إيجار',
  ];

  static const List<String> deedTypes = [
    'سكني',
    'تجاري',
    'زراعي',
  ];

  static const List<String> ownerStatuses = [
    'شخص واحد',
    'ورثة',
  ];
}
