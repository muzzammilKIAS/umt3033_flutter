import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/data_service.dart';
import 'services/storage_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/unit_screen.dart';
import 'screens/glossary_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.mistBackground,
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

  ThemeMode _themeMode(String pref) {
    switch (pref) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    return MaterialApp(
      title: 'Basic Arabic for Muamalat — UMT3033',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode(storage.theme),
      // The whole app is Arabic-medium, so the entire UI -- nav bar order,
      // back-button chevrons, list/row alignment, app bar layout -- mirrors
      // to right-to-left, not just individual Arabic text blocks.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('ms'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final scale = storage.textScale;
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    final body = IndexedStack(
      index: _currentIndex,
      children: [
        DashboardScreen(onOpenUnit: _navigateToUnit),
        const GlossaryScreen(),
        SearchScreen(onOpenUnit: _navigateToUnit),
        const SettingsScreen(),
      ],
    );

    if (isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            // Navigation Rail for wide screens
            Container(
              decoration: BoxDecoration(
                color: tokens.card,
                border: Border(
                  left: BorderSide(color: tokens.border, width: 1),
                ),
              ),
              child: NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.transparent,
                indicatorColor: scheme.primary.withValues(alpha: 0.16),
                selectedIconTheme: IconThemeData(color: scheme.primary),
                selectedLabelTextStyle: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedIconTheme: IconThemeData(color: tokens.textSecondary),
                unselectedLabelTextStyle: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 12,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard', textDirection: TextDirection.ltr),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book),
                    label: Text('Glosari', textDirection: TextDirection.ltr),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.search_outlined),
                    selectedIcon: Icon(Icons.search),
                    label: Text('Cari', textDirection: TextDirection.ltr),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Tetapan', textDirection: TextDirection.ltr),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: body,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Glosari',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Cari',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Tetapan',
          ),
        ],
      ),
    );
  }
}
