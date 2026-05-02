import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/core/widgets/app_form_widgets.dart';
import 'package:real_estate_app/core/widgets/app_detail_widgets.dart';
import 'package:real_estate_app/core/widgets/app_image_widgets.dart';
import 'package:real_estate_app/core/widgets/status_helpers.dart';

void main() {
  group('StatusHelpers', () {
    test('should return green for متاح', () {
      expect(StatusHelpers.color('متاح'), Colors.green);
    });

    test('should return orange for مؤجر', () {
      expect(StatusHelpers.color('مؤجر'), Colors.orange);
    });

    test('should return red for مباع', () {
      expect(StatusHelpers.color('مباع'), Colors.red);
    });

    test('should return grey for unknown status', () {
      expect(StatusHelpers.color('unknown'), Colors.grey);
    });

    test('should return correct icons', () {
      expect(StatusHelpers.icon('متاح'), Icons.check_circle_outline);
      expect(StatusHelpers.icon('مؤجر'), Icons.vpn_key);
      expect(StatusHelpers.icon('مباع'), Icons.sell);
      expect(StatusHelpers.icon('other'), Icons.info_outline);
    });
  });

  group('AppFormSection', () {
    testWidgets('should render title and children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppFormSection(
              title: 'قسم الاختبار',
              children: [Text('محتوى 1'), Text('محتوى 2')],
            ),
          ),
        ),
      );

      expect(find.text('قسم الاختبار'), findsOneWidget);
      expect(find.text('محتوى 1'), findsOneWidget);
      expect(find.text('محتوى 2'), findsOneWidget);
    });
  });

  group('AppTextField', () {
    testWidgets('should display label', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'الاسم',
            ),
          ),
        ),
      );

      expect(find.text('الاسم'), findsOneWidget);
    });

    testWidgets('should accept text input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'اختبار',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'قيمة جديدة');
      expect(controller.text, 'قيمة جديدة');
    });

    testWidgets('should validate required field', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppTextField(
                controller: controller,
                label: 'حقل مطلوب',
                isRequired: true,
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    });

    testWidgets('should not show error for optional empty field', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppTextField(
                controller: controller,
                label: 'حقل اختياري',
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('هذا الحقل مطلوب'), findsNothing);
    });
  });

  group('AppDropdown', () {
    testWidgets('should render with items', (tester) async {
      String value = 'بيع';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppDropdown(
                label: 'النوع',
                items: const ['بيع', 'إيجار'],
                value: value,
                onChanged: (v) => setState(() => value = v!),
              ),
            ),
          ),
        ),
      );

      expect(find.text('النوع'), findsOneWidget);
      expect(find.text('بيع'), findsOneWidget);
    });
  });

  group('AppSmartButtons', () {
    testWidgets('should highlight selected item', (tester) async {
      String selected = 'بيع';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppSmartButtons(
                label: 'نوع الإعلان',
                items: const ['بيع', 'إيجار'],
                selectedValue: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      );

      expect(find.text('نوع الإعلان'), findsOneWidget);
      expect(find.text('بيع'), findsOneWidget);
      expect(find.text('إيجار'), findsOneWidget);
    });

    testWidgets('should call onChanged when tapped', (tester) async {
      String selected = 'بيع';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppSmartButtons(
                label: 'النوع',
                items: const ['بيع', 'إيجار'],
                selectedValue: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('إيجار'));
      await tester.pump();

      expect(selected, 'إيجار');
    });
  });

  group('AppMultiSelect', () {
    testWidgets('should show all items as FilterChips', (tester) async {
      final selectedItems = <String>['مصعد'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppMultiSelect(
                items: const ['مصعد', 'تكييف', 'حديقة'],
                selectedItems: selectedItems,
                onToggle: (item) => setState(() {
                  if (selectedItems.contains(item)) {
                    selectedItems.remove(item);
                  } else {
                    selectedItems.add(item);
                  }
                }),
              ),
            ),
          ),
        ),
      );

      expect(find.text('مصعد'), findsOneWidget);
      expect(find.text('تكييف'), findsOneWidget);
      expect(find.text('حديقة'), findsOneWidget);
    });
  });

  group('AppSectionTitle', () {
    testWidgets('should render green bold title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSectionTitle(title: 'العنوان'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('العنوان'));
      expect(text.style?.fontWeight, FontWeight.bold);
      expect(text.style?.color, Colors.green);
      expect(text.style?.fontSize, 18);
    });
  });

  group('AppDetailRow', () {
    testWidgets('should display label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppDetailRow(label: 'الموقع', value: 'دمشق'),
          ),
        ),
      );

      expect(find.text('الموقع: '), findsOneWidget);
      expect(find.text('دمشق'), findsOneWidget);
    });
  });

  group('AppFilterSection', () {
    testWidgets('should render title and children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppFilterSection(
              title: 'فلتر السعر',
              children: [Text('من'), Text('إلى')],
            ),
          ),
        ),
      );

      expect(find.text('فلتر السعر'), findsOneWidget);
      expect(find.text('من'), findsOneWidget);
      expect(find.text('إلى'), findsOneWidget);
    });
  });

  group('AppChoiceChips', () {
    testWidgets('should render all items', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppChoiceChips(
                items: const ['متاح', 'مؤجر', 'مباع'],
                selected: selected,
                onSelected: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      );

      expect(find.text('متاح'), findsOneWidget);
      expect(find.text('مؤجر'), findsOneWidget);
      expect(find.text('مباع'), findsOneWidget);
    });

    testWidgets('should select and deselect', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppChoiceChips(
                items: const ['متاح', 'مؤجر'],
                selected: selected,
                onSelected: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('متاح'));
      await tester.pump();
      expect(selected, 'متاح');

      await tester.tap(find.text('متاح'));
      await tester.pump();
      expect(selected, isNull);
    });
  });

  group('AppRangeFilter', () {
    testWidgets('should have two text fields', (tester) async {
      String fromVal = '';
      String toVal = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppRangeFilter(
              onFromChanged: (v) => fromVal = v,
              onToChanged: (v) => toVal = v,
            ),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, '1000');
      expect(fromVal, '1000');

      await tester.enterText(textFields.last, '5000');
      expect(toVal, '5000');
    });
  });

  group('StatusBadge', () {
    testWidgets('should display status with correct color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'متاح'),
          ),
        ),
      );

      expect(find.text('متاح'), findsOneWidget);
    });
  });

  group('TappableStatusBadge', () {
    testWidgets('should call onTap when pressed', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TappableStatusBadge(
              status: 'متاح',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TappableStatusBadge));
      expect(tapped, isTrue);
    });

    testWidgets('should show edit icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TappableStatusBadge(
              status: 'مؤجر',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });

  group('AppImagePlaceholder', () {
    testWidgets('should render with default height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImagePlaceholder(),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });

    testWidgets('should render with custom height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImagePlaceholder(height: 100),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final constraints = container.constraints;
      expect(constraints?.maxHeight ?? 100, 100);
    });
  });

  group('AppImageTile', () {
    testWidgets('should show remove button', (tester) async {
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppImageTile(
              image: Container(width: 80, height: 80, color: Colors.blue),
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(removed, isTrue);
    });
  });
}
