// Basic smoke tests: the app launches and its primary screens open without
// throwing. Setup uses tester.runAsync() because testWidgets() otherwise runs
// in a FakeAsync zone where real async I/O (asset-bundle loading) never
// resolves; pumpAndSettle() is avoided afterwards since the audio player /
// TTS plugins schedule background timers under test that never fully
// quiesce (harmless in the real app). Run with: flutter test
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umt3033_app/main.dart';
import 'package:umt3033_app/screens/glossary_screen.dart';
import 'package:umt3033_app/screens/search_screen.dart';
import 'package:umt3033_app/screens/settings_screen.dart';
import 'package:umt3033_app/screens/unit_screen.dart';
import 'package:umt3033_app/services/data_service.dart';
import 'package:umt3033_app/services/storage_service.dart';

Future<Widget> _buildApp() async {
  final dataService = DataService();
  await dataService.loadAll();
  final storageService = StorageService();
  await storageService.init();
  return MultiProvider(
    providers: [
      Provider<DataService>.value(value: dataService),
      ChangeNotifierProvider<StorageService>.value(value: storageService),
    ],
    child: const UMT3033App(),
  );
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(700, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final app = await tester.runAsync(_buildApp);
  await tester.pumpWidget(app!);
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and Dashboard renders course + progress', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpApp(tester);

    expect(find.text('UMT3033'), findsWidgets);
    expect(
      find.text('٠/١٤'),
      findsOneWidget,
    ); // "Unit Selesai" stat, confirms 14 units loaded
  });

  testWidgets('Bottom navigation opens Glossary, Search and Settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpApp(tester);

    await tester.tap(find.text('Glosari'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GlossaryScreen), findsOneWidget);

    await tester.tap(find.text('Cari'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SearchScreen), findsOneWidget);

    await tester.tap(find.text('Tetapan'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('Opening a unit from the hero button shows UnitScreen content', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpApp(tester);

    await tester.tap(find.text('ابدأ التعلم'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(UnitScreen), findsOneWidget);
  });
}
