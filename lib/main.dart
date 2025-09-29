import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/saved_cities_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/weather_details_screen.dart';
import 'screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/news_screen.dart';
import 'screens/salahad_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  runApp(WeatherApp(isDarkMode: isDarkMode));
}

class WeatherApp extends StatefulWidget {
  final bool isDarkMode;

  WeatherApp({this.isDarkMode = false});

  @override
  _WeatherAppState createState() => _WeatherAppState();
}

//m initstate star isDarkMode
class _WeatherAppState extends State<WeatherApp> {
  late bool _isDarkMode;

  @override
  //
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  //m updateTheme เพื่ออัปเดตค่า... ให้แอปเปลี่ยนธีมเมื่อผู้ใช้ปรับค่าใน SettingsScreen
  void updateTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ธีมสว่างที่สวยงาม
    final lightTheme = ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Color(0xFF1976D2),
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: Color(0xFF1976D2),
        secondary: Color(0xFF03A9F4),
        background: Colors.white,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.blue.withOpacity(0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Color(0xFF1976D2)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.blue.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF1976D2),
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.blue.shade100,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    // ธีมมืดที่สวยงาม
    final darkTheme = ThemeData.dark().copyWith(
      primaryColor: Color(0xFF42A5F5),
      scaffoldBackgroundColor: Color(0xFF0A1929),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF42A5F5),
        secondary: Color(0xFF4FC3F7),
        background: Color(0xFF0A1929),
        surface: Color(0xFF102A43),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Color(0xFF102A43),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF102A43),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Color(0xFF42A5F5)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1C3D5A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF42A5F5), width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF102A43),
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: Color(0xFF1C3D5A),
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
    );

    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/search': (context) => SearchScreen(),
        '/saved': (context) => SavedCitiesScreen(),
        '/settings':
            (context) => SettingsScreen(
              isDarkMode: _isDarkMode,
              updateTheme: updateTheme,
            ),
        '/about': (context) => AboutScreen(),
        '/news': (context) => EnhancedNewsScreen(),
        '/salahad': (context) => SalahadScreen(),
        '/profile': (context) => ProfileScreen(),
      },
      //จะส่งค่าarguments ไปยังหน้า WeatherDetailsScreen
      onGenerateRoute: (settings) {
        if (settings.name == '/weather-details') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => WeatherDetailsScreen(weatherData: args),
          );
        }
        return null;
      },
    );
  }
}
