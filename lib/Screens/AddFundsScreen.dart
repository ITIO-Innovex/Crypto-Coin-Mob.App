import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/Models/Wallet.dart';
import 'package:coincraze/Screens/NotificationScreen.dart';
import 'package:coincraze/Screens/TransferSuccess.dart';
import 'package:coincraze/Services/RazorpayService.dart';
import 'package:coincraze/Services/Stripe_service.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AddFundsScreen extends StatefulWidget {
  final String userId;
  final String currency;

  const AddFundsScreen({required this.userId, required this.currency, Key? key})
      : super(key: key);

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _paymentMethod = 'stripe';
  double walletBalance = 0.0;
  bool _isProcessing = false;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  final Map<String, String> _currencyToFlag = {
    'USD': 'assets/flags/USD.jpg',
    'EUR': 'assets/flags/EuroFlag.png',
    'INR': 'assets/flags/IndianCurrency.jpg',
    'GBP': 'assets/flags/GBP.png',
    'JPY': 'assets/flags/Japan.png',
    'CAD': 'assets/flags/CAD.jpg',
    'AUD': 'assets/flags/australian-dollar.jpeg',
  };

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'INR': '₹',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
  };

  String get _currencySymbol =>
      _currencySymbols[widget.currency.toUpperCase()] ?? '';

  @override
  void initState() {
    super.initState();
    StripeService.init();
    fetchWalletDetails();
    _initializeNotifications();
    _requestNotificationPermissions();
  }

  void _initializeNotifications() async {
    print('Initializing notifications');
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );
    if (initialized != true) {
      print('Notification initialization failed');
    }

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'transaction_channel',
        'Transaction Notifications',
        description: 'Notifications for successful transactions',
        importance: Importance.max,
      ),
    );
    print('Notification channel created');
  }

  Future<void> _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      print('Notification permission granted: $granted');
      if (granted != true) {
        print('Notification permission not granted');
      }
    } else if (Platform.isIOS) {
      final bool? granted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      print('iOS Notification permission granted: $granted');
      if (granted != true) {
        print('iOS Notification permission not granted');
      }
    }
  }

  Future<void> _showNotification(double amount) async {
    print('Attempting to show notification for amount: $amount');
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'transaction_channel',
      'Transaction Notifications',
      channelDescription: 'Notifications for successful transactions',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    final title = 'Transaction Successful';
    final message =
        'Your transaction of ${_currencySymbol}${amount.toStringAsFixed(2)} has been successfully completed.';

    try {
      // Show local notification
      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        message,
        platformChannelSpecifics,
        payload: 'transaction_success',
      );
      print('Notification shown successfully');

      // Save notification to MongoDB
      final apiService = ApiService();
      print(widget.userId);
      await apiService.saveNotification(
        userId: widget.userId,
        title: title,
        message: message,
        currency: widget.currency,
        amount: amount,
      );
      print('Notification saved to MongoDB');
    } catch (e) {
      print('Error in _showNotification: $e');
    }
  }

  Future<void> fetchWalletDetails() async {
    try {
      final wallets = await ApiService().getBalance();
      final wallet = wallets.firstWhere(
        (w) => w.currency.toUpperCase() == widget.currency.toUpperCase(),
        orElse: () => Wallet(
          id: '',
          userId: widget.userId,
          currency: widget.currency,
          balance: 0.0,
        ),
      );
      setState(() => walletBalance = wallet.balance);
    } catch (e) {
      print("Error fetching balance: $e");
    }
  }

  Future<void> _addFunds() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_paymentMethod == 'stripe') {
        final apiService = ApiService();
        final response = await apiService.initiateStripePayment(
          widget.userId,
          amount,
          widget.currency,
        );
        final clientSecret = response['clientSecret'];
        if (clientSecret == null || clientSecret.isEmpty) {
          throw Exception('Stripe client secret missing');
        }

        await StripeService.makePayment(clientSecret);

        final confirmResponse = await apiService.confirmStripePayment(
          clientSecret,
        );
        if (confirmResponse['success'] == true) {
          await fetchWalletDetails();
          print('Calling showNotification for Stripe');
          await _showNotification(amount);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionSuccessScreen(
                amount: amount,
                currency: widget.currency,
              ),
            ),
          );
        } else {
          throw Exception(
            'Payment confirmation failed: ${confirmResponse['error']}',
          );
        }
      } else {
        final apiService = ApiService();
        final response = await apiService.initiateRazorpayPayment(
          widget.userId,
          amount,
          widget.currency,
        );

        if (response['orderId'] == null || response['key'] == null) {
          throw Exception('Invalid Razorpay response: Missing orderId or key');
        }

        final razorpay = RazorpayService();
        try {
          await razorpay.makePayment(
            response['orderId'],
            response['key'],
            amount,
            widget.currency,
          );
          await fetchWalletDetails();
          print('Calling showNotification for Razorpay');
          await _showNotification(amount);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionSuccessScreen(
                amount: amount,
                currency: widget.currency,
              ),
            ),
          );
        } finally {
          razorpay.dispose();
        }
      }
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('Failed to initiate Razorpay payment')) {
        errorMessage = 'Unable to process payment. Please try again later.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilePicture = AuthManager().profilePicture;
    final fullName = AuthManager().firstName ?? 'User';
    final flagImage = _currencyToFlag[widget.currency.toUpperCase()];
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Add Funds',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationsScreen(
                                // userId: widget.userId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black87.withOpacity(0.7),
                          Colors.black54.withOpacity(0.5),
                        ],
                      ),
                      image: flagImage != null
                          ? DecorationImage(
                              image: AssetImage(flagImage),
                              fit: BoxFit.cover,
                              opacity: 0.2,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        Text(
                          '${widget.currency.toUpperCase()} Wallet',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Balance: ${_currencySymbol}${walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _currencySymbol,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _paymentMethod,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black54,
                        ),
                        onChanged: (val) =>
                            setState(() => _paymentMethod = val!),
                        items: [
                          DropdownMenuItem(
                            value: 'stripe',
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/S.jpeg',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Stripe (Card)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'razorpay',
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/R.jpeg',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Razorpay (UPI/Card)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: _isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black87),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _addFunds,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Add Funds',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showNotification(100.0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Test Notification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}