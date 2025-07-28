import 'package:coincraze/Constants/API.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coincraze/AuthManager.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final userId = AuthManager().userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found. Please log in again.')),
        );
        return;
      }

      setState(() {
        // Show loading state
      });
      final profilePicturePath = await AuthManager().uploadProfilePicture(
        userId,
        image.path,
      );
      setState(() {
        // Refresh UI to display new image
      });

      if (profilePicturePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile picture')),
        );
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilePicture = AuthManager().profilePicture;
    final fullName = AuthManager().firstName ?? 'Kyc Required.';
    final email = AuthManager().email ?? 'Unable To Fetch Email ID.';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
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
                      backgroundColor: const Color.fromARGB(255, 140, 143, 140),
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Edit Profile'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to edit profile screen
            },
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Payment Method'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to payment method screen
            },
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to language settings
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Order History'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to order history
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Invite Friends'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to invite friends
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help Center'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to help center
            },
          ),
        ],
      ),
    );
  }
}