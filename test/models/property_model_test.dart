import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/features/properties/models/property_model.dart';

PropertyModel _createSampleProperty({
  int? id,
  String adType = 'بيع',
  String propertyType = 'شقة',
  String province = 'دمشق',
  String region = 'المزة',
  int rooms = 3,
  double area = 120.0,
  double price = 50000,
  String status = 'متاح',
  bool hasGarden = false,
  bool isDuplex = false,
  List<String> directions = const ['غربي'],
  List<String> features = const ['مصعد'],
  List<String> images = const [],
}) {
  return PropertyModel(
    id: id,
    adType: adType,
    deedType: 'سكني',
    propertyType: propertyType,
    province: province,
    region: region,
    addressDetails: '',
    floor: '2',
    rooms: rooms,
    area: area,
    hasGarden: hasGarden,
    isDuplex: isDuplex,
    facade: 'أمامي',
    directions: directions,
    finishingLevel: 'ممتاز',
    features: features,
    ownershipType: 'طابو أخضر',
    ownershipDetails: '',
    price: price,
    currency: 'ليرة سورية',
    status: status,
    ownerName: '',
    ownerWhatsapp: '',
    officeName: '',
    contactPhone: '',
    facebookLink: '',
    notes: '',
    images: images,
    videos: [],
    ownerStatus: 'شخص واحد',
  );
}

void main() {
  group('PropertyModel', () {
    group('toMap / fromMap', () {
      test('should serialize and deserialize correctly', () {
        final property = _createSampleProperty(
          id: 1,
          rooms: 4,
          area: 150.5,
          price: 75000,
          hasGarden: true,
          isDuplex: true,
          directions: ['غربي', 'شرقي'],
          features: ['مصعد', 'تكييف'],
        );

        final map = property.toMap();
        final restored = PropertyModel.fromMap(map);

        expect(restored.id, 1);
        expect(restored.adType, 'بيع');
        expect(restored.propertyType, 'شقة');
        expect(restored.province, 'دمشق');
        expect(restored.region, 'المزة');
        expect(restored.rooms, 4);
        expect(restored.area, 150.5);
        expect(restored.price, 75000);
        expect(restored.hasGarden, true);
        expect(restored.isDuplex, true);
        expect(restored.directions, ['غربي', 'شرقي']);
        expect(restored.features, ['مصعد', 'تكييف']);
        expect(restored.status, 'متاح');
        expect(restored.currency, 'ليرة سورية');
        expect(restored.ownerStatus, 'شخص واحد');
      });

      test('should handle null id', () {
        final property = _createSampleProperty();
        final map = property.toMap();
        final restored = PropertyModel.fromMap(map);
        expect(restored.id, isNull);
      });

      test('should handle empty directions and features', () {
        final property = _createSampleProperty(
          directions: [],
          features: [],
        );

        final map = property.toMap();
        final restored = PropertyModel.fromMap(map);

        expect(restored.directions, isEmpty);
        expect(restored.features, isEmpty);
      });
    });

    group('fromMap null safety', () {
      test('should handle completely null map values', () {
        final map = <String, dynamic>{
          'id': null,
          'adType': null,
          'deedType': null,
          'propertyType': null,
          'province': null,
          'region': null,
          'addressDetails': null,
          'floor': null,
          'rooms': null,
          'area': null,
          'hasGarden': null,
          'isDuplex': null,
          'facade': null,
          'directions': null,
          'finishingLevel': null,
          'features': null,
          'ownershipType': null,
          'ownershipDetails': null,
          'sharesCount': null,
          'price': null,
          'currency': null,
          'status': null,
          'ownerName': null,
          'ownerWhatsapp': null,
          'officeName': null,
          'contactPhone': null,
          'facebookLink': null,
          'notes': null,
          'images': null,
          'videos': null,
          'ownerStatus': null,
        };

        final property = PropertyModel.fromMap(map);

        expect(property.id, isNull);
        expect(property.adType, '');
        expect(property.rooms, 0);
        expect(property.area, 0.0);
        expect(property.price, 0.0);
        expect(property.hasGarden, false);
        expect(property.isDuplex, false);
        expect(property.directions, isEmpty);
        expect(property.features, isEmpty);
        expect(property.images, isEmpty);
        expect(property.videos, isEmpty);
      });

      test('should handle empty string for JSON fields', () {
        final map = <String, dynamic>{
          'directions': '',
          'features': '',
          'images': '',
          'videos': '',
        };

        final property = PropertyModel.fromMap(map);

        expect(property.directions, isEmpty);
        expect(property.features, isEmpty);
        expect(property.images, isEmpty);
        expect(property.videos, isEmpty);
      });

      test('should handle invalid JSON for list fields', () {
        final map = <String, dynamic>{
          'directions': 'not valid json',
          'features': '{invalid}',
          'images': '123',
          'videos': 'abc',
        };

        final property = PropertyModel.fromMap(map);

        expect(property.directions, isEmpty);
        expect(property.features, isEmpty);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final original = _createSampleProperty(
          id: 1,
          status: 'متاح',
          price: 50000,
        );

        final updated = original.copyWith(
          status: 'مباع',
          price: 60000,
        );

        expect(updated.status, 'مباع');
        expect(updated.price, 60000);
        expect(updated.id, 1);
        expect(updated.adType, 'بيع');
        expect(updated.province, 'دمشق');
        expect(updated.rooms, 3);
      });

      test('should keep original values when no changes', () {
        final original = _createSampleProperty(id: 5, rooms: 4);
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.rooms, original.rooms);
        expect(copy.adType, original.adType);
        expect(copy.province, original.province);
      });
    });

    group('toMap', () {
      test('should convert boolean to int for SQLite', () {
        final property = _createSampleProperty(
          hasGarden: true,
          isDuplex: false,
        );

        final map = property.toMap();

        expect(map['hasGarden'], 1);
        expect(map['isDuplex'], 0);
      });

      test('should encode lists as JSON strings', () {
        final property = _createSampleProperty(
          directions: ['غربي', 'شرقي'],
          features: ['مصعد'],
          images: ['/path/to/img.jpg'],
        );

        final map = property.toMap();

        expect(map['directions'], isA<String>());
        expect(map['features'], isA<String>());
        expect(map['images'], isA<String>());
      });
    });

    group('toString', () {
      test('should return readable string', () {
        final property = _createSampleProperty(
          id: 1,
          propertyType: 'فيلا',
          region: 'المالكي',
          price: 100000,
        );

        final str = property.toString();

        expect(str, contains('id: 1'));
        expect(str, contains('type: فيلا'));
        expect(str, contains('region: المالكي'));
        expect(str, contains('price: 100000'));
      });
    });
  });
}
