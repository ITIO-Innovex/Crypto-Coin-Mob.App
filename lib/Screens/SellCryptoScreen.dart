import 'package:coincraze/BottomBar.dart';
import 'package:coincraze/Screens/TransferSuccess.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coincraze/Models/CryptoWallet.dart';
import 'package:coincraze/Models/Wallet.dart';
import 'package:coincraze/Services/api_service.dart';

class CryptoSellScreen extends StatefulWidget {
  const CryptoSellScreen({Key? key}) : super(key: key);

  @override
  _CryptoSellScreenState createState() => _CryptoSellScreenState();
}

class _CryptoSellScreenState extends State<CryptoSellScreen> {
  List<CryptoWallet> cryptoWallets = [];
  List<Wallet> fiatWallets = [];
  CryptoWallet? selectedCrypto;
  Wallet? selectedFiat;
  double amountToSell = 0.0;
  double convertedAmount = 0.0;
  bool isLoading = false;
  final ApiService apiService = ApiService();

  // Mapping for currency codes to full coin names
  final Map<String, String> currencyToFullName = {
    'ETC_TEST': 'Ethereum Classic',
    'LTC_TEST': 'Litecoin',
    'BTC_TEST': 'Bitcoin',
    'DOGE_TEST': 'Dogecoin',
    'EOS_TEST': 'EOS',
    'ADA_TEST': 'Cardano',
    'DASH_TEST': 'Dash',
    'CELESTIA_TEST': 'Celestia',
    'HBAR_TEST': 'Hedera Hashgraph',
    'TRX_TEST': 'TRON',
  };

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      await Future.wait([fetchCryptoWallets(), fetchFiatWallets()]);

      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fetching data: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCryptoWallets() async {
    try {
      final wallets = await apiService.getCompleteCryptoDetails();
      setState(() {
        cryptoWallets = wallets;
        if (cryptoWallets.isNotEmpty) {
          selectedCrypto = cryptoWallets[0];
          updateConvertedAmount();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fetching crypto wallets: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> fetchFiatWallets() async {
    try {
      final wallets = await apiService.getBalance();
      setState(() {
        fiatWallets = wallets;
        if (fiatWallets.isNotEmpty) {
          selectedFiat = fiatWallets[0];
          updateConvertedAmount();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fetching fiat wallets: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> updateConvertedAmount() async {
    if (selectedCrypto != null && selectedFiat != null && amountToSell > 0) {
      try {
        final cryptoFullName =
            currencyToFullName[selectedCrypto!.currency] ??
            selectedCrypto!.currency;
        final rates = await apiService.fetchCryptoExchangeRates(
          cryptoFullName,
          selectedFiat!.currency,
          amountToSell,
        );
        final rate = rates[selectedFiat!.currency.toLowerCase()] ?? 1.0;
        setState(() {
          convertedAmount = amountToSell * rate;
        });
      } catch (e) {
        setState(() {
          convertedAmount = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error fetching exchange rate: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      setState(() {
        convertedAmount = 0.0;
      });
    }
  }

Future<void> sellCrypto() async {
  if (selectedCrypto == null || selectedFiat == null || amountToSell <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select valid crypto, fiat, and amount'),
      ),
    );
    return;
  }

  if (amountToSell > selectedCrypto!.balance) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You don\'t have sufficient balance in your crypto wallet account',
        ),
      ),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final cryptoFullName =
        currencyToFullName[selectedCrypto!.currency] ?? selectedCrypto!.currency;

    // Ensure convertedAmount is updated before the API call
    await updateConvertedAmount();
    if (convertedAmount <= 0) {
      throw Exception('Invalid converted amount');
    }

    // Store the values to pass to TransactionSuccessScreen
    final double finalConvertedAmount = convertedAmount;
    final String finalCurrency = selectedFiat!.currency;

    await apiService.sellCryptoToFiat(
      cryptoCurrency: cryptoFullName,
      fiatCurrency: selectedFiat!.currency,
      cryptoAmount: amountToSell,
      fiatAmount: convertedAmount,
      cryptoWalletId: selectedCrypto!.id ?? '',
      fiatWalletId: selectedFiat!.id.toString(),
    );

    await Future.wait([fetchCryptoWallets(), fetchFiatWallets()]);

    // Navigate to TransactionSuccessScreen with preserved values
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionSuccessScreen(
          amount: finalConvertedAmount,
          currency: finalCurrency,
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error selling crypto: $e',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      isLoading = false;
      amountToSell = 0.0; // Safe to reset after navigation
      convertedAmount = 0.0; // Safe to reset after navigation
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          'Sell Crypto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => MainScreen()),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crypto Selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Crypto to Sell',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CryptoWallet>(
                          value: selectedCrypto,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: Colors.grey[800],
                          items: cryptoWallets
                              .map(
                                (wallet) => DropdownMenuItem(
                                  value: wallet,
                                  child: Text(
                                    '${currencyToFullName[wallet.currency] ?? wallet.currency} (${wallet.balance.toStringAsFixed(4)})',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCrypto = value;
                              updateConvertedAmount();
                            });
                          },
                        ),
                        if (selectedCrypto != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Wallet Address: ${selectedCrypto!.address ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount Input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount to Sell',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[800],
                            hintText: 'Enter amount',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              amountToSell = double.tryParse(value) ?? 0.0;
                              updateConvertedAmount();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fiat Wallet Selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Fiat Wallet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Wallet>(
                          value: selectedFiat,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: Colors.grey[800],
                          items: fiatWallets
                              .map(
                                (wallet) => DropdownMenuItem(
                                  value: wallet,
                                  child: Text(
                                    '${wallet.currency} (${wallet.balance.toStringAsFixed(2)})',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFiat = value;
                              updateConvertedAmount();
                            });
                          },
                        ),
                        if (selectedFiat != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Available Balance: ${selectedFiat!.balance.toStringAsFixed(2)} ${selectedFiat!.currency}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Converted Amount Display
                  if (convertedAmount > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'You will receive: ${convertedAmount.toStringAsFixed(2)} ${selectedFiat?.currency ?? ''}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Sell Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: sellCrypto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sell Crypto',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
