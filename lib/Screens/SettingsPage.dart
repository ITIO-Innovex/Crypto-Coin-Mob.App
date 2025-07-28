import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CryptoSettingsPage extends StatefulWidget {
  const CryptoSettingsPage({super.key});

  @override
  _CryptoSettingsPageState createState() => _CryptoSettingsPageState();
}

class _CryptoSettingsPageState extends State<CryptoSettingsPage> with SingleTickerProviderStateMixin {
  bool isDarkTheme = false;
  bool is2FAEnabled = true;
  bool biometricAuth = false;
  bool priceAlerts = true;
  String selectedLanguage = 'English';
  String selectedCurrency = 'USD';
  String kycStatus = 'Not Started';

  bool isLoading = false;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSettings();
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
        _showSnackBar('Failed to update security settings: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error updating security settings: $e');
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
        _showSnackBar('Failed to update preferences: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error updating preferences: $e');
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
        _showSnackBar('Failed to update notifications: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error updating notifications: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.length < 8) {
      _showSnackBar('New password must be at least 8 characters long');
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
        _showSnackBar('Failed to change password: $error');
      }
    } catch (e) {
      _showSnackBar('Error changing password: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      isLoading = true;
    });
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.post(
        Uri.parse('$ProductionBaseUrl/api/settings/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        _showSnackBar('Logged out successfully');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showSnackBar('Failed to logout: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error logging out: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isDarkTheme ? Colors.black : Colors.white),
        ),
        backgroundColor: isDarkTheme ? Colors.white : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
        elevation: 0,
        backgroundColor: isDarkTheme ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: isDarkTheme ? Colors.white : Colors.black),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(isDarkTheme ? Colors.white : Colors.blue),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 16),
                _buildSectionTitle('Security'),
                SwitchListTile(
                  title: Text('Enable 2FA', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  value: is2FAEnabled,
                  onChanged: (val) {
                    setState(() => is2FAEnabled = val);
                    _updateSecurity();
                  },
                  secondary: Icon(Icons.shield, color: isDarkTheme ? Colors.white : Colors.black),
                  activeColor: isDarkTheme ? Colors.white : const Color.fromARGB(255, 71, 169, 74),
                  inactiveThumbColor: isDarkTheme ? Colors.grey[400] : null,
                  inactiveTrackColor: isDarkTheme ? Colors.grey[700] : null,
                ),
                SwitchListTile(
                  title: Text('Biometric Authentication', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  value: biometricAuth,
                  onChanged: (val) {
                    setState(() => biometricAuth = val);
                    _updateSecurity();
                  },
                  secondary: Icon(Icons.fingerprint, color: isDarkTheme ? Colors.white : Colors.black),
                  activeColor: isDarkTheme ? Colors.white : const Color.fromARGB(255, 71, 169, 74),
                  inactiveThumbColor: isDarkTheme ? Colors.grey[400] : null,
                  inactiveTrackColor: isDarkTheme ? Colors.grey[700] : null,
                ),
                ListTile(
                  leading: Icon(Icons.lock, color: isDarkTheme ? Colors.white : Colors.black),
                  title: Text('Change PIN/Password', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  trailing: Icon(Icons.arrow_forward_ios, color: isDarkTheme ? Colors.white : Colors.black),
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
                Divider(color: isDarkTheme ? Colors.grey[800] : Colors.grey[300]),
                _buildSectionTitle('App Preferences'),
                SwitchListTile(
                  title: Text('Dark Theme', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  value: isDarkTheme,
                  onChanged: (val) {
                    setState(() => isDarkTheme = val);
                    _updatePreferences();
                  },
                  secondary: Icon(isDarkTheme? Icons.dark_mode : Icons.sunny, color: isDarkTheme ? Colors.white : Colors.black),
                  activeColor: isDarkTheme ? Colors.white : Colors.blue,
                  inactiveThumbColor: isDarkTheme ? Colors.grey[400] : null,
                  inactiveTrackColor: isDarkTheme ? Colors.grey[700] : null,
                ),
                ListTile(
                  leading: Icon(Icons.language, color: isDarkTheme ? Colors.white : Colors.black),
                  title: Text('Language', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  subtitle: Text(selectedLanguage, style: TextStyle(color: isDarkTheme ? Colors.grey[400] : Colors.grey[600])),
                  trailing: Icon(Icons.arrow_forward_ios, color: isDarkTheme ? Colors.white : Colors.black),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDarkTheme ? Colors.black : Colors.white,
                        title: Text(
                          'Select Language',
                          style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: selectedLanguage,
                              dropdownColor: isDarkTheme ? Colors.grey[900] : Colors.white,
                              items: ['English', 'Hindi', 'Urdu', 'Spanish']
                                  .map(
                                    (lang) => DropdownMenuItem(
                                      value: lang,
                                      child: Text(
                                        lang,
                                        style: TextStyle(
                                          color: isDarkTheme ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() => selectedLanguage = val!);
                                _updatePreferences();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.attach_money, color: isDarkTheme ? Colors.white : Colors.black),
                  title: Text('Currency', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  subtitle: Text(selectedCurrency, style: TextStyle(color: isDarkTheme ? Colors.grey[400] : Colors.grey[600])),
                  trailing: Icon(Icons.arrow_forward_ios, color: isDarkTheme ? Colors.white : Colors.black),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDarkTheme ? Colors.black : Colors.white,
                        title: Text(
                          'Select Currency',
                          style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: selectedCurrency,
                              dropdownColor: isDarkTheme ? Colors.grey[900] : Colors.white,
                              items: ['USD', 'INR', 'EUR', 'GBP']
                                  .map(
                                    (curr) => DropdownMenuItem(
                                      value: curr,
                                      child: Text(
                                        curr,
                                        style: TextStyle(
                                          color: isDarkTheme ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() => selectedCurrency = val!);
                                _updatePreferences();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Divider(color: isDarkTheme ? Colors.grey[800] : Colors.grey[300]),
                _buildSectionTitle('Notifications'),
                SwitchListTile(
                  title: Text('Price Alerts', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  value: priceAlerts,
                  onChanged: (val) {
                    setState(() => priceAlerts = val);
                    _updateNotifications();
                  },
                  secondary: Icon(Icons.notifications, color: isDarkTheme ? Colors.white : Colors.black),
                  activeColor: isDarkTheme ? Colors.white : const Color.fromARGB(255, 71, 169, 74),
                  inactiveThumbColor: isDarkTheme ? Colors.grey[400] : null,
                  inactiveTrackColor: isDarkTheme ? Colors.grey[700] : null,
                ),
                Divider(color: isDarkTheme ? Colors.grey[800] : Colors.grey[300]),
                _buildSectionTitle('Account'),
                ListTile(
                  leading: Icon(Icons.verified_user, color: isDarkTheme ? Colors.white : Colors.black),
                  title: Text('KYC Status', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  subtitle: Text(kycStatus, style: TextStyle(color: isDarkTheme ? Colors.grey[400] : Colors.grey[600])),
                  trailing: Icon(Icons.arrow_forward_ios, color: isDarkTheme ? Colors.white : Colors.black),
                  onTap: () {
                    _showSnackBar('KYC Status: $kycStatus');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: isDarkTheme ? Colors.white : Colors.black),
                  title: Text('Logout', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  onTap: _logout,
                ),
                Divider(color: isDarkTheme ? Colors.grey[800] : Colors.grey[300]),
                _buildSectionTitle('About'),
                ListTile(
                  leading: Icon(Icons.info, color: isDarkTheme ? Colors.white : Colors.black),
                  title: Text('App Version', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  subtitle: Text('v1.0.0', style: TextStyle(color: isDarkTheme ? Colors.grey[400] : Colors.grey[600])),
                ),
                ListTile(
                  leading: Icon(Icons.description, color: isDarkTheme ? Colors.white : Colors.black),
                  title: Text('Privacy Policy', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  onTap: () {
                    _showSnackBar('Opening Privacy Policy...');
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
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
  _AnimatedChangePasswordDialogState createState() => _AnimatedChangePasswordDialogState();
}

class _AnimatedChangePasswordDialogState extends State<_AnimatedChangePasswordDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
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
                padding: const EdgeInsets.all(24),
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
                            color: widget.isDarkTheme ? Colors.white : Colors.blue[800],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: widget.isDarkTheme ? Colors.white : Colors.grey[700],
                            size: 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter your current and new password.',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: widget.currentPasswordController,
                      obscureText: true,
                      style: TextStyle(color: widget.isDarkTheme ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        hintText: 'Enter current password',
                        prefixIcon: Icon(Icons.lock_outline, color: widget.isDarkTheme ? Colors.white : Colors.blue),
                        labelStyle: TextStyle(color: widget.isDarkTheme ? Colors.grey[400] : Colors.grey[700]),
                        hintStyle: TextStyle(color: widget.isDarkTheme ? Colors.grey[600] : Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.isDarkTheme ? Colors.grey[700]! : Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.isDarkTheme ? Colors.grey[700]! : Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.isDarkTheme ? Colors.white : Colors.blue, width: 2),
                        ),
                        filled: true,
                        fillColor: widget.isDarkTheme ? Colors.grey[800] : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.newPasswordController,
                      obscureText: true,
                      style: TextStyle(color: widget.isDarkTheme ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password (min 8 characters)',
                        prefixIcon: Icon(Icons.lock_outline, color: widget.isDarkTheme ? Colors.white : Colors.blue),
                        labelStyle: TextStyle(color: widget.isDarkTheme ? Colors.grey[400] : Colors.grey[700]),
                        hintStyle: TextStyle(color: widget.isDarkTheme ? Colors.grey[600] : Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.isDarkTheme ? Colors.grey[700]! : Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.isDarkTheme ? Colors.grey[700]! : Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.isDarkTheme ? Colors.white : Colors.blue, width: 2),
                        ),
                        filled: true,
                        fillColor: widget.isDarkTheme ? Colors.grey[800] : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: widget.isDarkTheme ? Colors.grey[400] : Colors.grey[700],
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            widget.onChange();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                                    ? [Colors.blue[300]!, Colors.blue[700]!]
                                    : [Colors.blue, Colors.blue[700]!],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              constraints: const BoxConstraints(minWidth: 100, minHeight: 48),
                              child: Text(
                                'Change',
                                style: TextStyle(
                                  color: widget.isDarkTheme ? Colors.black : Colors.white,
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