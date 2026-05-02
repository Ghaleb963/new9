import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/features/properties/providers/property_provider.dart';

void main() {
  group('PropertyFilter', () {
    group('isEmpty', () {
      test('should be true when no filters set', () {
        const filter = PropertyFilter();
        expect(filter.isEmpty, isTrue);
      });

      test('should be false when query is set', () {
        const filter = PropertyFilter(query: 'test');
        expect(filter.isEmpty, isFalse);
      });

      test('should be false when any filter is set', () {
        const f1 = PropertyFilter(minPrice: 1000);
        const f2 = PropertyFilter(selectedType: 'شقة');
        const f3 = PropertyFilter(hasGarden: true);
        const f4 = PropertyFilter(selectedProvince: 'دمشق');
        const f5 = PropertyFilter(minRooms: 2);

        expect(f1.isEmpty, isFalse);
        expect(f2.isEmpty, isFalse);
        expect(f3.isEmpty, isFalse);
        expect(f4.isEmpty, isFalse);
        expect(f5.isEmpty, isFalse);
      });
    });

    group('copyWith', () {
      test('should update specific fields', () {
        const original = PropertyFilter();

        final updated = original.copyWith(
          query: 'دمشق',
          minPrice: () => 5000,
          selectedType: () => 'شقة',
        );

        expect(updated.query, 'دمشق');
        expect(updated.minPrice, 5000);
        expect(updated.selectedType, 'شقة');
        expect(updated.maxPrice, isNull);
      });

      test('should allow setting values to null via Function()', () {
        final filter = const PropertyFilter().copyWith(
          selectedType: () => 'شقة',
          minPrice: () => 1000,
        );

        final cleared = filter.copyWith(
          selectedType: () => null,
          minPrice: () => null,
        );

        expect(cleared.selectedType, isNull);
        expect(cleared.minPrice, isNull);
      });

      test('should preserve values when not specified', () {
        final filter = const PropertyFilter().copyWith(
          query: 'test',
          selectedType: () => 'فيلا',
          minRooms: () => 3,
        );

        final partial = filter.copyWith(
          selectedType: () => 'شقة',
        );

        expect(partial.query, 'test');
        expect(partial.selectedType, 'شقة');
        expect(partial.minRooms, 3);
      });

      test('should handle all 19 filter fields', () {
        final filter = const PropertyFilter().copyWith(
          query: 'بحث',
          minPrice: () => 1000,
          maxPrice: () => 100000,
          selectedType: () => 'شقة',
          selectedOwnerStatus: () => 'شخص واحد',
          selectedProvince: () => 'دمشق',
          selectedAdType: () => 'بيع',
          selectedStatus: () => 'متاح',
          selectedFinishing: () => 'ممتاز',
          selectedFacade: () => 'أمامي',
          selectedDeedType: () => 'سكني',
          minRooms: () => 2,
          maxRooms: () => 5,
          minArea: () => 80.0,
          maxArea: () => 200.0,
          selectedFloor: () => '2',
          hasGarden: () => true,
          isDuplex: () => false,
          selectedCurrency: () => 'دولار',
          selectedOwnership: () => 'طابو أخضر',
        );

        expect(filter.query, 'بحث');
        expect(filter.minPrice, 1000);
        expect(filter.maxPrice, 100000);
        expect(filter.selectedType, 'شقة');
        expect(filter.selectedOwnerStatus, 'شخص واحد');
        expect(filter.selectedProvince, 'دمشق');
        expect(filter.selectedAdType, 'بيع');
        expect(filter.selectedStatus, 'متاح');
        expect(filter.selectedFinishing, 'ممتاز');
        expect(filter.selectedFacade, 'أمامي');
        expect(filter.selectedDeedType, 'سكني');
        expect(filter.minRooms, 2);
        expect(filter.maxRooms, 5);
        expect(filter.minArea, 80.0);
        expect(filter.maxArea, 200.0);
        expect(filter.selectedFloor, '2');
        expect(filter.hasGarden, true);
        expect(filter.isDuplex, false);
        expect(filter.selectedCurrency, 'دولار');
        expect(filter.selectedOwnership, 'طابو أخضر');
        expect(filter.isEmpty, isFalse);
      });
    });
  });
}
