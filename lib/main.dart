import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'features/properties/views/property_list_view.dart';
import 'features/properties/views/add_property_view.dart';
import 'features/properties/views/matches_screen.dart';
import 'features/properties/providers/property_provider.dart';
import 'features/settings/views/settings_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ProviderScope(child: RealEstateApp()));
}

class RealEstateApp extends StatelessWidget {
  const RealEstateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  // IndexedStack يحافظ على حالة كل شاشة دون إعادة بنائها عند التبديل
  static const List<Widget> _screens = [
    PropertyListView(),
    AddPropertyView(),
    MatchesScreen(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    // مراقبة عدد التوافقات للـ badge — يتحدث تلقائياً مع allMatchesProvider
    final matchCount = ref.watch(allMatchesProvider).length;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppTheme.emeraldGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // ضروري عند 4 تبويبات+
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'العقارات',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'إضافة',
          ),
          // التبويب الجديد مع badge يعرض عدد التوافقات
          BottomNavigationBarItem(
            icon: _MatchesBadgeIcon(
              count: matchCount,
              isSelected: false,
            ),
            activeIcon: _MatchesBadgeIcon(
              count: matchCount,
              isSelected: true,
            ),
            label: 'التوافقات',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

// Badge icon مخصص لتبويب التوافقات — يعرض العدد إذا كان > 0
class _MatchesBadgeIcon extends StatelessWidget {
  final int count;
  final bool isSelected;

  const _MatchesBadgeIcon({
    required this.count,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isSelected ? Icons.link_rounded : Icons.link_outlined,
          color: isSelected ? AppTheme.emeraldGreen : Colors.grey,
        ),
        if (count > 0)
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.grey[900]!, width: 1.5),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
