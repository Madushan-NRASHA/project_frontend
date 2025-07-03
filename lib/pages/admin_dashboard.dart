import 'package:flutter/material.dart';

class Admin_dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Use the correct field names from your API response
    final name = args['name'] ?? 'Unknown';
    final theme = args['user_theme'] ?? 0;  // Changed from 'theme' to 'user_theme'
    final profilePic = args['Profile_Pic'] ?? '';  // Changed from 'profilePic' to 'Profile_Pic'

    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome Admin $name'),
            Text('Theme: $theme'),
            // Add null/empty check for profile picture
            profilePic.isNotEmpty
                ? Image.network(profilePic)
                : Icon(Icons.person, size: 100), // Show default icon if no profile pic
          ],
        ),
      ),
    );
  }
}