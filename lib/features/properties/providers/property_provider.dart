import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_model.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../services/matching_service.dart';
import '../services/pdf_service.dart';
import '../../settings/providers/settings_provider.dart';

class PropertyNotifier extends StateNotifier<List<PropertyModel>> {
  final Ref ref;
  PropertyNotifier(this.ref) : super([]) {
    loadProperties();
  }

  Future<void> loadProperties() async {
    try {
      final properties = await DatabaseHelper.instance.getAllProperties();
      state = properties;
    } catch (e) {
      state = [];
    }
  }

  Future<bool> addProperty(PropertyModel property) async {
    final newId = await DatabaseHelper.instance.insertProperty(property);
    final inserted = property.copyWith(id: newId);
    state = [inserted, ...state];

    unawaited(_enqueueBackgroundPdf(inserted));

    return true;
  }

  Future<void> _enqueueBackgroundPdf(PropertyModel property) async {
    try {
      final settings = ref.read(settingsProvider);
      await PdfService.enqueueForBackgroundCache(
        property: property,
        settings: settings,
      );
    } catch (e) {
      debugPrint('PropertyNotifier: enqueue background PDF failed: $e');
    }
  }

  Future<void> deleteProperty(int id) async {
    await PdfService.invalidateCache(id);
    await DatabaseHelper.instance.deleteProperty(id);
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> updateProperty(PropertyModel property) async {
    await PdfService.invalidateCache(property.id!);
    await DatabaseHelper.instance.updateProperty(property);
    state = state.map((p) => p.id == property.id ? property : p).toList();
  }

  Future<void> updatePropertyStatus(int id, String newStatus) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final updated = state[index].copyWith(status: newStatus);
    await PdfService.invalidateCache(id);
    await DatabaseHelper.instance.updateProperty(updated);
    state = state.map((p) => p.id == id ? updated : p).toList();
  }

  List<MatchResult>? findMatchesFor(PropertyModel property) {
    final matches = MatchingService.findMatches(property, state);
    return matches.isEmpty ? null : matches;
  }
}

final propertyProvider =
    StateNotifierProvider<PropertyNotifier, List<PropertyModel>>((ref) {
  return PropertyNotifier(ref);
});

// ════════════════════════════════════════════════════════
// filteredPropertiesProvider — فلترة على مستوى SQL
//
// بدلاً من جلب كل العقارات ثم تصفيتها في Dart (O(n × 19))،
// نبني جملة WHERE ديناميكياً ونترك SQLite يقوم بالعمل.
// ════════════════════════════════════════════════════════
final filteredPropertiesProvider = FutureProvider<List<PropertyModel>>((ref) {
  final filter = ref.watch(propertyFilterProvider);

  if (filter.isEmpty) {
    return DatabaseHelper.instance.getAllProperties();
  }

  return DatabaseHelper.instance.getPropertiesFiltered(
    entryType: filter.selectedEntryType?.name,
    query: filter.query.isNotEmpty ? filter.query : null,
    minPrice: filter.minPrice,
    maxPrice: filter.maxPrice,
    propertyType: filter.selectedType,
    province: filter.selectedProvince,
    adType: filter.selectedAdType,
    status: filter.selectedStatus,
    finishingLevel: filter.selectedFinishing,
    facade: filter.selectedFacade,
    deedType: filter.selectedDeedType,
    minRooms: filter.minRooms,
    maxRooms: filter.maxRooms,
    minArea: filter.minArea,
    maxArea: filter.maxArea,
    floor: filter.selectedFloor,
    hasGarden: filter.hasGarden,
    isDuplex: filter.isDuplex,
    currency: filter.selectedCurrency,
    ownershipType: filter.selectedOwnership,
    ownerStatus: filter.selectedOwnerStatus,
  );
});

class PropertyFilter {
  final EntryType? selectedEntryType;
  final String query;
  final double? minPrice;
  final double? maxPrice;
  final String? selectedType;
  final String? selectedOwnerStatus;
  final String? selectedProvince;
  final String? selectedAdType;
  final String? selectedStatus;
  final String? selectedFinishing;
  final String? selectedFacade;
  final String? selectedDeedType;
  final int? minRooms;
  final int? maxRooms;
  final double? minArea;
  final double? maxArea;
  final String? selectedFloor;
  final bool? hasGarden;
  final bool? isDuplex;
  final String? selectedCurrency;
  final String? selectedOwnership;

