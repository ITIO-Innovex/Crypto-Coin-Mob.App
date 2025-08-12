import 'package:carousel_slider/carousel_slider.dart';
import 'package:coincraze/CreateWallet.dart';
import 'package:coincraze/Models/Wallet.dart';
import 'package:coincraze/Screens/AddFundsScreen.dart';
import 'package:coincraze/Screens/BuyCryptoScreen.dart';
import 'package:coincraze/Screens/DetailsTransacitonScreen.dart';
import 'package:coincraze/Screens/TransactionScreen.dart';
import 'package:coincraze/Screens/Transactions.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class FiatWalletScreen extends StatefulWidget {
  @override
  _FiatWalletScreenState createState() => _FiatWalletScreenState();
}

class _FiatWalletScreenState extends State<FiatWalletScreen>
    with TickerProviderStateMixin {
  final Map<String, String> _currencyToFlag = {
    'USD': 'assets/flags/USD.jpg',
    'INR': 'assets/flags/IndianCurrency.jpg',
    'EUR': 'assets/flags/Euro.jpg',
    'GBP': 'assets/flags/GBP.png',
    'JPY': 'assets/flags/Japan.png',
    'CAD': 'assets/flags/CAD.jpg',
    'AUD': 'assets/flags/australian-dollar.jpeg',
    'JOD': 'assets/flags/JOD.jpg',
  };

  late Future<List<Wallet>> _walletsFuture;
  late Future<List<dynamic>> _newsFuture;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _walletsFuture = ApiService().getBalance();
    _newsFuture = _fetchNews();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _fetchNews() async {
    try {
      final wallets = await _walletsFuture;
      final currencies = wallets.map((w) => w.currency.toUpperCase()).toList();
      return await ApiService().fetchCurrencyNews(currencies);
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _walletsFuture = ApiService().getBalance();
      _newsFuture = _fetchNews();
      _fadeController.reset();
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fiat Wallet',
          style: GoogleFonts.poppins(
            fontSize: isLargeScreen ? 28 : 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 166, 167, 170), // Deep blue
              Color.fromARGB(255, 5, 5, 5), // Vibrant blue
              Color.fromARGB(255, 129, 97, 97), // Light blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: Colors.white,
            backgroundColor: Color(0xFF2E2E2F),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: FutureBuilder<List<Wallet>>(
                future: _walletsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerLoading(isLargeScreen);
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                    );
                  }
                  final wallets = snapshot.data ?? [];
                  final availableCurrencies = wallets
                      .map((w) => w.currency.toUpperCase())
                      .toList();
                  if (wallets.isEmpty) {
                    return _buildEmptyState(context, isLargeScreen);
                  }
                  return SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: isLargeScreen ? 160 : 130),
                        CarouselSlider.builder(
                          itemCount: wallets.length,
                          itemBuilder: (context, index, realIndex) {
                            final wallet = wallets[index];
                            return _buildWalletCard(
                              context,
                              wallet,
                              isLargeScreen,
                            );
                          },
                          options: CarouselOptions(
                            height: isLargeScreen ? 240 : 200,
                            enlargeCenterPage: true,
                            autoPlay: wallets.length > 1,
                            autoPlayInterval: Duration(seconds: 5),
                            aspectRatio: 16 / 9,
                            enableInfiniteScroll: wallets.length > 1,
                            viewportFraction: isLargeScreen ? 0.75 : 0.80,
                            onPageChanged: (index, reason) {},
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 400;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildActionButton(
                                      context: context,
                                      label: 'Add New Wallet',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CreateWalletScreen(),
                                          ),
                                        );
                                      },
                                      isLargeScreen: !isNarrow,
                                    ),
                                    _buildActionButton(
                                      context: context,
                                      label: 'Buy Crypto',
                                      onPressed: () async {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        final userId =
                                            prefs.getString('userId') ?? '';
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BuyCryptoScreen(
                                                  availableCurrencies:
                                                      availableCurrencies,
                                                ),
                                          ),
                                        );
                                      },
                                      isLargeScreen: !isNarrow,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 30),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 30 : 20,
                            vertical: 16,
                          ),
                          child: Text(
                            'Trending Currency News',
                            style: GoogleFonts.poppins(
                              fontSize: isLargeScreen ? 24 : 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        FutureBuilder<List<dynamic>>(
                          future: _newsFuture,
                          builder: (context, newsSnapshot) {
                            if (newsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildNewsShimmer(isLargeScreen);
                            }
                            if (newsSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading news: ${newsSnapshot.error}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              );
                            }
                            final newsArticles = newsSnapshot.data ?? [];
                            if (newsArticles.isEmpty) {
                              return Center(
                                child: Text(
                                  'No news available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: newsArticles.length,
                              itemBuilder: (context, index) {
                                final article = newsArticles[index];
                                return _buildNewsCard(
                                  context,
                                  article,
                                  index,
                                  isLargeScreen,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isLargeScreen) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isLargeScreen ? 300 : 200,
                height: isLargeScreen ? 300 : 200,
                child: Lottie.asset(
                  'assets/lottie/Empty.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'No Wallets Available',
                style: GoogleFonts.poppins(
                  fontSize: isLargeScreen ? 24 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 60 : 40,
                ),
                child: Text(
                  'Start by creating a new wallet to manage your funds securely.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isLargeScreen ? 16 : 14,
                    color: Colors.white70,
                  ),
                ),
              ),
              SizedBox(height: 24),
              _buildActionButton(
                context: context,
                label: 'Create Wallet',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateWalletScreen(),
                    ),
                  );
                },
                isLargeScreen: isLargeScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isLargeScreen) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isLargeScreen ? 160 : 130),
          CarouselSlider.builder(
            itemCount: 3,
            itemBuilder: (context, index, realIndex) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 102, 103, 103),
                        Color.fromARGB(255, 21, 21, 21),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: isLargeScreen ? 16 : 14,
                              backgroundColor: Colors.grey[400],
                            ),
                            SizedBox(width: 10),
                            Container(
                              width: isLargeScreen ? 120 : 100,
                              height: isLargeScreen ? 24 : 20,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: isLargeScreen ? 180 : 150,
                          height: isLargeScreen ? 20 : 18,
                          color: Colors.grey[400],
                        ),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: isLargeScreen ? 36 : 30,
                              height: isLargeScreen ? 36 : 30,
                              color: Colors.grey[400],
                            ),
                            SizedBox(width: 10),
                            Container(
                              width: isLargeScreen ? 36 : 30,
                              height: isLargeScreen ? 36 : 30,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: isLargeScreen ? 240 : 200,
              enlargeCenterPage: true,
              autoPlay: false,
              aspectRatio: 16 / 9,
              enableInfiniteScroll: false,
              viewportFraction: isLargeScreen ? 0.75 : 0.80,
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 40 : 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: isLargeScreen ? 180 : 150,
                      height: isLargeScreen ? 60 : 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color.fromARGB(255, 65, 65, 68),

                            const Color.fromARGB(255, 48, 39, 53),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: isLargeScreen ? 180 : 150,
                      height: isLargeScreen ? 60 : 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4B5EAA), Color(0xFF7B9CFF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 40 : 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: isLargeScreen ? 240 : 200,
                height: isLargeScreen ? 24 : 20,
                color: Colors.white,
              ),
            ),
          ),
          _buildNewsShimmer(isLargeScreen),
        ],
      ),
    );
  }

  Widget _buildNewsShimmer(bool isLargeScreen) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.only(
              left: isLargeScreen ? 30 : 15,
              right: isLargeScreen ? 30 : 15,
              top: index == 0 ? 4 : 8,
              bottom: 8,
            ),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 19, 20, 20),
                  Color.fromARGB(255, 109, 112, 118),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isLargeScreen ? 120 : 100,
                  height: isLargeScreen ? 120 : 100,
                  color: Colors.grey[400],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: isLargeScreen ? 18 : 16,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 6),
                      Container(
                        width: isLargeScreen ? 120 : 100,
                        height: isLargeScreen ? 14 : 12,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletCard(
    BuildContext context,
    Wallet wallet,
    bool isLargeScreen,
  ) {
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
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(-2, -2),
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
                    Color.fromARGB(255, 22, 22, 38), // Deep blue
                    Color.fromARGB(255, 17, 18, 19), // Light blue
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 27, 27, 27).withOpacity(0.6),
                    Color.fromARGB(255, 20, 20, 20).withOpacity(0.4),
                  ],
                ),
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
                    mainAxisAlignment: MainAxisAlignment.start,
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
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white70,
                        size: isLargeScreen ? 34 : 30,
                      ),
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

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required bool isLargeScreen,
  }) {
    return AnimatedScale(
      scale: 1.0,
      duration: Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 65, 59, 59), // Deep blue
              Color.fromARGB(255, 104, 105, 105), // Light blue
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 30 : 32,
              vertical: isLargeScreen ? 20 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation:
                0, // Disable default elevation as shadow is handled by Container
            shadowColor: Colors.transparent,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isLargeScreen ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isLargeScreen,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 17, 17, 18),
                Color.fromARGB(255, 89, 93, 107),
              ],
            ),
          ),
          child: Icon(icon, color: Colors.white, size: isLargeScreen ? 34 : 25),
        ),
      ),
    );
  }

  Widget _buildNewsCard(
    BuildContext context,
    dynamic article,
    int index,
    bool isLargeScreen,
  ) {
    return GestureDetector(
      onTap: () async {
        final url = article['url']?.toString();
        if (url != null && url.isNotEmpty) {
          try {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cannot launch URL: $url')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error launching URL: $e')));
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid URL')));
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(
          left: isLargeScreen ? 30 : 15,
          right: isLargeScreen ? 30 : 15,
          top: index == 0 ? 4 : 8,
          bottom: 8,
        ),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4B5EAA).withOpacity(0.15),
              Color(0xFF93C5FD).withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            article['urlToImage'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      article['urlToImage'],
                      width: isLargeScreen ? 120 : 100,
                      height: isLargeScreen ? 120 : 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: isLargeScreen ? 120 : 100,
                        height: isLargeScreen ? 120 : 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4B5EAA), Color(0xFF7B9CFF)],
                          ),
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: isLargeScreen ? 120 : 100,
                    height: isLargeScreen ? 120 : 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4B5EAA), Color(0xFF7B9CFF)],
                      ),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white70,
                    ),
                  ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] ?? 'No title',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: isLargeScreen ? 16 : 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    article['source']['name'] ?? 'Unknown source',
                    style: GoogleFonts.poppins(
                      fontSize: isLargeScreen ? 13 : 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCountryCode(String currency) {
    final Map<String, String> currencyToCountry = {
      'USD': 'US',
      'INR': 'IN',
      'EUR': 'EU',
      'GBP': 'GB',
      'JPY': 'JP',
      'CAD': 'CA',
      'AUD': 'AU',
      'JOD': 'JO',
    };
    return currencyToCountry[currency] ?? 'UN';
  }
}
