import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/property_model.dart';
import '../providers/property_provider.dart';
import 'match_results_view.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_form_widgets.dart';
import '../../../core/widgets/app_image_widgets.dart';
import '../../../core/widgets/match_notification_overlay.dart';
import '../widgets/add_property_widgets.dart';

// ════════════════════════════════════════════════════════
// ISOLATE ENTRY POINT — Image file saving off main thread
// ════════════════════════════════════════════════════════

/// Input data for isolate-based image saving.
/// All fields are serializable across isolate boundaries.
class _SaveMediaInput {
  final String mediaDirPath;
  final List<String> existingImagePaths;
  final List<String> newFilePaths;

  _SaveMediaInput({
    required this.mediaDirPath,
    required this.existingImagePaths,
    required this.newFilePaths,
  });
}

/// Saves images to disk inside an isolate.
/// Performs file I/O off the main thread to prevent frame drops.
Future<List<String>> _saveMediaInIsolate(_SaveMediaInput input) async {
  final mediaDir = Directory(input.mediaDirPath);
  if (!await mediaDir.exists()) {
    await mediaDir.create(recursive: true);
  }

  final savedPaths = List<String>.from(input.existingImagePaths);
  for (final filePath in input.newFilePaths) {
    final sourceFile = File(filePath);
    if (!await sourceFile.exists()) continue;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
    final savedFile = await sourceFile.copy('${mediaDir.path}/$fileName');
    savedPaths.add(savedFile.path);
  }
  return savedPaths;
}

class AddPropertyView extends ConsumerStatefulWidget {
  final PropertyModel? existingProperty;
  const AddPropertyView({super.key, this.existingProperty});

  @override
  ConsumerState<AddPropertyView> createState() => _AddPropertyViewState();
}

class _AddPropertyViewState extends ConsumerState<AddPropertyView> {
  final _formKey = GlobalKey<FormState>();

  late EntryType entryType;

  late String adType;
  late String propertyType;
  late String province;
  final regionController = TextEditingController();
  final roomsController = TextEditingController();
  final areaController = TextEditingController();
  final priceController = TextEditingController();
  late String currency;
  final notesController = TextEditingController();

  late String deedType;
  final addressController = TextEditingController();
  final floorController = TextEditingController();
  late bool hasGarden;
  late bool isDuplex;
  late String facade;
  late List<String> selectedDirections;
  late String finishingLevel;
  late List<String> selectedFeatures;
  late String ownershipType;
  final ownershipDetailsController = TextEditingController();
  final sharesController = TextEditingController();
  late String status;
  late String ownerStatus;
  final ownerNameController = TextEditingController();
  final ownerWhatsappController = TextEditingController();
  final officeNameController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final fbLinkController = TextEditingController();
  List<File> images = [];
  List<String> existingImagePaths = [];

  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  bool get isEditing => widget.existingProperty != null;
  bool get isOffer => entryType == EntryType.offer;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProperty;

