import 'package:coincraze/Screens/AddFundsScreen.dart';
import 'package:coincraze/Screens/DetailsTransacitonScreen.dart';
import 'package:coincraze/Screens/TransactionScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_flags/country_flags.dart';
import '../models/wallet.dart';


class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final bool isLargeScreen;

  WalletCard({required this.wallet, required this.isLargeScreen});

  final Map<String, String> _currencyToFlag = {
    'USD': 'assets/flags/USD.jpg',
    'INR': 'assets/flags/IndianCurrency.jpg',
    'EUR': 'assets/flags/Euro.jpg',
    'GBP': 'assets/flags/GBP.png',
    'JPY': 'assets/flags/Japan.png',
    'CAD': 'assets/flags/CAD.jpg',
    'AUD': 'assets/flags/australian-dollar.jpeg',
  };

  String _getCountryCode(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return 'US';
      case 'INR':
        return 'IN';
      case 'EUR':
        return 'EU';
      case 'GBP':
        return 'GB';
      case 'JPY':
        return 'JP';
      case 'CAD':
        return 'CA';
      case 'AUD':
        return 'AU';
      default:
        return 'US';
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isLargeScreen,
  }) {
    return IconButton(
      icon: Icon(icon, size: isLargeScreen ? 28 : 24, color: Colors.white),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final flagImage = _currencyToFlag[wallet.currency.toUpperCase()];

    return Hero(
      tag: 'wallet-${wallet.currency}',
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          image: flagImage != null
              ? DecorationImage(
                  image: AssetImage(flagImage),
                  fit: BoxFit.cover,
                  opacity: 0.5,
                )
              : null,
          gradient: flagImage == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF161626),
                    Color(0xFF111213),
                  ],
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: isLargeScreen ? 16 : 14,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: wallet.currency.toUpperCase() == 'EUR'
                            ? ClipOval(
                                child: Image.asset(
                                  'assets/flags/EuroFlag.png',
                                  width: isLargeScreen ? 28 : 24,
                                  height: isLargeScreen ? 28 : 24,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CountryFlag.fromCountryCode(
                                _getCountryCode(wallet.currency.toUpperCase()),
                                height: isLargeScreen ? 28 : 24,
                                width: isLargeScreen ? 28 : 24,
                              ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${wallet.currency.toUpperCase()} Wallet',
                          style: GoogleFonts.poppins(
                            fontSize: isLargeScreen ? 24 : 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Icon(Icons.account_balance_wallet,
                          color: Colors.white70,
                          size: isLargeScreen ? 34 : 30),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Balance: ${wallet.balance.toStringAsFixed(2)} ${wallet.currency.toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontSize: isLargeScreen ? 20 : 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildIconButton(
                        icon: Icons.add_circle,
                        tooltip: 'Add Funds',
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('userId') ?? '';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddFundsScreen(
                                userId: userId,
                                currency: wallet.currency,
                              ),
                            ),
                          );
                        },
                        isLargeScreen: isLargeScreen,
                      ),
                      SizedBox(width: 8),
                      _buildIconButton(
                        icon: Icons.history,
                        tooltip: 'Transaction History',
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('userId') ?? '';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailsTransactionScreen(),
                            ),
                          );
                        },
                        isLargeScreen: isLargeScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
