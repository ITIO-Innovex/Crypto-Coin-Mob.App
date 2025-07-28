import 'dart:convert';
import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:coincraze/Models/WalletResponse.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coincraze/Models/CryptoWallet.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'package:coincraze/Constants/API.dart';
import 'package:flutter/services.dart';

class BuyCryptoScreen extends StatefulWidget {
  const BuyCryptoScreen({required this.availableCurrencies, super.key});

  final List<String> availableCurrencies;

  @override
  _BuyCryptoScreenState createState() => _BuyCryptoScreenState();
}

class _BuyCryptoScreenState extends State<BuyCryptoScreen> {
  final _amountController = TextEditingController();
  String? _selectedCrypto; // Initially null until wallets are fetched
  String _selectedFiat = 'USD';
  String? _selectedWalletAddress;
  double _cryptoAmount = 0.0;
  double _exchangeRate = 0.0;
  double _fee = 0.0;
  bool _isLoading = false;
  List<WalletData> _userWallets = [];
  List<String> _cryptos = []; // Dynamic list from DB

  // Map to handle testnet coins (maps API coinName to mainnet coin for display)
  final Map<String, String> coinNameToMainnet = {
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

  // Enhanced theme colors with gradients
  final Color _primaryColor = const Color.fromARGB(255, 23, 23, 23);
  final Color _accentColor = const Color.fromARGB(255, 211, 224, 225);
  final Color _backgroundColor = const Color(0xFFECEFF1);
  final LinearGradient _buttonGradient = const LinearGradient(
    colors: [
      Color.fromARGB(255, 13, 13, 13),
      Color.fromARGB(255, 92, 117, 130),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  final LinearGradient _cardGradient = const LinearGradient(
    colors: [Color.fromRGBO(111, 110, 110, 1), Color.fromARGB(255, 37, 37, 38)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void initState() {
    super.initState();
    _selectedFiat = widget.availableCurrencies.contains('USD')
        ? 'USD'
        : (widget.availableCurrencies.isNotEmpty
              ? widget.availableCurrencies[0]
              : 'USD');
    _fetchExchangeRate();
    _amountController.addListener(_calculateCryptoAmount);
    _fetchUserWallets();
  }

  Future<void> _fetchUserWallets() async {
    setState(() => _isLoading = true);
    try {
      // Ensure user is authenticated
      final authManager = AuthManager();
      if (!authManager.isLoggedIn || authManager.userId == null) {
        throw Exception('User not authenticated. Please log in.');
      }
      final token = await authManager.getAuthToken();
      print('Fetching wallets with token: $token');

      // Fetch wallets from API
      final wallets = await ApiService().getCompleteCryptoDetails();
      print('Fetched Wallets: $wallets (Count: ${wallets.length})');
      if (wallets.isEmpty) {
        print('No wallets returned from API');
      } else {
        wallets.forEach((wallet) {
          print(
            'Wallet: currency=${wallet.currency}, address=${wallet.address}, createdAt=${wallet.createdAt}',
          );
        });
      }

      setState(() {
        // Map wallets to WalletData
        _userWallets = wallets
            .map(
              (wallet) => WalletData(
                coinName: wallet.currency ?? 'Unknown',
                walletAddress: wallet.address ?? '',
                createdAt: wallet.createdAt ?? DateTime.now(),
              ),
            )
            .toList();

        // Populate _cryptos with unique currencies from DB
        _cryptos = _userWallets
            .map((wallet) => wallet.coinName)
            .toSet()
            .toList(); // Remove duplicates
        print('Available cryptocurrencies: $_cryptos');

        // Set default selected crypto
        if (_cryptos.isNotEmpty) {
          _selectedCrypto = _cryptos.first;
        } else {
          _selectedCrypto = null;
        }

        // Select wallet address for the current _selectedCrypto
        if (_userWallets.isNotEmpty && _selectedCrypto != null) {
          final matchingWallets = _userWallets
              .where((w) => w.coinName == _selectedCrypto)
              .toList();
          _selectedWalletAddress = matchingWallets.isNotEmpty
              ? matchingWallets.first.walletAddress
              : _userWallets.first.walletAddress;
        } else {
          _selectedWalletAddress = null;
        }
      });
    } catch (e) {
      print('Fetch Wallets Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('401')
                ? 'Authentication failed. Please log in again.'
                : 'Error fetching wallet details: $e',
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createWallet() async {
    if (_selectedCrypto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cryptocurrency')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final newWallet = await ApiService().createWalletAddress(
        _selectedCrypto!,
      );
      print(
        'New Wallet: currency=${newWallet.currency}, address=${newWallet.address}',
      );
      setState(() {
        _userWallets.add(
          WalletData(
            coinName: newWallet.currency ?? 'Unknown',
            walletAddress: newWallet.address ?? '',
            createdAt: newWallet.createdAt ?? DateTime.now(),
          ),
        );
        _selectedWalletAddress = newWallet.address;
        // Update _cryptos if new coin is created
        if (!_cryptos.contains(newWallet.currency)) {
          _cryptos.add(newWallet.currency ?? 'Unknown');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wallet address created successfully for ${coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto}',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Create Wallet Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating wallet: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchExchangeRate() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 || _selectedCrypto == null) {
      setState(() {
        _exchangeRate = 0.0;
        _cryptoAmount = 0.0;
        _fee = 0.0;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final rates = await ApiService().fetchCryptoExchangeRates(
        coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto!,
        _selectedFiat,
        amount,
      );
      setState(() {
        _exchangeRate = rates[_selectedFiat.toLowerCase()] ?? 0.0;
        if (_exchangeRate <= 0) {
          throw Exception('Invalid exchange rate received');
        }
        _calculateCryptoAmount();
      });
    } catch (e) {
      setState(() {
        _exchangeRate = 60000.0;
        _calculateCryptoAmount();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching rate, using mock value: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateCryptoAmount() {
    final fiatAmount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _fee = fiatAmount * 0.015;
      _cryptoAmount = _exchangeRate > 0
          ? (fiatAmount - _fee) / _exchangeRate
          : 0.0;
    });
  }

  bool _validateWalletAddress(String? address, String? crypto) {
    return address != null && address.isNotEmpty;
  }

  void _copyAddress(String? address) {
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No address available to copy",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Address copied to clipboard",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _confirmTransaction() async {
    final fiatAmount = double.tryParse(_amountController.text) ?? 0.0;
    final walletAddress = _selectedWalletAddress;
    print('Selected Wallet Address: $walletAddress');

    if (fiatAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (walletAddress == null ||
        !_validateWalletAddress(walletAddress, _selectedCrypto)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid wallet address')),
      );
      return;
    }

    final authManager = AuthManager();
    if (!authManager.isLoggedIn ||
        authManager.userId == null ||
        authManager.kycCompleted != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KYC verification required to perform transactions'),
        ),
      );
      return;
    }

    final selectedWallet = _userWallets.firstWhere(
      (w) => w.walletAddress == walletAddress,
      orElse: () => WalletData(
        coinName: _selectedCrypto ?? 'Unknown',
        walletAddress: walletAddress,
        createdAt: DateTime.now(),
      ),
    );

    setState(() => _isLoading = true);
    try {
      final token = await authManager.getAuthToken();
      final response = await http.post(
        Uri.parse('$ProductionBaseUrl/api/wallet/CryptoAmountUpdate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': authManager.userId,
          'currency': selectedWallet.coinName,
          'address': walletAddress,
          'amount': _cryptoAmount,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedWallet = CryptoWallet.fromJson(responseData);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.transparent,
            content: Container(
              decoration: BoxDecoration(
                gradient: _cardGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: FadeInUp(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Successful',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: _backgroundColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogText('Fiat Amount: $_selectedFiat $fiatAmount'),
                    _buildDialogText(
                      'Crypto Received: ${_cryptoAmount.toStringAsFixed(8)} ${coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto}',
                    ),
                    _buildDialogText(
                      'Fee: $_selectedFiat ${_fee.toStringAsFixed(2)}',
                    ),
                    _buildDialogText(
                      'Exchange Rate: 1 ${coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto} = $_selectedFiat ${_exchangeRate.toStringAsFixed(2)}',
                    ),
                    _buildDialogText('Wallet Address: $walletAddress'),
                    _buildDialogText(
                      'New Balance: ${updatedWallet.balance.toStringAsFixed(8)} ${coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto}',
                    ),
                    _buildDialogText('Date: ${DateTime.now().toString()}'),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: _buttonGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'OK',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        _amountController.clear();
        setState(() {
          _cryptoAmount = 0.0;
          _fee = 0.0;
          _exchangeRate = 0.0;
        });

        await _fetchUserWallets();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Failed to update wallet: ${errorData['message'] ?? response.body}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Transaction failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDialogText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: _backgroundColor.withOpacity(0.9),
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Buy Crypto',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _accentColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Select Cryptocurrency'),
                const SizedBox(height: 12),
                _buildCryptoDropdown(),
                const SizedBox(height: 24),
                _buildSectionTitle('Select Fiat Currency'),
                const SizedBox(height: 12),
                _buildFiatDropdown(),
                const SizedBox(height: 24),
                _buildSectionTitle('Wallet Address'),
                const SizedBox(height: 12),
                _userWallets.where((w) => w.coinName == _selectedCrypto).isEmpty
                    ? _buildCreateWalletButton()
                    : _buildWalletAddressDropdown(),
                const SizedBox(height: 24),
                _buildSectionTitle('Amount ($_selectedFiat)'),
                const SizedBox(height: 12),
                _buildAmountInput(),
                const SizedBox(height: 28),
                _isLoading
                    ? _buildLoadingIndicator()
                    : _buildTransactionDetails(),
                const SizedBox(height: 32),
                _buildConfirmButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _primaryColor.withOpacity(0.9),
      ),
    );
  }

  Widget _buildCryptoDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCrypto,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: _accentColor),
          dropdownColor: _primaryColor,
          hint: Text(
            _cryptos.isEmpty
                ? 'No cryptocurrencies available'
                : 'Select cryptocurrency',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          items: _cryptos
              .map(
                (crypto) => DropdownMenuItem(
                  value: crypto,
                  child: Text(
                    coinNameToMainnet[crypto] ?? crypto,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: _cryptos.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedCrypto = value!;
                    final matchingWallets = _userWallets
                        .where((w) => w.coinName == _selectedCrypto)
                        .toList();
                    _selectedWalletAddress = matchingWallets.isNotEmpty
                        ? matchingWallets.first.walletAddress
                        : null;
                    _fetchExchangeRate();
                  });
                },
        ),
      ),
    );
  }

  Widget _buildFiatDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFiat,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: _accentColor),
          dropdownColor: _primaryColor,
          items: widget.availableCurrencies
              .map(
                (currency) => DropdownMenuItem(
                  value: currency,
                  child: Text(
                    currency,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedFiat = value!;
              _fetchExchangeRate();
            });
          },
        ),
      ),
    );
  }

  Widget _buildWalletAddressDropdown() {
    final availableWallets = _userWallets
        .where((w) => w.coinName == _selectedCrypto)
        .toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedWalletAddress,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: _accentColor),
          dropdownColor: _primaryColor,
          hint: Text(
            availableWallets.isEmpty
                ? 'No wallets available'
                : 'Select wallet address',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          items: availableWallets
              .map(
                (wallet) => DropdownMenuItem(
                  value: wallet.walletAddress,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          wallet.walletAddress.isNotEmpty
                              ? wallet.walletAddress
                              : "No address",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (wallet.walletAddress.isNotEmpty)
                        GestureDetector(
                          onTap: () => _copyAddress(wallet.walletAddress),
                          child: Icon(
                            Icons.copy,
                            size: 16,
                            color: _accentColor,
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: availableWallets.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedWalletAddress = value;
                  });
                },
        ),
      ),
    );
  }

  Widget _buildCreateWalletButton() {
    return Center(
      child: GestureDetector(
        onTap: _isLoading || _selectedCrypto == null ? null : _createWallet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: _isLoading
                ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                : _buttonGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _selectedCrypto == null
                ? 'Create Wallet'
                : 'Create ${coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto} Wallet',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount ($_selectedFiat)',
        labelStyle: GoogleFonts.poppins(
          color: _primaryColor.withOpacity(0.7),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _accentColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        prefixIcon: Icon(Icons.attach_money, color: _accentColor),
      ),
      style: GoogleFonts.poppins(color: _primaryColor, fontSize: 16),
      keyboardType: TextInputType.number,
      onChanged: (value) => _fetchExchangeRate(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailText(
            'Exchange Rate: 1 ${coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto ?? 'N/A'} = $_selectedFiat ${_exchangeRate.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildDetailText(
            'Fee (1.5%): $_selectedFiat ${_fee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildDetailText(
            'You will receive: ${_cryptoAmount.toStringAsFixed(8)} ${coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto ?? 'N/A'}',
            isBold: true,
            color: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailText(String text, {bool isBold = false, Color? color}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color ?? Colors.white.withOpacity(0.9),
        fontSize: 14,
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Center(
      child: GestureDetector(
        onTap: _isLoading || _selectedCrypto == null
            ? null
            : _confirmTransaction,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
          decoration: BoxDecoration(
            gradient: _isLoading
                ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                : _buttonGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'Confirm Transaction',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
