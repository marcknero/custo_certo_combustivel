import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  final storageService = LocalStorageService();
  final initialDarkMode = await storageService.getDarkMode();

  runApp(
    CustoCertoApp(
      storageService: storageService,
      initialDarkMode: initialDarkMode,
    ),
  );
}

class CustoCertoApp extends StatefulWidget {
  final LocalStorageService storageService;
  final bool initialDarkMode;

  const CustoCertoApp({
    super.key,
    required this.storageService,
    required this.initialDarkMode,
  });

  @override
  State<CustoCertoApp> createState() => _CustoCertoAppState();
}

class _CustoCertoAppState extends State<CustoCertoApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  Future<void> _handleToggleTheme(bool dark) async {
    setState(() => _isDarkMode = dark);
    await widget.storageService.saveDarkMode(dark);
  }

  ThemeData _buildLightSkyTheme() {
    const skyBackground = Color(0xFFE7F3FC);
    const skySurface = Color(0xFFF6FAFF);
    const primaryBlue = Color(0xFF0E6BA8);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        surface: skySurface,
      ),
      scaffoldBackgroundColor: skyBackground,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD6ECFA),
        foregroundColor: Color(0xFF0A2E4D),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: skySurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const darkBg = Color(0xFF0D1622);
    const darkSurface = Color(0xFF162232);
    const accentBlue = Color(0xFF56B4F5);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBlue,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBg,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121E2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custo Certo Combustível',
      debugShowCheckedModeBanner: false,
      theme: _buildLightSkyTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        storageService: widget.storageService,
        isDarkMode: _isDarkMode,
        onToggleTheme: _handleToggleTheme,
      ),
    );
  }
}