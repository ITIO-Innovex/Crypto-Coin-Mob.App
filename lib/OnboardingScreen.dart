import 'package:coincraze/LoginScreen.dart';
import 'package:coincraze/ProfilePage.dart';
import 'package:coincraze/Screens/SettingsPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<Offset> _textAnimation;

  // Define onboarding pages data
  final List<Map<String, String>> _pages = [
    {
      'title': 'Simplify your life\nwith CoinCraze',
      'description': 'Spend, earn and track\nfinancial activity',
    },
    {
      'title': 'Secure Transactions\nMade Simple',
      'description': 'Send and receive crypto\nwith ease and safety',
    },
    {
      'title': 'Grow Your Wealth',
      'description': 'Invest and manage your\ncrypto portfolio',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
      _animationController.reset();
      _animationController.forward();
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => LoginScreen()));
    }
  }

  void _skipToEnd() {
    _pageController.jumpToPage(_pages.length - 1);
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => CryptoSettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with a placeholder gradient
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/ss.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.difference,
                ),
              ),
            ),
          ),
          // Settings button at top left
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              onPressed: _navigateToSettings,
              icon: Icon(
                Icons.settings,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
          // Skip button at top right
          Positioned(
            top: 40,
            right: 16,
            child: TextButton(
              onPressed: _skipToEnd,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Static logo and card with scrolling text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Image.asset(
                  'assets/images/NoBgLogo.png',
                  height: 250,
                  width: 250,
                ),
                Spacer(),
                // Card with PageView for scrolling text content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    height: 220,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          height: 150, // Reduced height since button is outside
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _pages.length,
                            itemBuilder: (context, index) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SlideTransition(
                                    position: _textAnimation,
                                    child: Text(
                                      _pages[index]['title']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  SlideTransition(
                                    position: _textAnimation,
                                    child: Text(
                                      _pages[index]['description']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  // Dots indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _pages.length,
                                      (i) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: i == _currentPage ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Static Next button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}