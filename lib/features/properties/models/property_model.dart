import 'dart:convert';
import '../../../core/constants/app_constants.dart';

class PropertyModel {
  final int? id;

  // [جديد] التصنيف الجذري للإدخال: عرض أو طلب.
  // يُحدد طبيعة السجل بالكامل ويؤثر على منطق العرض والفلترة.
  final EntryType entryType;

  final String adType;
  final String deedType;
  final String propertyType;
  final String province;
  final String region;
  final String addressDetails;
  final String floor;
  final int rooms;
  final double area;
  final bool hasGarden;
  final bool isDuplex;
  final String facade;
  final List<String> directions;
  final String finishingLevel;
  final List<String> features;
  final String ownershipType;
  final String ownershipDetails;
  final int? sharesCount;
  final double price;
  final String currency;
  final String status;
  final String ownerName;
  final String ownerWhatsapp;
  final String officeName;
  final String contactPhone;
  final String facebookLink;
  final String notes;
  final List<String> images;
  final List<String> videos;
  final String ownerStatus;

  PropertyModel({
    this.id,
    this.entryType = EntryType.offer, // افتراضي: عرض — للتوافق مع السجلات القديمة
    required this.adType,
    required this.deedType,
    required this.propertyType,
    required this.province,
    required this.region,
    required this.addressDetails,
    required this.floor,
    required this.rooms,
    required this.area,
    required this.hasGarden,
    required this.isDuplex,
    required this.facade,
    required this.directions,
    required this.finishingLevel,
    required this.features,
    required this.ownershipType,
    required this.ownershipDetails,
    this.sharesCount,
    required this.price,
    required this.currency,
    required this.status,
    required this.ownerName,
    required this.ownerWhatsapp,
    required this.officeName,
    required this.contactPhone,
    required this.facebookLink,
    required this.notes,
    required this.images,
    required this.videos,
    required this.ownerStatus,
  });

  PropertyModel copyWith({
    int? id,
    EntryType? entryType,
    String? adType,
    String? deedType,
    String? propertyType,
    String? province,
    String? region,
    String? addressDetails,
    String? floor,
    int? rooms,
    double? area,
    bool? hasGarden,
    bool? isDuplex,
    String? facade,
    List<String>? directions,
    String? finishingLevel,
    List<String>? features,
    String? ownershipType,
    String? ownershipDetails,
    int? sharesCount,
    double? price,
    String? currency,
    String? status,
    String? ownerName,
    String? ownerWhatsapp,
    String? officeName,
    String? contactPhone,
    String? facebookLink,
    String? notes,
    List<String>? images,
    List<String>? videos,
    String? ownerStatus,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      entryType: entryType ?? this.entryType,
      adType: adType ?? this.adType,
      deedType: deedType ?? this.deedType,
      propertyType: propertyType ?? this.propertyType,
      province: province ?? this.province,
      region: region ?? this.region,
      addressDetails: addressDetails ?? this.addressDetails,
      floor: floor ?? this.floor,
      rooms: rooms ?? this.rooms,
      area: area ?? this.area,
      hasGarden: hasGarden ?? this.hasGarden,
      isDuplex: isDuplex ?? this.isDuplex,
      facade: facade ?? this.facade,
      directions: directions ?? this.directions,
      finishingLevel: finishingLevel ?? this.finishingLevel,
      features: features ?? this.features,
      ownershipType: ownershipType ?? this.ownershipType,
      ownershipDetails: ownershipDetails ?? this.ownershipDetails,
      sharesCount: sharesCount ?? this.sharesCount,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      ownerName: ownerName ?? this.ownerName,
      ownerWhatsapp: ownerWhatsapp ?? this.ownerWhatsapp,
      officeName: officeName ?? this.officeName,
      contactPhone: contactPhone ?? this.contactPhone,
      facebookLink: facebookLink ?? this.facebookLink,
      notes: notes ?? this.notes,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      ownerStatus: ownerStatus ?? this.ownerStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // تخزين EntryType كـ String في DB عبر Extension (لا magic numbers)
      'entry_type': entryType.value,
      'adType': adType,
      'deedType': deedType,
      'propertyType': propertyType,
      'province': province,
      'region': region,
      'addressDetails': addressDetails,
      'floor': floor,
      'rooms': rooms,
      'area': area,
      'hasGarden': hasGarden ? 1 : 0,
      'isDuplex': isDuplex ? 1 : 0,
      'facade': facade,
      'directions': jsonEncode(directions),
      'finishingLevel': finishingLevel,
      'features': jsonEncode(features),
      'ownershipType': ownershipType,
      'ownershipDetails': ownershipDetails,
      'sharesCount': sharesCount,
      'price': price,
      'currency': currency,
      'status': status,
      'ownerName': ownerName,
      'ownerWhatsapp': ownerWhatsapp,
      'officeName': officeName,
      'contactPhone': contactPhone,
      'facebookLink': facebookLink,
      'notes': notes,
      'images': jsonEncode(images),
      'videos': jsonEncode(videos),
      'ownerStatus': ownerStatus,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'] as int?,
      // قراءة entry_type مع Fallback آمن 'offer' للسجلات القديمة قبل الـ migration
      entryType: ((map['entry_type'] as String?) ?? 'offer').toEntryType(),
      adType: (map['adType'] as String?) ?? '',
      deedType: (map['deedType'] as String?) ?? '',
      propertyType: (map['propertyType'] as String?) ?? '',
      province: (map['province'] as String?) ?? '',
      region: (map['region'] as String?) ?? '',
      addressDetails: (map['addressDetails'] as String?) ?? '',
      floor: (map['floor'] as String?) ?? '',
      rooms: (map['rooms'] as int?) ?? 0,
      area: (map['area'] as num?)?.toDouble() ?? 0.0,
      hasGarden: map['hasGarden'] == 1,
      isDuplex: map['isDuplex'] == 1,
      facade: (map['facade'] as String?) ?? '',
      directions: _decodeStringList(map['directions']),
      finishingLevel: (map['finishingLevel'] as String?) ?? '',
      features: _decodeStringList(map['features']),
      ownershipType: (map['ownershipType'] as String?) ?? '',
      ownershipDetails: (map['ownershipDetails'] as String?) ?? '',
      sharesCount: map['sharesCount'] as int?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] as String?) ?? '',
      status: (map['status'] as String?) ?? '',
      ownerName: (map['ownerName'] as String?) ?? '',
      ownerWhatsapp: (map['ownerWhatsapp'] as String?) ?? '',
      officeName: (map['officeName'] as String?) ?? '',
      contactPhone: (map['contactPhone'] as String?) ?? '',
      facebookLink: (map['facebookLink'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      images: _decodeStringList(map['images']),
      videos: _decodeStringList(map['videos']),
      ownerStatus: (map['ownerStatus'] as String?) ?? '',
    );
  }

  static List<String> _decodeStringList(dynamic value) {
    if (value == null || value == '') return [];
    try {
      return List<String>.from(jsonDecode(value as String));
    } catch (_) {
      return [];
    }
  }

  @override
  String toString() => 'PropertyModel(id: $id, entryType: ${entryType.label}, '
      'type: $propertyType, region: $region, price: $price $currency)';
}
