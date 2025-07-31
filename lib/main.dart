import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Hive.initFlutter();
  await Hive.openBox('inspection_history');
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  runApp(JasaMargaApp(onboardingDone: onboardingDone));
}

class JasaMargaApp extends StatelessWidget {
  final bool onboardingDone;
  const JasaMargaApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jasamarga Inspeksi',
      theme: ThemeData(
        primaryColor: const Color(0xFFEBEC07),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEBEC07),
            foregroundColor: const Color(0xFF2257C1),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2257C1),
            side: const BorderSide(color: Color(0xFF2257C1)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2257C1),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF2257C1);
            }
            return Colors.grey;
          }),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2257C1),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF2257C1),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      home: onboardingDone ? const HomeScreen() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
