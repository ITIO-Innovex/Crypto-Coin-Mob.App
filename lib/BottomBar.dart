import 'package:coincraze/HomeScreen.dart';
import 'package:coincraze/Screens/ChartScreen.dart';
import 'package:coincraze/Screens/DetailsTransacitonScreen.dart';
import 'package:coincraze/Screens/QRCode_Scanner.dart';
import 'package:coincraze/Screens/SettingsPage.dart';
import 'package:coincraze/Screens/Transactions.dart';
import 'package:coincraze/deposit.dart';
import 'package:coincraze/walletScreen.dart';
import 'package:coincraze/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Swap tab (index 2) default active

  // Pages ke liye list
  final List<Widget> _pages = [
    Homescreen(),
    ChartScreen(), // Replaced ChartScreen with CoinSwap
    WalletScreen(),
    DetailsTransactionScreen(),
    CryptoSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Selected page show karo
      bottomNavigationBar: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_chart_outlined),
                label: 'Trade',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.wallet),
                  ],
                ),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: themeProvider.isDarkMode ? Color.fromARGB(255, 36, 38, 40) : Colors.white,
            selectedItemColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
            unselectedItemColor: themeProvider.isDarkMode ? const Color.fromARGB(255, 142, 141, 141) : Colors.grey[700],
          );
        },
      ),
    );
  }
}