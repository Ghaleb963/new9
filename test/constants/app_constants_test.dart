import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('should have 14 provinces', () {
      expect(AppConstants.provinces.length, 14);
      expect(AppConstants.provinces, contains('دمشق'));
      expect(AppConstants.provinces, contains('حلب'));
      expect(AppConstants.provinces, contains('اللاذقية'));
    });

    test('should have 11 property types', () {
      expect(AppConstants.propertyTypes.length, 11);
      expect(AppConstants.propertyTypes, contains('شقة'));
      expect(AppConstants.propertyTypes, contains('فيلا'));
      expect(AppConstants.propertyTypes, contains('أرض'));
    });

    test('should have 9 facade types', () {
      expect(AppConstants.facadeTypes.length, 9);
      expect(AppConstants.facadeTypes, contains('أمامي'));
    });

    test('should have 7 finishing levels', () {
      expect(AppConstants.finishingLevels.length, 7);
      expect(AppConstants.finishingLevels, contains('عظم'));
      expect(AppConstants.finishingLevels, contains('ممتاز'));
      expect(AppConstants.finishingLevels, contains('سوبر'));
    });

    test('should have 4 directions', () {
      expect(AppConstants.directions.length, 4);
      expect(AppConstants.directions, contains('غربي'));
      expect(AppConstants.directions, contains('شرقي'));
    });

    test('should have 10 features', () {
      expect(AppConstants.featuresList.length, 10);
      expect(AppConstants.featuresList, contains('مصعد'));
      expect(AppConstants.featuresList, contains('تكييف'));
    });

    test('should have 3 ownership types', () {
      expect(AppConstants.ownershipTypes.length, 3);
      expect(AppConstants.ownershipTypes, contains('طابو أخضر'));
    });

    test('should have 2 currencies', () {
      expect(AppConstants.currencies.length, 2);
      expect(AppConstants.currencies, contains('ليرة سورية'));
      expect(AppConstants.currencies, contains('دولار'));
    });

    test('should have 3 statuses', () {
      expect(AppConstants.statusList.length, 3);
      expect(AppConstants.statusList, contains('متاح'));
      expect(AppConstants.statusList, contains('مؤجر'));
      expect(AppConstants.statusList, contains('مباع'));
    });

    test('should have 2 ad types', () {
      expect(AppConstants.adTypes.length, 2);
      expect(AppConstants.adTypes, contains('بيع'));
      expect(AppConstants.adTypes, contains('إيجار'));
    });

    test('should have 3 deed types', () {
      expect(AppConstants.deedTypes.length, 3);
      expect(AppConstants.deedTypes, contains('سكني'));
      expect(AppConstants.deedTypes, contains('تجاري'));
      expect(AppConstants.deedTypes, contains('زراعي'));
    });

    test('should have 2 owner statuses', () {
      expect(AppConstants.ownerStatuses.length, 2);
      expect(AppConstants.ownerStatuses, contains('شخص واحد'));
      expect(AppConstants.ownerStatuses, contains('ورثة'));
    });

    test('free property limit should be 2', () {
      expect(AppConstants.freePropertyLimit, 2);
    });

    test('no list should have duplicates', () {
      void checkNoDuplicates(List<String> list, String name) {
        final unique = list.toSet();
        expect(unique.length, list.length,
            reason: '$name has duplicates');
      }

      checkNoDuplicates(AppConstants.provinces, 'provinces');
      checkNoDuplicates(AppConstants.propertyTypes, 'propertyTypes');
      checkNoDuplicates(AppConstants.facadeTypes, 'facadeTypes');
      checkNoDuplicates(AppConstants.finishingLevels, 'finishingLevels');
      checkNoDuplicates(AppConstants.directions, 'directions');
      checkNoDuplicates(AppConstants.featuresList, 'featuresList');
      checkNoDuplicates(AppConstants.ownershipTypes, 'ownershipTypes');
      checkNoDuplicates(AppConstants.currencies, 'currencies');
      checkNoDuplicates(AppConstants.statusList, 'statusList');
      checkNoDuplicates(AppConstants.adTypes, 'adTypes');
      checkNoDuplicates(AppConstants.deedTypes, 'deedTypes');
      checkNoDuplicates(AppConstants.ownerStatuses, 'ownerStatuses');
    });

    test('no list should be empty', () {
      expect(AppConstants.provinces, isNotEmpty);
      expect(AppConstants.propertyTypes, isNotEmpty);
      expect(AppConstants.facadeTypes, isNotEmpty);
      expect(AppConstants.finishingLevels, isNotEmpty);
      expect(AppConstants.directions, isNotEmpty);
      expect(AppConstants.featuresList, isNotEmpty);
      expect(AppConstants.ownershipTypes, isNotEmpty);
      expect(AppConstants.currencies, isNotEmpty);
      expect(AppConstants.statusList, isNotEmpty);
      expect(AppConstants.adTypes, isNotEmpty);
      expect(AppConstants.deedTypes, isNotEmpty);
      expect(AppConstants.ownerStatuses, isNotEmpty);
    });
  });
}
