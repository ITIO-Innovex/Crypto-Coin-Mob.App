import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/BankDetailsScreen.dart';
import 'package:coincraze/BottomBar.dart';
import 'package:coincraze/CoinSwap.dart';
import 'package:coincraze/ForgotPassword.dart';
import 'package:coincraze/HomeScreen.dart';
import 'package:coincraze/LoginScreen.dart';
import 'package:coincraze/OnboardingScreen.dart';
import 'package:coincraze/OtpValidationScreen.dart';
import 'package:coincraze/ProfilePage.dart';
import 'package:coincraze/Screens/FiatWalletScreen.dart';
import 'package:coincraze/Screens/SellCryptoScreen.dart';
import 'package:coincraze/Screens/TransferSuccess.dart';
import 'package:coincraze/SplashScreen.dart';
import 'package:coincraze/UpdatePassword.dart';
import 'package:coincraze/VerifyOtp.dart';
import 'package:coincraze/WalletList.dart';
import 'package:coincraze/demoColor.dart';
import 'package:coincraze/kyc.dart';
import 'package:coincraze/newKyc.dart';
import 'package:coincraze/walletScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize Hive
  await Hive.openBox('userBox'); // Open the box
  print('Hive box "userBox" opened successfully');
  await AuthManager().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoinCraze',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: MainScreen(),
    );
  }
}
