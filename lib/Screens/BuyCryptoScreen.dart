import 'dart:convert';
import 'dart:async';
import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/BottomBar.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:coincraze/Models/WalletResponse.dart';
import 'package:flutter/cupertino.dart';
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
  String? _selectedCrypto;
  String _selectedFiat = 'USD';
  String? _selectedWalletAddress;
  double _cryptoAmount = 0.0;
  double _exchangeRate = 0.0;
  double _fee = 0.0;
  bool _isLoading = false;
  bool _isLoadingRate = false;
  List<WalletData> _userWallets = [];
  List<String> _cryptos = [];
  double? _fiatBalance; // Store fiat account balance
  Timer? _debounceTimer;
  String? _lastErrorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _debounceDelay = Duration(milliseconds: 800);
  static const double _maxAmount = 1000000.0; // Maximum allowed amount

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
    _amountController.addListener(_onAmountChanged);
    _fetchUserWallets();
    _fetchFiatBalance(); // Fetch fiat balance on initialization
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Clear previous error
    if (_lastErrorMessage != null) {
      setState(() {
        _lastErrorMessage = null;
      });
    }
    
    // Start new timer
    _debounceTimer = Timer(_debounceDelay, () {
      _fetchExchangeRateWithValidation();
    });
    
    // Calculate immediately for UI responsiveness (without API call)
    _calculateCryptoAmount();
  }

  // Simplified to use ApiService().getBalance() and show balance from response
  Future<void> _fetchFiatBalance() async {
    setState(() => _isLoading = true);
    try {
      final authManager = AuthManager();
      if (!authManager.isLoggedIn || authManager.userId == null) {
        throw Exception('User not authenticated. Please log in.');
      }
      final wallets = await ApiService().getBalance(); // Hit getBalance API
      final selectedWallet = wallets.firstWhere(
        (wallet) => wallet.currency.toUpperCase() == _selectedFiat,
      );
      setState(() {
        _fiatBalance = selectedWallet.balance;
      });
    } catch (e) {
      print('Fetch Fiat Balance Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching fiat balance: $e'),
        ),
      );
      setState(() {
        _fiatBalance = null; // Set to null on error or no wallet found
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserWallets() async {
    setState(() => _isLoading = true);
    try {
      final authManager = AuthManager();
      if (!authManager.isLoggedIn || authManager.userId == null) {
        throw Exception('User not authenticated. Please log in.');
      }
      final wallets = await ApiService().getCompleteCryptoDetails();

      setState(() {
        _userWallets = wallets
            .map(
              (wallet) => WalletData(
                coinName: wallet.currency ?? 'Unknown',
                walletAddress: wallet.address ?? '',
                createdAt: wallet.createdAt ?? DateTime.now(),
              ),
            )
            .toList();
        _cryptos = _userWallets.map((wallet) => wallet.coinName).toSet().toList();
        if (_cryptos.isNotEmpty) {
          _selectedCrypto = _cryptos.first;
        } else {
          _selectedCrypto = null;
        }
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
      final newWallet = await ApiService().createWalletAddress(_selectedCrypto!);
      setState(() {
        _userWallets.add(
          WalletData(
            coinName: newWallet.currency ?? 'Unknown',
            walletAddress: newWallet.address ?? '',
            createdAt: newWallet.createdAt ?? DateTime.now(),
          ),
        );
        _selectedWalletAddress = newWallet.address;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating wallet: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchExchangeRateWithValidation() async {
    final amountText = _amountController.text.trim();
    
    // Input validation
    if (amountText.isEmpty) {
      _resetExchangeData();
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      setState(() {
        _lastErrorMessage = 'Please enter a valid number';
      });
      _resetExchangeData();
      return;
    }

    if (amount <= 0) {
      setState(() {
        _lastErrorMessage = 'Amount must be greater than 0';
      });
      _resetExchangeData();
      return;
    }

    if (amount > _maxAmount) {
      setState(() {
        _lastErrorMessage = 'Amount too large. Maximum allowed: ${_maxAmount.toStringAsFixed(0)}';
      });
      _resetExchangeData();
      return;
    }

    if (_selectedCrypto == null) {
      _resetExchangeData();
      return;
    }

    await _fetchExchangeRate(amount);
  }

  Future<void> _fetchExchangeRate(double amount) async {
    setState(() {
      _isLoadingRate = true;
      _lastErrorMessage = null;
    });

    try {
      final rates = await _fetchExchangeRateWithRetry(amount);
      
      setState(() {
        _exchangeRate = rates[_selectedFiat.toLowerCase()] ?? 0.0;
        if (_exchangeRate <= 0) {
          throw Exception('Invalid exchange rate received');
        }
        _retryCount = 0; // Reset retry count on success
        _calculateCryptoAmount();
      });
      
    } catch (e) {
      await _handleExchangeRateError(e, amount);
    } finally {
      setState(() => _isLoadingRate = false);
    }
  }

  Future<Map<String, double>> _fetchExchangeRateWithRetry(double amount) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final rates = await ApiService().fetchCryptoExchangeRates(
          coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto!,
          _selectedFiat,
          amount,
        );
        return rates;
      } catch (e) {
        if (attempt == _maxRetries) {
          rethrow; // Last attempt failed, rethrow the error
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    
    throw Exception('Max retries exceeded');
  }

  Future<void> _handleExchangeRateError(dynamic error, double amount) async {
    _retryCount++;
    
    String errorMessage;
    bool shouldUseFallback = false;
    
    if (error.toString().contains('500')) {
      if (amount > 100000) {
        errorMessage = 'Amount too large for conversion. Please try a smaller amount.';
      } else {
        errorMessage = 'Server error. Using estimated rate.';
        shouldUseFallback = true;
      }
    } else if (error.toString().contains('timeout')) {
      errorMessage = 'Request timeout. Please check your connection.';
      shouldUseFallback = true;
    } else if (error.toString().contains('Failed to fetch conversion rate')) {
      errorMessage = 'Unable to get current rates. Using estimated rate.';
      shouldUseFallback = true;
    } else {
      errorMessage = 'Network error. Please try again.';
      shouldUseFallback = _retryCount <= 2; // Only use fallback for first few attempts
    }

    setState(() {
      _lastErrorMessage = errorMessage;
      
      if (shouldUseFallback) {
        // Use a reasonable fallback rate based on crypto type
        _exchangeRate = _getFallbackRate(_selectedCrypto);
        _calculateCryptoAmount();
      } else {
        _resetExchangeData();
      }
    });
  }

  double _getFallbackRate(String? crypto) {
    // Provide reasonable fallback rates for different cryptocurrencies
    switch (crypto) {
      case 'BTC_TEST':
        return 45000.0;
      case 'ETH_TEST':
        return 2500.0;
      case 'LTC_TEST':
        return 70.0;
      case 'DOGE_TEST':
        return 0.08;
      case 'ADA_TEST':
        return 0.35;
      default:
        return 1000.0; // Generic fallback
    }
  }

  void _resetExchangeData() {
    setState(() {
      _exchangeRate = 0.0;
      _cryptoAmount = 0.0;
      _fee = 0.0;
    });
  }

  void _calculateCryptoAmount() {
    final fiatAmount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _fee = fiatAmount * 0.015;
      _cryptoAmount = _exchangeRate > 0 ? (fiatAmount - _fee) / _exchangeRate : 0.0;
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
  final totalAmount = fiatAmount + _fee;
  final walletAddress = _selectedWalletAddress;

  if (fiatAmount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid amount')),
    );
    return;
  }

  if (_fiatBalance == null || totalAmount > _fiatBalance!) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _fiatBalance == null
              ? 'Balance not available for $_selectedFiat. Please try again.'
              : 'Insufficient balance in $_selectedFiat account. Available: ${_fiatBalance!.toStringAsFixed(2)} $_selectedFiat',
        ),
      ),
    );
    return;
  }

  if (walletAddress == null || !_validateWalletAddress(walletAddress, _selectedCrypto)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a valid wallet address')),
    );
    return;
  }

  final authManager = AuthManager();
  if (!authManager.isLoggedIn || authManager.userId == null || authManager.kycCompleted != true) {
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

    // Step 1: Update Crypto Wallet Balance
    final cryptoResponse = await http.post(
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

    if (cryptoResponse.statusCode != 200) {
      final errorData = jsonDecode(cryptoResponse.body);
      throw Exception(
        'Failed to update crypto wallet: ${errorData['message'] ?? cryptoResponse.body}',
      );
    }

    // Step 2: Update Fiat Wallet Balance (Deduct total amount)
    final fiatResponse = await http.post(
      Uri.parse('$ProductionBaseUrl/api/wallet/FiatAmountUpdate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': authManager.userId,
        'currency': _selectedFiat,
        'amount': totalAmount, // Deduct fiat amount + fee
      }),
    );

    if (fiatResponse.statusCode != 200) {
      final errorData = jsonDecode(fiatResponse.body);
      throw Exception(
        'Failed to update fiat wallet: ${errorData['message'] ?? fiatResponse.body}',
      );
    }

    // Parse the crypto wallet response
    final cryptoResponseData = jsonDecode(cryptoResponse.body);
    final updatedWallet = CryptoWallet.fromJson(cryptoResponseData);

    // Store values for dialog
    final cryptoAmount = _cryptoAmount.toStringAsFixed(8);
    final feeAmount = _fee.toStringAsFixed(2);
    final exchangeRate = _exchangeRate.toStringAsFixed(2);
    final coinName = coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto;
    final currentWalletAddress = walletAddress;
    final newBalance = updatedWallet.balance.toStringAsFixed(8);
    final now = DateTime.now().toString();

    // Parse fiat wallet response to get updated fiat balance
    final fiatResponseData = jsonDecode(fiatResponse.body);
    final updatedFiatBalance = fiatResponseData['balance']?.toDouble() ?? _fiatBalance;

    // Show success dialog
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
                _buildDialogText('Crypto Received: $cryptoAmount $coinName'),
                _buildDialogText('Fee: $_selectedFiat $feeAmount'),
                _buildDialogText('Exchange Rate: 1 $coinName = $_selectedFiat $exchangeRate'),
                _buildDialogText('Wallet Address: $currentWalletAddress'),
                _buildDialogText('New Crypto Balance: $newBalance $coinName'),
                _buildDialogText('New Fiat Balance: ${updatedFiatBalance.toStringAsFixed(2)} $_selectedFiat'),
                _buildDialogText('Date: $now'),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => MainScreen(),)),
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

    // Reset state
    _amountController.clear();
    setState(() {
      _cryptoAmount = 0.0;
      _fee = 0.0;
      _exchangeRate = 0.0;
      _fiatBalance = updatedFiatBalance; // Update local fiat balance
    });

    // Refresh wallets and fiat balance
    await _fetchUserWallets();
    await _fetchFiatBalance();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction failed: $e')),
    );
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
                const SizedBox(height: 12),
                // Display fiat balance
                Text(
                  _fiatBalance == null
                      ? 'Balance not available for $_selectedFiat'
                      : 'Available Balance: ${_fiatBalance!.toStringAsFixed(2)} $_selectedFiat',
                  style: GoogleFonts.poppins(
                    color: _fiatBalance == null ? Colors.red : _primaryColor.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
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
                  });
                  // Trigger rate fetch with new crypto selection
                  _fetchExchangeRateWithValidation();
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
            });
            _fetchExchangeRateWithValidation();
            _fetchFiatBalance(); // Fetch balance for new fiat currency
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount ($_selectedFiat)',
            labelStyle: GoogleFonts.poppins(
              color: _lastErrorMessage != null 
                  ? Colors.red.shade700 
                  : _primaryColor.withOpacity(0.7),
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
              borderSide: BorderSide(
                color: _lastErrorMessage != null 
                    ? Colors.red.shade300 
                    : _accentColor.withOpacity(0.3)
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _lastErrorMessage != null 
                    ? Colors.red.shade500 
                    : _accentColor, 
                width: 2
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade500, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade700, width: 2),
            ),
            prefixIcon: Icon(
              Icons.attach_money, 
              color: _lastErrorMessage != null 
                  ? Colors.red.shade600 
                  : _accentColor
            ),
            suffixIcon: _isLoadingRate 
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                      ),
                    ),
                  )
                : null,
            helperText: 'Maximum amount: ${_maxAmount.toStringAsFixed(0)}',
            helperStyle: GoogleFonts.poppins(
              color: _primaryColor.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          style: GoogleFonts.poppins(color: _primaryColor, fontSize: 16),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
        if (_lastErrorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastErrorMessage!,
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
            _isLoadingRate 
                ? 'Exchange Rate: Loading...'
                : _exchangeRate > 0
                    ? 'Exchange Rate: 1 ${coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto ?? 'N/A'} = $_selectedFiat ${_exchangeRate.toStringAsFixed(2)}'
                    : 'Exchange Rate: Enter amount to see rate',
          ),
          const SizedBox(height: 12),
          _buildDetailText(
            'Fee (1.5%): $_selectedFiat ${_fee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildDetailText(
            _cryptoAmount > 0
                ? 'You will receive: ${_cryptoAmount.toStringAsFixed(8)} ${coinNameToMainnet[_selectedCrypto] ?? _selectedCrypto ?? 'N/A'}'
                : 'You will receive: Enter amount to calculate',
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
        onTap: _isLoading || _selectedCrypto == null || _fiatBalance == null
            ? null
            : _confirmTransaction,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
          decoration: BoxDecoration(
            gradient: _isLoading || _selectedCrypto == null || _fiatBalance == null
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
}