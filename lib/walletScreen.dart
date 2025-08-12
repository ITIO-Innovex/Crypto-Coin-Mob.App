import 'package:coincraze/CreateWallet.dart';
import 'package:coincraze/WalletList.dart';
import 'package:coincraze/utils/UnderProcess.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/wallet.jpg', // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
            // Dark overlay
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
            // Bottom-fixed container
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose how you want to add your wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'You can either create a new wallet or import an existing one',
                      style: TextStyle(color: Colors.grey, fontSize: 14.0),
                    ),
                    SizedBox(height: 16.0),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 15, 15, 15),
                            Color.fromARGB(255, 204, 202, 202),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        image: DecorationImage(
                          image: AssetImage('assets/images/walt.jpg'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.1),
                            BlendMode.dstATop,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _buildOption(
                        context,
                        icon: Icons.add,
                        title: 'Create a wallet',
                        subtitle:
                            'If you do not have an existing wallet, create one',
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => CryptoWalletScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 15, 15, 15),
                            Color.fromARGB(255, 204, 202, 202),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        image: DecorationImage(
                          image: AssetImage('assets/images/bg.jpg'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.1),
                            BlendMode.dstATop,
                          ),
                        ),
                      ),
                      child: _buildOption(
                        context,
                        icon: Icons.import_export,
                        title: 'Import a wallet',
                        subtitle:
                            'Enter your recovery phrase from another wallet',
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (context) =>
                                ComingSoonScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.amber),
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 20)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: const Color.fromARGB(255, 16, 15, 15)),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        tileColor: Colors.grey[800],
      ),
    );
  }

  IconData _getRandomIcon() {
    final List<IconData> icons = [
      Icons.star,
      Icons.circle,
      Icons.arrow_upward,
      Icons.book,
      Icons.sunny,
      Icons.rocket,
      Icons.work,
      Icons.tag,
    ];
    return icons[DateTime.now().millisecond % icons.length];
  }
}
