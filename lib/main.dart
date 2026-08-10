import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/data_service.dart';
import 'services/storage_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/unit_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkCocoa,
    ),
  );

  final dataService = DataService();
  await dataService.loadAll();

  final storageService = StorageService();
  await storageService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DataService>.value(value: dataService),
        ChangeNotifierProvider<StorageService>.value(value: storageService),
      ],
      child: const UMT3033App(),
    ),
  );
}

class UMT3033App extends StatelessWidget {
  const UMT3033App({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final isDark = storage.theme == 'dark';

    return MaterialApp(
      title: 'Basic Arabic for Muamalat — UMT3033',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppColors.accent,
        scaffoldBackgroundColor: const Color(0xFFFFFAF6),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkCocoa,
          foregroundColor: AppColors.textOnDark,
          elevation: 0,
          scrolledUnderElevation: 4,
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textMid,
            side: const BorderSide(color: Color(0xFFBFA99A)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.warmWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.mutedBrown),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.accent,
        scaffoldBackgroundColor: const Color(0xFF1A0E07),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkCocoa,
          foregroundColor: AppColors.textOnDark,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2A1008),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _navigateToUnit(int unitId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UnitScreen(unitId: unitId)),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(onOpenUnit: _navigateToUnit),
          const Center(child: Text('Glosari — akan datang')),
          const Center(child: Text('Carian — akan datang')),
          const Center(child: Text('Catatan — akan datang')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.darkCocoa,
        indicatorColor: AppColors.accent,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppColors.mutedBrown),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.white),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: AppColors.mutedBrown),
            selectedIcon: Icon(Icons.menu_book, color: AppColors.white),
            label: 'Glosari',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search, color: AppColors.mutedBrown),
            selectedIcon: const Icon(Icons.search, color: AppColors.white),
            label: 'Cari',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined, color: AppColors.mutedBrown),
            selectedIcon: const Icon(Icons.settings, color: AppColors.white),
            label: 'Tetapan',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToSettings,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.settings),
        label: const Text('Tetapan'),
      ),
    );
  }
}