    entryType = p?.entryType ?? EntryType.offer;
    adType = p?.adType ?? 'بيع';
    deedType = p?.deedType ?? 'سكني';
    propertyType = p?.propertyType ?? 'شقة';
    province = p?.province ?? 'دمشق';
    regionController.text = p?.region ?? '';
    addressController.text = p?.addressDetails ?? '';
    floorController.text = p?.floor ?? '';
    roomsController.text = p != null && p.rooms > 0 ? '${p.rooms}' : '';
    areaController.text = p != null && p.area > 0 ? '${p.area}' : '';
    hasGarden = p?.hasGarden ?? false;
    isDuplex = p?.isDuplex ?? false;
    facade = p?.facade ?? 'أمامي';
    selectedDirections = List<String>.from(p?.directions ?? []);
    finishingLevel = p?.finishingLevel ?? 'ممتاز';
    selectedFeatures = List<String>.from(p?.features ?? []);
    ownershipType = p?.ownershipType ?? 'طابو أخضر';
    ownershipDetailsController.text = p?.ownershipDetails ?? '';
    sharesController.text = p?.sharesCount != null ? '${p!.sharesCount}' : '';
    priceController.text = p != null && p.price > 0 ? '${p.price}' : '';
    currency = p?.currency ?? 'ليرة سورية';
    status = p?.status ?? 'متاح';
    ownerNameController.text = p?.ownerName ?? '';
    ownerWhatsappController.text = p?.ownerWhatsapp ?? '';
    officeNameController.text = p?.officeName ?? '';
    contactPhoneController.text = p?.contactPhone ?? '';
    fbLinkController.text = p?.facebookLink ?? '';
    notesController.text = p?.notes ?? '';
    ownerStatus = p?.ownerStatus ?? 'شخص واحد';
    existingImagePaths = List<String>.from(p?.images ?? []);
  }

  @override
  void dispose() {
    regionController.dispose();
    addressController.dispose();
    floorController.dispose();
    roomsController.dispose();
    areaController.dispose();
    ownershipDetailsController.dispose();
    sharesController.dispose();
    priceController.dispose();
    ownerNameController.dispose();
    ownerWhatsappController.dispose();
    officeNameController.dispose();
    contactPhoneController.dispose();
    fbLinkController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  /// Saves images to disk using Isolate.run() — zero main-thread blocking.
  Future<List<String>> _saveMediaLocally() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDirPath = '${appDir.path}/property_images';

    final input = _SaveMediaInput(
      mediaDirPath: mediaDirPath,
      existingImagePaths: List<String>.from(existingImagePaths),
      newFilePaths: images.map((f) => f.path).toList(),
    );

    return Isolate.run<List<String>>(() => _saveMediaInIsolate(input));
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      entryType = EntryType.offer;
      adType = 'بيع';
      deedType = 'سكني';
      propertyType = 'شقة';
      province = 'دمشق';
      regionController.clear();
      addressController.clear();
      floorController.clear();
      roomsController.clear();
      areaController.clear();
      hasGarden = false;
      isDuplex = false;
      facade = 'أمامي';
      selectedDirections.clear();
      finishingLevel = 'ممتاز';
      selectedFeatures.clear();
      ownershipType = 'طابو أخضر';
      ownershipDetailsController.clear();
      sharesController.clear();
      priceController.clear();
      currency = 'ليرة سورية';
      status = 'متاح';
      ownerNameController.clear();
      ownerWhatsappController.clear();
      officeNameController.clear();
      contactPhoneController.clear();
      fbLinkController.clear();
      notesController.clear();
      ownerStatus = 'شخص واحد';
      images.clear();
      existingImagePaths.clear();
    });
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final savedImages = isOffer ? await _saveMediaLocally() : [];

      final property = PropertyModel(
        id: widget.existingProperty?.id,
        entryType: entryType,
        adType: adType,
        deedType: isOffer ? deedType : '',
        propertyType: propertyType,
        province: province,
        region: regionController.text,
        addressDetails: isOffer ? addressController.text : '',
        floor: isOffer ? floorController.text : '',
        rooms: int.tryParse(roomsController.text) ?? 0,
        area: double.tryParse(areaController.text) ?? 0,
        hasGarden: isOffer ? hasGarden : false,
        isDuplex: isOffer ? isDuplex : false,
        facade: isOffer ? facade : '',
        directions: isOffer ? List<String>.from(selectedDirections) : [],
        finishingLevel: isOffer ? finishingLevel : '',
        features: isOffer ? List<String>.from(selectedFeatures) : [],
        ownershipType: isOffer ? ownershipType : '',
        ownershipDetails: isOffer ? ownershipDetailsController.text : '',
        sharesCount: isOffer ? int.tryParse(sharesController.text) : null,
        price: double.tryParse(priceController.text) ?? 0,
        currency: currency,
        status: isOffer ? status : '',
        ownerName: ownerNameController.text,
        ownerWhatsapp: ownerWhatsappController.text,
        officeName: isOffer ? officeNameController.text : '',
        contactPhone: contactPhoneController.text,
        facebookLink: isOffer ? fbLinkController.text : '',
        notes: notesController.text,
        images: List<String>.from(savedImages),
        videos: widget.existingProperty?.videos ?? [],
        ownerStatus: isOffer ? ownerStatus : '',
      );

      if (isEditing) {
        await ref.read(propertyProvider.notifier).updateProperty(property);
        if (!mounted) return;
        messenger.showSnackBar(
            const SnackBar(content: Text('تم تحديث السجل بنجاح')));
        Navigator.pop(context, true);
      } else {
        await ref.read(propertyProvider.notifier).addProperty(property);
        if (!mounted) return;

        messenger
            .showSnackBar(const SnackBar(content: Text('تمت الإضافة بنجاح')));

        final matches = ref.read(propertyProvider.notifier).findMatchesFor(property);

        if (matches != null && matches.isNotEmpty && mounted) {
          final ctx = context;
          final originProperty = property;

          showMatchNotification(
            context,
            matches: matches,
            onViewMatches: (results) {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => MatchResultsView(
                    matches: results,
                    originProperty: originProperty,
                  ),
                ),
              );
            },
          );
        }

        _resetForm();
      }
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل السجل' : 'إضافة سجل جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.sp16),
          children: [
            EntryTypeSelector(
              selected: entryType,
              onChanged: (type) => setState(() {
                entryType = type;
                status = 'متاح';
                deedType = 'سكني';
              }),
            ),
            const SizedBox(height: AppTheme.sp8),

            AppFormSection(
              title: isOffer ? 'نوع الإعلان' : 'نوع الطلب',
              children: [
                AppSmartButtons(
                    label: isOffer
                        ? 'نوع الإعلان'
                        : 'نوع العقار المطلوب (بيع/إيجار)',
                    items: AppConstants.adTypes,
                    selectedValue: adType,
                    onChanged: (val) => setState(() => adType = val)),
                AppSmartButtons(
                    label: 'نوع العقار',
                    items: AppConstants.propertyTypes,
                    selectedValue: propertyType,
                    onChanged: (val) => setState(() => propertyType = val)),
              ],
            ),

            AppFormSection(
              title: isOffer ? 'الموقع' : 'الموقع المطلوب',
              children: [
                AppDropdown(
                    label: 'المحافظة',
                    items: AppConstants.provinces,
                    value: province,
                    onChanged: (val) => setState(() => province = val!)),
                AppTextField(
                    controller: regionController,
                    label: isOffer ? 'المنطقة' : 'المنطقة المفضلة (اختياري)'),
              ],
            ),

            AppFormSection(
              title: isOffer ? 'المساحة والغرف' : 'المواصفات المطلوبة',
              children: [
                AppTextField(
                    controller: roomsController,
                    label: isOffer ? 'عدد الغرف' : 'عدد الغرف المطلوب',
                    isNumber: true),
                AppTextField(
                    controller: areaController,
                    label: isOffer ? 'المساحة (م2)' : 'المساحة المطلوبة (م2)',
                    isNumber: true),
              ],
            ),

            AppFormSection(
              title: isOffer ? 'السعر' : 'الميزانية القصوى',
              children: [
                AppTextField(
                    controller: priceController,
                    label: isOffer ? 'السعر' : 'الميزانية القصوى',
                    isNumber: true),
                AppDropdown(
                    label: 'العملة',
                    items: AppConstants.currencies,
                    value: currency,
                    onChanged: (val) => setState(() => currency = val!)),
              ],
            ),

            if (isOffer) ...[
              AppFormSection(title: 'نوع السند', children: [
                AppSmartButtons(
                    label: 'نوع السند',
                    items: AppConstants.deedTypes,
                    selectedValue: deedType,
                    onChanged: (val) => setState(() => deedType = val)),
              ]),
              AppFormSection(title: 'تفاصيل العنوان', children: [
                AppTextField(
                    controller: addressController, label: 'تفاصيل العنوان'),
                AppTextField(controller: floorController, label: 'الطابق'),
                CheckboxListTile(
                    title: const Text('حديقة'),
                    value: hasGarden,
                    onChanged: (val) => setState(() => hasGarden = val!)),
                CheckboxListTile(
                    title: const Text('دوبلكس'),
                    value: isDuplex,
                    onChanged: (val) => setState(() => isDuplex = val!)),
              ]),
              AppFormSection(title: 'الواجهة', children: [
                AppDropdown(
                    label: 'الواجهة',
                    items: AppConstants.facadeTypes,
                    value: facade,
                    onChanged: (val) => setState(() => facade = val!)),
              ]),
              AppFormSection(title: 'الاتجاهات', children: [
                AppMultiSelect(
                    items: AppConstants.directions,
                    selectedItems: selectedDirections,
                    onToggle: (val) => setState(() =>
                        selectedDirections.contains(val)
                            ? selectedDirections.remove(val)
                            : selectedDirections.add(val))),
              ]),
              AppFormSection(title: 'مستوى الإكساء', children: [
                AppDropdown(
                    label: 'الإكساء',
                    items: AppConstants.finishingLevels,
                    value: finishingLevel,
                    onChanged: (val) => setState(() => finishingLevel = val!)),
              ]),
              AppFormSection(title: 'الميزات', children: [
                AppMultiSelect(
                    items: AppConstants.featuresList,
                    selectedItems: selectedFeatures,
                    onToggle: (val) => setState(() =>
                        selectedFeatures.contains(val)
                            ? selectedFeatures.remove(val)
                            : selectedFeatures.add(val))),
              ]),
              AppFormSection(title: 'حالة الملكية', children: [
                AppDropdown(
                    label: 'الملكية',
                    items: AppConstants.ownerStatuses,
                    value: ownerStatus,
                    onChanged: (val) => setState(() => ownerStatus = val!)),
              ]),
              AppFormSection(title: 'نوع الملكية', children: [
                AppDropdown(
                    label: 'الملكية',
                    items: AppConstants.ownershipTypes,
                    value: ownershipType,
                    onChanged: (val) => setState(() => ownershipType = val!)),
                AppTextField(
                    controller: ownershipDetailsController,
                    label: 'تفاصيل الملكية الأخرى'),
                AppTextField(
                    controller: sharesController,
                    label: 'عدد الأسهم',
                    isNumber: true),
              ]),
              AppFormSection(title: 'حالة العقار', children: [
                AppDropdown(
                    label: 'الحالة',
                    items: AppConstants.statusList,
                    value: status,
                    onChanged: (val) => setState(() => status = val!)),
              ]),
            ],

            AppFormSection(
              title: isOffer ? 'معلومات المالك (خاصة)' : 'معلومات الباحث',
              children: [
                AppTextField(
                    controller: ownerNameController,
                    label: isOffer ? 'اسم المالك' : 'اسم الباحث'),
                AppTextField(
                    controller: contactPhoneController,
                    label: isOffer ? 'هاتف الاتصال' : 'هاتف الباحث'),
                AppTextField(
                    controller: ownerWhatsappController,
                    label: isOffer ? 'واتساب المالك' : 'واتساب الباحث'),
                if (isOffer) ...[
                  AppTextField(
                      controller: officeNameController, label: 'اسم المكتب'),
                  AppTextField(
                      controller: fbLinkController, label: 'رابط فيسبوك'),
                ],
              ],
            ),

            AppFormSection(title: 'ملاحظات', children: [
              AppTextField(
                  controller: notesController,
                  label: isOffer
                      ? 'ملاحظات إضافية عن العقار'
                      : 'تفاصيل إضافية عن متطلبات الباحث',
                  maxLines: 3),
            ]),

            if (isOffer)
              AppFormSection(title: 'الوسائط', children: [
                ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.image),
                    label: const Text('رفع صور')),
                if (existingImagePaths.isNotEmpty || images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...existingImagePaths.asMap().entries.map(
                              (entry) => AppImageTile(
                                image: Image.file(File(entry.value),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image)),
                                onRemove: () => setState(() =>
                                    existingImagePaths.removeAt(entry.key)),
                              ),
                            ),
                        ...images.asMap().entries.map(
                              (entry) => AppImageTile(
                                image: Image.file(entry.value,
                                    width: 80, height: 80, fit: BoxFit.cover),
                                onRemove: () =>
                                    setState(() => images.removeAt(entry.key)),
                              ),
                            ),
                      ],
                    ),
                  ),
              ]),

            const SizedBox(height: AppTheme.sp20),
            ElevatedButton(
              onPressed: _isSaving ? null : _submitProperty,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.sp12),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.textOnAccent))
                    : Text(isEditing ? 'حفظ التعديلات' : 'إضافة السجل',
                        style: const TextStyle(fontSize: AppTheme.fontLg)),
              ),
            ),
            const SizedBox(height: AppTheme.sp40),
          ],
        ),
      ),
    );
  }
}
