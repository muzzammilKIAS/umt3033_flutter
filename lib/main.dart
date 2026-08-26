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
  bool _sidebarExpanded = false;

  void _navigateToUnit(int unitId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UnitScreen(unitId: unitId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
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
        backgroundColor: tokens.mist,
        body: Row(
          children: [
            // Branded sidebar for wide screens: icon-only, expands on hover
            MouseRegion(
              onEnter: (_) => setState(() => _sidebarExpanded = true),
              onExit: (_) => setState(() => _sidebarExpanded = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: _sidebarExpanded ? 240 : 76,
                margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                padding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: _sidebarExpanded ? 14 : 10,
                ),
                decoration: BoxDecoration(
                  color: tokens.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: context.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: _sidebarExpanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                tokens.heroGradientStart,
                                tokens.heroGradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'ع',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (_sidebarExpanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'UMT3033',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),
                    _sidebarItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard,
                      label: 'Dashboard',
                      index: 0,
                      expanded: _sidebarExpanded,
                    ),
                    const SizedBox(height: 6),
                    _sidebarItem(
                      context,
                      icon: Icons.menu_book_outlined,
                      selectedIcon: Icons.menu_book,
                      label: 'Glosari',
                      index: 1,
                      expanded: _sidebarExpanded,
                    ),
                    const SizedBox(height: 6),
                    _sidebarItem(
                      context,
                      icon: Icons.search_outlined,
                      selectedIcon: Icons.search,
                      label: 'Cari',
                      index: 2,
                      expanded: _sidebarExpanded,
                    ),
                    const SizedBox(height: 6),
                    _sidebarItem(
                      context,
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Tetapan',
                      index: 3,
                      expanded: _sidebarExpanded,
                    ),
                  ],
                ),
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

  Widget _sidebarItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool expanded,
  }) {
    final tokens = context.tokens;
    final selected = _currentIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 14 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [tokens.heroGradientStart, tokens.heroGradientEnd],
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: expanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 20,
                color: selected ? Colors.white : tokens.textSecondary,
              ),
              if (expanded) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: selected ? Colors.white : tokens.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
