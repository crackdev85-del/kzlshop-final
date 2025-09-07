
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:myapp/firebase_options.dart';
import 'package:myapp/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to light theme

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define Custom Colors
    const Color babyPink = Color(0xFFF4C2C2);
    const Color skyBlue = Color(0xFF87CEEB);
    const Color pink = Colors.pink;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    // --- Light Theme --- 
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: babyPink, // Set background to Baby Pink
      colorScheme: ColorScheme.fromSeed(
        seedColor: skyBlue, // Primary color scheme seed
        brightness: Brightness.light,
        primary: skyBlue,
        secondary: pink, 
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: skyBlue, // App Bar to Sky Blue
        foregroundColor: Colors.black, // Text/Icons on App Bar
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, // Text on buttons
          backgroundColor: pink, // Buttons to Pink
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );

    // --- Dark Theme --- 
    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey[900], // Dark background
      colorScheme: ColorScheme.fromSeed(
        seedColor: skyBlue,
        brightness: Brightness.dark,
        primary: skyBlue, 
        secondary: pink,
      ),
      textTheme: appTextTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850], // Darker App Bar
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: pink, // Keep buttons pink for contrast
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'KZL Shop',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