  const PropertyFilter({
    this.selectedEntryType,
    this.query = '',
    this.minPrice,
    this.maxPrice,
    this.selectedType,
    this.selectedOwnerStatus,
    this.selectedProvince,
    this.selectedAdType,
    this.selectedStatus,
    this.selectedFinishing,
    this.selectedFacade,
    this.selectedDeedType,
    this.minRooms,
    this.maxRooms,
    this.minArea,
    this.maxArea,
    this.selectedFloor,
    this.hasGarden,
    this.isDuplex,
    this.selectedCurrency,
    this.selectedOwnership,
  });

  bool get isEmpty =>
      selectedEntryType == null &&
      query.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      selectedType == null &&
      selectedOwnerStatus == null &&
      selectedProvince == null &&
      selectedAdType == null &&
      selectedStatus == null &&
      selectedFinishing == null &&
      selectedFacade == null &&
      selectedDeedType == null &&
      minRooms == null &&
      maxRooms == null &&
      minArea == null &&
      maxArea == null &&
      selectedFloor == null &&
      hasGarden == null &&
      isDuplex == null &&
      selectedCurrency == null &&
      selectedOwnership == null;

  PropertyFilter copyWith({
    EntryType? Function()? selectedEntryType,
    String? query,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    String? Function()? selectedType,
    String? Function()? selectedOwnerStatus,
    String? Function()? selectedProvince,
    String? Function()? selectedAdType,
    String? Function()? selectedStatus,
    String? Function()? selectedFinishing,
    String? Function()? selectedFacade,
    String? Function()? selectedDeedType,
    int? Function()? minRooms,
    int? Function()? maxRooms,
    double? Function()? minArea,
    double? Function()? maxArea,
    String? Function()? selectedFloor,
    bool? Function()? hasGarden,
    bool? Function()? isDuplex,
    String? Function()? selectedCurrency,
    String? Function()? selectedOwnership,
  }) {
    return PropertyFilter(
      selectedEntryType: selectedEntryType != null
          ? selectedEntryType()
          : this.selectedEntryType,
      query: query ?? this.query,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      selectedType:
          selectedType != null ? selectedType() : this.selectedType,
      selectedOwnerStatus: selectedOwnerStatus != null
          ? selectedOwnerStatus()
          : this.selectedOwnerStatus,
      selectedProvince: selectedProvince != null
          ? selectedProvince()
          : this.selectedProvince,
      selectedAdType:
          selectedAdType != null ? selectedAdType() : this.selectedAdType,
      selectedStatus:
          selectedStatus != null ? selectedStatus() : this.selectedStatus,
      selectedFinishing: selectedFinishing != null
          ? selectedFinishing()
          : this.selectedFinishing,
      selectedFacade:
          selectedFacade != null ? selectedFacade() : this.selectedFacade,
      selectedDeedType: selectedDeedType != null
          ? selectedDeedType()
          : this.selectedDeedType,
      minRooms: minRooms != null ? minRooms() : this.minRooms,
      maxRooms: maxRooms != null ? maxRooms() : this.maxRooms,
      minArea: minArea != null ? minArea() : this.minArea,
      maxArea: maxArea != null ? maxArea() : this.maxArea,
      selectedFloor:
          selectedFloor != null ? selectedFloor() : this.selectedFloor,
      hasGarden: hasGarden != null ? hasGarden() : this.hasGarden,
      isDuplex: isDuplex != null ? isDuplex() : this.isDuplex,
      selectedCurrency: selectedCurrency != null
          ? selectedCurrency()
          : this.selectedCurrency,
      selectedOwnership: selectedOwnership != null
          ? selectedOwnership()
          : this.selectedOwnership,
    );
  }
}

final propertyFilterProvider =
    StateProvider<PropertyFilter>((ref) => const PropertyFilter());

