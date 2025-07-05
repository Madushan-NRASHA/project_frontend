import 'package:flutter/material.dart';

class ViewProfile extends StatefulWidget {
  @override
  _ViewProfileState createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  late Map<String, dynamic> userArgs;
  bool isDarkTheme = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    isDarkTheme = (userArgs['user_theme'] ?? 0) == 1;
  }

  @override
  Widget build(BuildContext context) {
    final name = userArgs['name'] ?? 'Unknown';
    final email = userArgs['email'] ?? 'No email';
    final phone = userArgs['phone'] ?? 'No phone';
    final address = userArgs['address'] ?? 'No address';
    final profileImage = userArgs['profile_image'] ?? '';
    final joinDate = userArgs['join_date'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkTheme ? Colors.grey[800] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
            onPressed: () {
              // Navigate to edit profile page
              _editProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture Section
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkTheme ? Colors.white : Colors.grey[300]!,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: isDarkTheme ? Colors.grey[700] : Colors.grey[300],
                backgroundImage: profileImage.isNotEmpty
                    ? NetworkImage(profileImage)
                    : null,
                child: profileImage.isEmpty
                    ? Icon(
                  Icons.person,
                  size: 60,
                  color: isDarkTheme ? Colors.white : Colors.grey[600],
                )
                    : null,
              ),
            ),
            SizedBox(height: 20),

            // Name
            Text(
              name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8),

            // Email
            Text(
              email,
              style: TextStyle(
                fontSize: 16,
                color: isDarkTheme ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 30),

            // Profile Information Cards
            _buildInfoCard(
              icon: Icons.email,
              title: 'Email',
              value: email,
            ),
            SizedBox(height: 15),

            _buildInfoCard(
              icon: Icons.phone,
              title: 'Phone',
              value: phone,
            ),
            SizedBox(height: 15),

            _buildInfoCard(
              icon: Icons.location_on,
              title: 'Address',
              value: address,
            ),
            SizedBox(height: 15),

            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Member Since',
              value: joinDate,
            ),
            SizedBox(height: 30),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit Profile',
                  onPressed: _editProfile,
                ),
                _buildActionButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onPressed: _openSettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme ? Colors.black26 : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkTheme ? Colors.blue[800] : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDarkTheme ? Colors.blue[300] : Colors.blue[700],
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: isDarkTheme ? Colors.white : Colors.white,
        backgroundColor: isDarkTheme ? Colors.blue[700] : Colors.blue[600],
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _editProfile() {
    // Navigate to edit profile page
    Navigator.pushNamed(
      context,
      '/edit-profile',
      arguments: userArgs,
    );
  }

  void _openSettings() {
    // Navigate to settings page
    Navigator.pushNamed(
      context,
      '/settings',
      arguments: userArgs,
    );
  }
}