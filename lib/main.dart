import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/BottomBar.dart'; // Assuming this is your MainScreen
import 'package:coincraze/LoginScreen.dart';
import 'package:coincraze/OnboardingScreen.dart';
import 'package:coincraze/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize Hive
  var userBox = await Hive.openBox('userBox');

  await AuthManager().init(); // Load login state

  // Determine which screen to show first
  bool isFirstLaunch = userBox.get('isFirstLaunch', defaultValue: true);
  bool isLoggedIn = AuthManager().isLoggedIn;

  Widget initialScreen;

  if (isFirstLaunch) {
    await userBox.put('isFirstLaunch', false);
    initialScreen = OnboardingScreen();
  } else if (!isLoggedIn) {
    initialScreen = LoginScreen();
  } else {
    initialScreen = MainScreen(); // This is your main/home screen
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(initialScreen: initialScreen),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CoinCraze',
          theme: themeProvider.lightTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(
              themeProvider.lightTheme.textTheme,
            ),
          ),
          darkTheme: themeProvider.darkTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(
              themeProvider.darkTheme.textTheme,
            ),
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: initialScreen,
        );
      },
    );
  }
}