// ════════════════════════════════════════════════════════
// allMatchesProvider — يعمل على Isolate منفصل
//
// بدلاً من حساب O(offers × requirements) على الخيط الرئيسي
// (مسبب تجميد الواجهة 2-3 ثوانٍ)، نستخدم Isolate.run()
// لنقل الحساب الثقيل إلى خلفية بدون فقدان أي إطار.
// ════════════════════════════════════════════════════════
final allMatchesProvider =
    FutureProvider<List<MatchResult>>((ref) async {
  final allProperties = ref.watch(propertyProvider);

  if (allProperties.isEmpty) return [];

  final offers = allProperties
      .where((p) => p.entryType == EntryType.offer)
      .toList();
  final requirements = allProperties
      .where((p) => p.entryType == EntryType.requirement)
      .toList();

  if (offers.isEmpty || requirements.isEmpty) return [];

  // Offload O(offers × requirements) to background isolate
  final results = await Isolate.run<List<Map<String, dynamic>>>(() {
    return _computeAllMatches(offers, requirements);
  });

  return results
      .map((m) => MatchResult(
            offer: PropertyModel.fromMap(m['offer'] as Map<String, dynamic>),
            requirement:
                PropertyModel.fromMap(m['requirement'] as Map<String, dynamic>),
            score: m['score'] as double,
            matchedCriteria:
                (m['matchedCriteria'] as List).cast<String>(),
          ))
      .toList();
});

/// Top-level function for isolate execution.
/// Pure Dart — no Flutter dependencies.
/// Converts PropertyModel to Map for SendPort serialization.
List<Map<String, dynamic>> _computeAllMatches(
  List<PropertyModel> offers,
  List<PropertyModel> requirements,
) {
  final results = <Map<String, dynamic>>[];

  for (final offer in offers) {
    for (final req in requirements) {
      final result = _evaluateIsolated(offer, req);
      if (result != null) results.add(result);
    }
  }

  results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  return results;
}

/// Isolated match evaluation — pure computation, no Flutter dependencies.
Map<String, dynamic>? _evaluateIsolated(
  PropertyModel offer,
  PropertyModel requirement,
) {
  const double priceTolerance = 0.20;
  const double minimumScore = 0.60;

  // Hard Criteria
  if (offer.province.isEmpty ||
      requirement.province.isEmpty ||
      offer.province != requirement.province) {
    return null;
  }
  if (offer.propertyType.isEmpty ||
      requirement.propertyType.isEmpty ||
      offer.propertyType != requirement.propertyType) {
    return null;
  }
  if (offer.adType.isEmpty ||
      requirement.adType.isEmpty ||
      offer.adType != requirement.adType) {
    return null;
  }

  // Soft Criteria
  double score = 0.60;
  final matched = <String>['المحافظة', 'نوع العقار', 'نوع الإعلان'];

  if (offer.price > 0 && requirement.price > 0) {
    final maxAcceptable = requirement.price * (1 + priceTolerance);
    if (offer.price <= maxAcceptable) {
      score += 0.20;
      matched.add('السعر ضمن الميزانية');
    } else if (offer.price > maxAcceptable * 1.5) {
      score -= 0.05;
    }
  } else {
    score += 0.10;
  }

  if (offer.region.isNotEmpty && requirement.region.isNotEmpty) {
    if (offer.region.trim().toLowerCase() ==
        requirement.region.trim().toLowerCase()) {
      score += 0.15;
      matched.add('المنطقة');
    }
  }

  if (offer.rooms > 0 && requirement.rooms > 0) {
    if ((offer.rooms - requirement.rooms).abs() <= 1) {
      score += 0.05;
      matched.add('عدد الغرف');
    }
  }

  final finalScore = score.clamp(0.0, 1.0);
  if (finalScore < minimumScore) return null;

  return {
    'offer': offer.toMap(),
    'requirement': requirement.toMap(),
    'score': finalScore,
    'matchedCriteria': matched,
  };
}

class PropertyStats {
  final int total;
  final int offers;
  final int requirements;
  final int available;
  final int sold;

  const PropertyStats({
    required this.total,
    required this.offers,
    required this.requirements,
    required this.available,
    required this.sold,
  });
}

final propertyStatsProvider = Provider<PropertyStats>((ref) {
  final all = ref.watch(propertyProvider);
  return PropertyStats(
    total: all.length,
    offers: all.where((p) => p.entryType == EntryType.offer).length,
    requirements: all.where((p) => p.entryType == EntryType.requirement).length,
    available: all.where((p) => p.status == 'متاح').length,
    sold: all.where((p) => p.status == 'مباع').length,
  );
});
