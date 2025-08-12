import 'package:cached_network_image/cached_network_image.dart';
import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/BottomBar.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/HomeScreen.dart';
import 'package:coincraze/LoginScreen.dart';
import 'package:coincraze/Models/Wallet.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:coincraze/theme/theme_provider.dart';
import 'package:coincraze/utils/CurrencySymbol.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CryptoSettingsPage extends StatefulWidget {
  const CryptoSettingsPage({super.key});

  @override
  _CryptoSettingsPageState createState() => _CryptoSettingsPageState();
}

class _CryptoSettingsPageState extends State<CryptoSettingsPage>
    with SingleTickerProviderStateMixin {
  bool isDarkTheme = false;
  bool is2FAEnabled = true;
  bool biometricAuth = false;
  bool priceAlerts = true;
  String selectedLanguage = 'English';
  String selectedCurrency = 'USD';
  String kycStatus = 'Not Started';
  final profilePicture = AuthManager().profilePicture;
  final fullName = AuthManager().firstName ?? 'Kyc Required.';
  final email = AuthManager().email ?? 'Unable To Fetch Email ID.';
  late Future<List<Wallet>> _walletsFuture;
  bool isLoading = false;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _walletsFuture = ApiService().getBalance();
    _fetchSettings();
  }

  final ImagePicker _picker = ImagePicker();

  void _confirmLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkTheme ? Colors.grey[300] : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: isDarkTheme ? Colors.white : Colors.blue,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performLogout();
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await AuthManager().clearUserData();
      if (!Hive.isBoxOpen('userBox')) {
        await Hive.openBox('userBox');
      }
      await Hive.box('userBox').clear();
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully logged out',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final userId = AuthManager().userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ID not found. Please log in again.',
              style: TextStyle(color: Colors.red),
            ),
          ),
        );
        return;
      }
      final profilePicturePath = await AuthManager().uploadProfilePicture(
        userId,
        image.path,
      );
      if (profilePicturePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => const CryptoSettingsPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading profile picture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchSettings() async {
    setState(() {
      isLoading = true;
    });
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.get(
        Uri.parse('$ProductionBaseUrl/api/settings/settings'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          is2FAEnabled = data['securitySettings']['twoFactorAuth'] ?? false;
          biometricAuth = data['securitySettings']['biometricAuth'] ?? false;
          isDarkTheme = data['preferences']['theme'] == 'Dark';
          selectedLanguage = data['preferences']['language'] ?? 'English';
          selectedCurrency = data['preferences']['currency'] ?? 'USD';
          priceAlerts = data['notificationPreferences']['priceAlerts'] ?? true;
          kycStatus = data['kyc']['status'] ?? 'Not Started';
        });
      } else {
        _showSnackBar('Failed to fetch settings: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error fetching settings: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateSecurity() async {
    setState(() {
      isLoading = true;
    });
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.put(
        Uri.parse('$ProductionBaseUrl/api/settings/update-security'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'twoFactorAuth': is2FAEnabled,
          'biometricAuth': biometricAuth,
        }),
      );
      if (response.statusCode == 200) {
        _showSnackBar('Security settings updated successfully');
      } else {
        _showSnackBar(
          'Failed to update security settings: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error updating security settings: $e', isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updatePreferences() async {
    setState(() {
      isLoading = true;
    });
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.put(
        Uri.parse('$ProductionBaseUrl/api/settings/update-preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'theme': isDarkTheme ? 'Dark' : 'Light',
          'language': selectedLanguage,
          'currency': selectedCurrency,
        }),
      );
      if (response.statusCode == 200) {
        _showSnackBar('Preferences updated successfully');
      } else {
        _showSnackBar(
          'Failed to update preferences: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error updating preferences: $e', isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateNotifications() async {
    setState(() {
      isLoading = true;
    });
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.put(
        Uri.parse('$ProductionBaseUrl/api/settings/update-notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'priceAlerts': priceAlerts}),
      );
      if (response.statusCode == 200) {
        _showSnackBar('Notification preferences updated successfully');
      } else {
        _showSnackBar(
          'Failed to update notifications: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error updating notifications: $e', isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.length < 8) {
      _showSnackBar(
        'New password must be at least 8 characters long',
        isError: true,
      );
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.put(
        Uri.parse('$ProductionBaseUrl/api/settings/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );
      if (response.statusCode == 200) {
        _showSnackBar('Password changed successfully');
        _currentPasswordController.clear();
        _newPasswordController.clear();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Unknown error';
        _showSnackBar('Failed to change password: $error', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error changing password: $e', isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isDarkTheme ? Colors.black : Colors.white),
        ),
        backgroundColor: isError
            ? Colors.red
            : (isDarkTheme ? Colors.white : Colors.green),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Sync local isDarkTheme with ThemeProvider
        isDarkTheme = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDarkTheme ? Colors.black : Colors.white,
          appBar: AppBar(
            leading: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => MainScreen()),
                );
              },
              child: Icon(
                Icons.arrow_back, 
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            title: Text(
              'Profile Page',
              style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: isDarkTheme ? Colors.black : Colors.white,
            iconTheme: IconThemeData(
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkTheme ? Colors.white : Colors.blue,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profilePicture != null
                              ? CachedNetworkImageProvider(
                                  '$ProductionBaseUrl/$profilePicture',
                                )
                              : AssetImage('assets/images/ProfileImage.jpg')
                                    as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Color.fromARGB(255, 140, 143, 140),
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                _buildSectionTitle('Security'),
                ListTile(
                  leading: Icon(
                    Icons.lock,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  title: Text(
                    'Change PIN/Password',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _AnimatedChangePasswordDialog(
                        isDarkTheme: isDarkTheme,
                        currentPasswordController: _currentPasswordController,
                        newPasswordController: _newPasswordController,
                        onChange: _changePassword,
                      ),
                    );
                  },
                ),
                Divider(
                  color: isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                ),
                _buildSectionTitle('App Preferences'),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      title: Text(
                        'Dark Theme',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      value: themeProvider.isDarkMode,
                      onChanged: (val) {
                        themeProvider.toggleTheme();
                        setState(() => isDarkTheme = val);
                        _updatePreferences();
                      },
                      secondary: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.sunny,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      ),
                      activeColor: themeProvider.isDarkMode ? Colors.white : Colors.blue,
                      inactiveThumbColor: themeProvider.isDarkMode ? Colors.grey[400] : null,
                      inactiveTrackColor: themeProvider.isDarkMode ? Colors.grey[700] : null,
                    );
                  },
                ),
                FutureBuilder<List<Wallet>>(
                  future: _walletsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text(
                          'Loading currencies...',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        title: Text(
                          'Error loading currencies',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    } else if (snapshot.hasData) {
                      final currencies = snapshot.data!
                          .map((wallet) => wallet.currency.trim().toUpperCase())
                          .toSet()
                          .toList();

                      return ListTile(
                        leading: Text(
                          CurrencyHelper.getSymbol(selectedCurrency),
                          style: TextStyle(
                            fontSize: 20,
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                        ),

                        title: Text(
                          'Currency',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '${CurrencyHelper.getSymbol(selectedCurrency)} $selectedCurrency',
                          style: TextStyle(
                            color: isDarkTheme
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: isDarkTheme
                                  ? Colors.grey[900]
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 20,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Select Currency',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkTheme
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 350, // Adjust height as needed
                                      child: ListView.separated(
                                        itemCount: currencies.length,
                                        separatorBuilder: (context, index) =>
                                            Divider(
                                              color: isDarkTheme
                                                  ? Colors.grey[700]
                                                  : Colors.grey[300],
                                              thickness: 1,
                                              height: 1,
                                            ),
                                        itemBuilder: (context, index) {
                                          final curr = currencies[index];
                                          final symbol =
                                              CurrencyHelper.getSymbol(curr);
                                          final flag = getFlagEmoji(curr);

                                          return ListTile(
                                            title: Text(
                                              '$flag  $curr',
                                              style: TextStyle(
                                                color: isDarkTheme
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            onTap: () {
                                              setState(
                                                () => selectedCurrency = curr,
                                              );
                                              _updatePreferences();
                                              Navigator.pop(context);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: isDarkTheme
                                              ? Colors.grey[400]
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return ListTile(
                        title: Text(
                          'No currencies available',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }
                  },
                ),

                Divider(
                  color: isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                ),
                _buildSectionTitle('Notifications'),
                SwitchListTile(
                  title: Text(
                    'Price Alerts',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  value: priceAlerts,
                  onChanged: (val) {
                    setState(() => priceAlerts = val);
                    _updateNotifications();
                  },
                  secondary: Icon(
                    Icons.notifications,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  activeColor: isDarkTheme
                      ? Colors.white
                      : Color.fromARGB(255, 71, 169, 74),
                  inactiveThumbColor: isDarkTheme ? Colors.grey[400] : null,
                  inactiveTrackColor: isDarkTheme ? Colors.grey[700] : null,
                ),
                Divider(
                  color: isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                ),
                _buildSectionTitle('Account'),
                ListTile(
                  leading: Icon(
                    Icons.verified_user,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  title: Text(
                    'KYC Status',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    kycStatus,
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  onTap: () {
                    _showSnackBar('KYC Status: $kycStatus');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: _confirmLogoutDialog,
                ),
                Divider(
                  color: isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                ),
                _buildSectionTitle('About'),
                ListTile(
                  leading: Icon(
                    Icons.info,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  title: Text(
                    'App Version',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.description,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  title: Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () async {
                    const url =
                        'https://vikas-web.github.io/CoinCrazeLandingPage/privacy-policy.html';
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
                ),
              ],
            ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isDarkTheme ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
    );
  }
}

class _AnimatedChangePasswordDialog extends StatefulWidget {
  final bool isDarkTheme;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final VoidCallback onChange;

  const _AnimatedChangePasswordDialog({
    required this.isDarkTheme,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.onChange,
  });

  @override
  _AnimatedChangePasswordDialogState createState() =>
      _AnimatedChangePasswordDialogState();
}

class _AnimatedChangePasswordDialogState
    extends State<_AnimatedChangePasswordDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: widget.isDarkTheme ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: widget.isDarkTheme
                                ? Colors.white
                                : const Color.fromARGB(255, 14, 14, 14),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: widget.isDarkTheme
                                ? Colors.white
                                : Colors.grey[700],
                            size: 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Enter your current and new password.',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isDarkTheme
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: widget.currentPasswordController,
                      obscureText: !_isCurrentPasswordVisible,
                      style: TextStyle(
                        color: widget.isDarkTheme ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        hintText: 'Enter current password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: widget.isDarkTheme
                              ? Colors.white
                              : const Color.fromARGB(255, 14, 14, 14),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isCurrentPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: widget.isDarkTheme
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _isCurrentPasswordVisible =
                                  !_isCurrentPasswordVisible;
                            });
                          },
                        ),
                        labelStyle: TextStyle(
                          color: widget.isDarkTheme
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
                        hintStyle: TextStyle(
                          color: widget.isDarkTheme
                              ? Colors.grey[600]
                              : Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDarkTheme
                                ? Colors.grey[700]!
                                : Colors.grey.shade400,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDarkTheme
                                ? Colors.grey[700]!
                                : Colors.grey.shade400,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDarkTheme
                                ? Colors.white
                                : const Color.fromARGB(255, 14, 14, 14),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: widget.isDarkTheme
                            ? Colors.grey[800]
                            : Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: widget.newPasswordController,
                      obscureText: !_isNewPasswordVisible,
                      style: TextStyle(
                        color: widget.isDarkTheme ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password (min 8 characters)',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: widget.isDarkTheme
                              ? Colors.white
                              : const Color.fromARGB(255, 14, 14, 14),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isNewPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: widget.isDarkTheme
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible;
                            });
                          },
                        ),
                        labelStyle: TextStyle(
                          color: widget.isDarkTheme
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
                        hintStyle: TextStyle(
                          color: widget.isDarkTheme
                              ? Colors.grey[600]
                              : Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDarkTheme
                                ? Colors.grey[700]!
                                : Colors.grey.shade400,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDarkTheme
                                ? Colors.grey[700]!
                                : Colors.grey.shade400,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDarkTheme
                                ? Colors.white
                                : const Color.fromARGB(255, 14, 14, 14),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: widget.isDarkTheme
                            ? Colors.grey[800]
                            : Colors.white,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: widget.isDarkTheme
                                ? Colors.grey[400]
                                : Colors.grey[700],
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            widget.onChange();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.isDarkTheme
                                    ? [
                                        const Color.fromARGB(255, 93, 95, 96)!,
                                        Colors.blue[700]!,
                                      ]
                                    : [
                                        const Color.fromARGB(255, 10, 10, 10),
                                        Colors.blue[700]!,
                                      ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              constraints: BoxConstraints(
                                minWidth: 100,
                                minHeight: 48,
                              ),
                              child: Text(
                                'Change',
                                style: TextStyle(
                                  color: widget.isDarkTheme
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
