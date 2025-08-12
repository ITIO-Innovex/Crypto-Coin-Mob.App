import 'dart:async'; // Added for Timer
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/LoginScreen.dart';
import 'package:coincraze/ProfilePage.dart';
import 'package:coincraze/Screens/DetailsTransacitonScreen.dart';
import 'package:coincraze/Screens/FiatWalletScreen.dart';
import 'package:coincraze/Screens/NotificationScreen.dart';
import 'package:coincraze/Screens/SellCryptoScreen.dart';
import 'package:coincraze/Screens/SettingsPage.dart';
import 'package:coincraze/Screens/Transactions.dart';
import 'package:coincraze/WalletList.dart';
import 'package:coincraze/deposit.dart';
import 'package:coincraze/newKyc.dart';
import 'package:coincraze/walletScreen.dart';
import 'package:coincraze/Models/CryptoWallet.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart'; // Added for skeleton loading

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  String? email;
  double btcPrice = 0.0; // State variable for live BTC price

  // Key to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Crypto data
  List<Map<String, dynamic>> cryptoData = [];
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  Timer? _priceUpdateTimer; // Timer for periodic updates
  
  // Bitcoin wallet address
  String? bitcoinWalletAddress;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCryptoData();
    _checkHiveData();
    _checkKycStatus();
    _fetchBitcoinWalletAddress(); // Fetch Bitcoin wallet address
    // Set up timer to fetch crypto data every 30 seconds
    // _priceUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
    //   _fetchCryptoData();
    // });
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  // Check KYC status and show dialog if incomplete
  void _checkKycStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isKycCompleted = AuthManager().kycCompleted ?? false;
      if (!isKycCompleted) {
        _showKycDialog();
      }
    });
  }

  // Show bottom dialog for incomplete KYC
  void _showKycDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Complete Your KYC',
                style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Text(
                'Please complete your KYC to use all functionalities of the app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => NewKYC()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.08,
                    vertical: MediaQuery.of(context).size.height * 0.02,
                  ),
                ),
                child: Text(
                  'Go to KYC',
                  style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
            ],
          ),
        );
      },
    );
  }

  void _checkHiveData() async {
    if (!Hive.isBoxOpen('userBox')) {
      await Hive.openBox('userBox');
    }
    final userBox = Hive.box('userBox');
    final allKeys = userBox.keys;
    for (var key in allKeys) {
      final value = userBox.get(key);
      print('Key: $key, Value: $value');
    }
  }

  Future<void> _loadUserData() async {
    if (!Hive.isBoxOpen('userBox')) {
      await Hive.openBox('userBox');
    }
    final userBox = Hive.box('userBox');
    final storedEmail = userBox.get('email');
    setState(() {
      email = storedEmail ?? 'User';
    });
    await AuthManager().loadSavedDetails(); // Load AuthManager data
  }

  // Fetch Bitcoin wallet address
  Future<void> _fetchBitcoinWalletAddress() async {
    try {
      final wallets = await _apiService.getCryptoWalletBalances();
      print('Fetched Wallets for Bitcoin address: $wallets');
      
      // Find Bitcoin wallet (check for different possible names)
      final bitcoinWallet = wallets.firstWhere(
        (wallet) => 
          wallet.currency.toUpperCase() == 'BTC_TEST' ||
          wallet.currency.toLowerCase() == 'bitcoin' ||
          wallet.currency.toLowerCase() == 'btc' ||
          wallet.currency.toLowerCase().contains('bitcoin') ||
          wallet.currency.toLowerCase() == 'btc_test' ||
          wallet.currency.toLowerCase().contains('btc'),
        orElse: () => CryptoWallet(currency: ''),
      );
      
      if (bitcoinWallet.currency.isNotEmpty && bitcoinWallet.address != null) {
        print('Found Bitcoin wallet: ${bitcoinWallet.currency}, Address: ${bitcoinWallet.address}');
        setState(() {
          bitcoinWalletAddress = bitcoinWallet.address;
        });
        print('Bitcoin wallet address set: $bitcoinWalletAddress');
      } else {
        print('Bitcoin wallet not found. Available wallets:');
        for (var wallet in wallets) {
          print('- Currency: ${wallet.currency}, Address: ${wallet.address}');
        }
        setState(() {
          bitcoinWalletAddress = 'Bitcoin wallet not found';
        });
      }
    } catch (e) {
      print('Error fetching Bitcoin wallet address: $e');
      // Keep the default hardcoded address as fallback
      setState(() {
        bitcoinWalletAddress = 'tb1qtu8n3jz7q5zmdrelqc28lmvglf9fdkluhelw7e';
      });
    }
  }

  Future<void> _fetchCryptoData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          final btcData = data.firstWhere(
            (item) => item['id'] == 'bitcoin',
            orElse: () => {'current_price': 0.0},
          );
          btcPrice = btcData['current_price']?.toDouble() ?? 0.0;

          cryptoData = List<Map<String, dynamic>>.from(
            data.map((item) {
              final sparkline =
                  item['sparkline_in_7d'] as Map<String, dynamic>? ?? {};
              final prices =
                  sparkline['price'] as List<dynamic>? ?? List.filled(20, 0.0);
              final normalizedPrices = _generateZigzagPrices(
                prices,
                item['price_change_percentage_24h'] ?? 0.0,
              );
              final imageUrl = item['image'] as String? ?? '';
              print('Debug - Coin: ${item['name']}, Image URL: $imageUrl');
              return {
                'name': item['name'] ?? 'Unknown',
                'symbol': (item['symbol'] as String? ?? 'UNK').toUpperCase(),
                'price': item['current_price'] ?? 0.0,
                'change_24h': item['price_change_percentage_24h'] ?? 0.0,
                'prices': normalizedPrices,
                'image': imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://via.placeholder.com/20',
              };
            }),
          );
          isLoading = false;
        });
      } else {
        throw Exception('Data Not Available, status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  List<double> _generateZigzagPrices(List<dynamic> prices, double change) {
    List<double> zigzagPrices = [];
    if (prices.isEmpty) {
      return List.filled(20, 0.0);
    }

    for (int i = 0; i < prices.length; i++) {
      double baseValue = prices[i] is num ? prices[i].toDouble() : 0.0;
      if (i % 2 == 0) {
        zigzagPrices.add(baseValue + (change > 0 ? 0.1 : -0.1));
      } else {
        zigzagPrices.add(baseValue - (change > 0 ? 0.1 : -0.1));
      }
    }
    return zigzagPrices;
  }

  Future<void> _refreshData() async {
    await _fetchCryptoData();
    await _fetchBitcoinWalletAddress(); // Also refresh Bitcoin wallet address
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }

      final userId = AuthManager().userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found. Please log in again.'),
          ),
        );
        return;
      }

      final profilePicturePath = await AuthManager().uploadProfilePicture(
        userId,
        image.path,
      );
      if (profilePicturePath != null) {
        setState(() {
          // Trigger UI update to display new image
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture uploaded successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile picture')),
        );
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
      );
    }
  }

  void _showKycStatus() {
    final isKycCompleted = AuthManager().kycCompleted ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isKycCompleted ? 'Your KYC Is Completed' : 'Please Complete Your KYC',
          style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
        ),
        backgroundColor: isKycCompleted ? Colors.green : Colors.red,
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.05,
            ),
          ),
          content: Text(
            'Are you sure you want to logout? This will clear all saved data.',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await AuthManager().clearUserData();
                  if (!Hive.isBoxOpen('userBox')) {
                    await Hive.openBox('userBox');
                  }
                  final userBox = Hive.box('userBox');
                  await userBox.clear();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Successfully logged out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error logging out: $e',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Skeleton widget for header (menu icon, KYC, notifications, profile avatar)
  Widget _buildSkeletonHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[600]!,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.08,
            height: MediaQuery.of(context).size.width * 0.08,
            color: Colors.grey[800],
          ),
        ),
        Row(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.06,
                height: MediaQuery.of(context).size.width * 0.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[800],
                ),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.06,
                height: MediaQuery.of(context).size.width * 0.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[800],
                ),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.06,
                height: MediaQuery.of(context).size.width * 0.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Skeleton widget for wallet balance section
  Widget _buildSkeletonWalletBalance(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[600]!,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.width * 0.05,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
        Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[600]!,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.width * 0.09,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[600]!,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.05,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // Skeleton widget for buttons (FIAT Wallet, Crypto Wallet, Sell Crypto)
  Widget _buildSkeletonButtons(BuildContext context) {
    return Wrap(
      spacing: MediaQuery.of(context).size.width * 0.02,
      runSpacing: MediaQuery.of(context).size.height * 0.02,
      alignment: WrapAlignment.spaceEvenly,
      children: List.generate(
        3,
        (index) => Column(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.12,
                height: MediaQuery.of(context).size.width * 0.12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[800],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.2,
                height: MediaQuery.of(context).size.width * 0.035,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton widget for crypto prices list
  Widget _buildSkeletonCryptoList(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.15,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5, // Show 5 placeholder items
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: MediaQuery.of(context).size.width * 0.03,
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.55,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.03,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.1,
                            height: MediaQuery.of(context).size.width * 0.1,
                            color: Colors.grey[800],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.width * 0.035,
                            color: Colors.grey[800],
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.width * 0.035,
                            color: Colors.grey[800],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.1,
                            height: MediaQuery.of(context).size.width * 0.03,
                            color: Colors.grey[800],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirstName = AuthManager().firstName ?? 'User';
    final email = AuthManager().email ?? 'email';
    final greeting = getGreeting();
    final profilePicture = AuthManager().profilePicture;
    final isKycCompleted = AuthManager().kycCompleted ?? false;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.20,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 65, 65, 68),
                        const Color.fromARGB(255, 48, 39, 53),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => CryptoSettingsPage(),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: MediaQuery.of(context).size.width * 0.07,
                              backgroundImage: profilePicture != null
                                  ? CachedNetworkImageProvider(
                                      '$ProductionBaseUrl/$profilePicture',
                                    )
                                  : const AssetImage(
                                          'assets/images/ProfileImage.jpg',
                                        )
                                        as ImageProvider,
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.03,
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hey, $FirstName!',
                                  style: GoogleFonts.poppins(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.05,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                      255,
                                      234,
                                      232,
                                      232,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  email,
                                  style: GoogleFonts.poppins(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.035,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.home,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
                title: Text(
                  'Home',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              // ListTile(
              //   leading: Icon(
              //     Icons.account_balance_wallet,
              //     color: Colors.white,
              //     size: MediaQuery.of(context).size.width * 0.06,
              //   ),
              //   title: Text(
              //     'Wallet',
              //     style: GoogleFonts.poppins(
              //       color: Colors.white,
              //       fontSize: MediaQuery.of(context).size.width * 0.04,
              //     ),
              //   ),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       CupertinoPageRoute(builder: (context) => WalletScreen()),
              //     );
              //   },
              // ),
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
                title: Text(
                  'Transaction History',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => DetailsTransactionScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
                title: Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => CryptoSettingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
                title: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 2, 5, 97),
                  Color.fromARGB(255, 249, 247, 251),
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
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
                child: isLoading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonHeader(context),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              right: MediaQuery.of(context).size.width * 0.25,
                            ),
                            child: Divider(
                              thickness: 1,
                              color: Color.fromARGB(255, 121, 119, 119),
                            ),
                          ),
                          _buildSkeletonWalletBalance(context),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildSkeletonButtons(context),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildSkeletonCryptoList(context),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          // Placeholder for TransactionsScreen
                          Shimmer.fromColors(
                            baseColor: Colors.grey[800]!,
                            highlightColor: Colors.grey[600]!,
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.2,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                                child: Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                  size:
                                      MediaQuery.of(context).size.width * 0.08,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (isKycCompleted) {
                                        _showKycStatus();
                                      } else {
                                        Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (context) =>
                                                const NewKYC(),
                                          ),
                                        );
                                      }
                                    },
                                    child: Icon(
                                      isKycCompleted
                                          ? Icons.verified_user
                                          : Icons.error_outline,
                                      color: isKycCompleted
                                          ? Colors.green
                                          : Colors.red,
                                      size:
                                          MediaQuery.of(context).size.width *
                                          0.06,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              NotificationsScreen(),
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.notifications,
                                      color: Colors.white,
                                      size:
                                          MediaQuery.of(context).size.width *
                                          0.06,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              CryptoSettingsPage(),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      radius:
                                          MediaQuery.of(context).size.width *
                                          0.06,
                                      backgroundImage: profilePicture != null
                                          ? CachedNetworkImageProvider(
                                              '$ProductionBaseUrl/$profilePicture',
                                            )
                                          : const AssetImage(
                                                  'assets/images/ProfileImage.jpg',
                                                )
                                                as ImageProvider,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          // Wallet Balance with Greeting
                          Padding(
                            padding: EdgeInsets.only(
                              right: MediaQuery.of(context).size.width * 0.25,
                            ),
                            child: Divider(
                              thickness: 1,
                              color: Color.fromARGB(255, 121, 119, 119),
                            ),
                          ),
                          Text(
                            '$greeting, $FirstName!',
                            style: GoogleFonts.poppins(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.05,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 234, 232, 232),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              right: MediaQuery.of(context).size.width * 0.25,
                            ),
                            child: Divider(
                              thickness: 1,
                              color: Color.fromARGB(255, 121, 119, 119),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.015,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current BTC Value',
                                style: GoogleFonts.poppins(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(
                                    255,
                                    169,
                                    166,
                                    166,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.01,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '\$${btcPrice.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                            0.09,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.01,
                              ),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Container(
                                    width: constraints.maxWidth * 0.7,
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                          0.04,
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                          0.015,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        251,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.2),
                                          blurRadius: 0.0,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            bitcoinWalletAddress ?? 'tb1qpj3lnlytpn6s0jrvxy6d8the5nfwkncqzqragp',
                                            style: GoogleFonts.poppins(
                                              fontSize:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.035,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.05,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (bitcoinWalletAddress != null) {
                                              Clipboard.setData(
                                                ClipboardData(
                                                  text: bitcoinWalletAddress!,
                                                ),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Bitcoin address copied to clipboard',
                                                    style: TextStyle(
                                                      fontSize:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.width *
                                                          0.04,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Bitcoin address not available yet',
                                                    style: TextStyle(
                                                      fontSize:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.width *
                                                          0.04,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          child: Icon(
                                            Icons.content_copy,
                                            size:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.04,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          // Deposit and Withdraw Buttons
                          Wrap(
                            spacing: MediaQuery.of(context).size.width * 0.03,
                            runSpacing:
                                MediaQuery.of(context).size.height * 0.025,
                            alignment: WrapAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              FiatWalletScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 1.5,
                                      ),
                                      shape: const CircleBorder(),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.024,
                                      ),
                                      elevation: 5,
                                      shadowColor: Colors.black.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade300,
                                            Colors.blue.shade600,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.02,
                                      ),
                                      child: Icon(
                                        IconlyLight.wallet,
                                        color: Colors.white,
                                        size:
                                            MediaQuery.of(context).size.width *
                                            0.07,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.015,
                                  ),
                                  Text(
                                    'Fiat Wallet',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                          0.034,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                               SizedBox(width: 7),
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              CryptoWalletScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 1.5,
                                      ),
                                      shape: const CircleBorder(),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.024,
                                      ),
                                      elevation: 5,
                                      shadowColor: Colors.black.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade300,
                                            Colors.green.shade600,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.02,
                                      ),
                                      child: Icon(
                                        IconlyLight.chart,
                                        color: Colors.white,
                                        size:
                                            MediaQuery.of(context).size.width *
                                            0.07,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.015,
                                  ),
                                  Text(
                                    'Crypto Wallet',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                          0.034,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 7),
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              CryptoSellScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 1.5,
                                      ),
                                      shape: const CircleBorder(),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.024,
                                      ),
                                      elevation: 5,
                                      shadowColor: Colors.black.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.shade300,
                                            Colors.orange.shade600,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.02,
                                      ),
                                      child: Icon(
                                        IconlyLight.swap,
                                        color: Colors.white,
                                        size:
                                            MediaQuery.of(context).size.width *
                                            0.07,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.015,
                                  ),
                                  Text(
                                    'Sell Crypto',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                          0.034,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          // Live Crypto Prices Horizontal List
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: cryptoData.length,
                              itemBuilder: (context, index) {
                                final crypto = cryptoData[index];
                                final change = crypto['change_24h'] ?? 0.0;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right:
                                        MediaQuery.of(context).size.width *
                                        0.03,
                                  ),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.55,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                            0.03,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(
                                                  MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.02,
                                                ),
                                                child: Image.network(
                                                  crypto['image'] as String? ??
                                                      'https://via.placeholder.com/20',
                                                  width:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.1,
                                                  height:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.1,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return CircularProgressIndicator(
                                                          value:
                                                              loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                              : null,
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        print(
                                                          'Image load error for ${crypto['name']}: $error',
                                                        );
                                                        return Image.asset(
                                                          'assets/images/default_coin.png',
                                                          width:
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.width *
                                                              0.1,
                                                          height:
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.width *
                                                              0.1,
                                                        );
                                                      },
                                                ),
                                              ),
                                              SizedBox(
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.02,
                                              ),
                                              Flexible(
                                                child: Text(
                                                  crypto['name'] as String? ??
                                                      'Unknown',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width *
                                                        0.035,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '\$${crypto['price'].toStringAsFixed(2)}',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.035,
                                                ),
                                              ),
                                              Text(
                                                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                                                style: GoogleFonts.poppins(
                                                  color: change >= 0
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.03,
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.005,
                                              ),
                                              Icon(
                                                change >= 0
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                color: change >= 0
                                                    ? Colors.green
                                                    : Colors.red,
                                                size:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.05,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          // Portfolio Section
                          TransactionsScreen(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData(this.time, this.open, this.high, this.low, this.close);
}
