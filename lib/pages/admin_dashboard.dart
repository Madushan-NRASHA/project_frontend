import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late bool isDarkTheme;
  bool isUpdatingTheme = false;
  late Map<String, dynamic> userArgs;
  late String authToken;
  late int userId; // User ID එක clearly store කරන්න

  final String baseUrl = 'http://10.0.2.2:8000';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (routeArgs == null || routeArgs['token'] == null) {
      _showErrorSnackBar('Authentication required');
      Navigator.pop(context);
      return;
    }

    userArgs = routeArgs;
    authToken = userArgs['token'];
    userId = userArgs['id'] ?? 0; // User ID එක extract කරලා store කරන්න
    isDarkTheme = (userArgs['user_theme'] ?? 0) == 1;
  }

  Future<void> _updateThemeInBackend(int newTheme) async {
    if (userId == 0) {
      _showErrorSnackBar('User authentication required');
      return;
    }

    setState(() => isUpdatingTheme = true);

    try {
      final url = Uri.parse("$baseUrl/api/update-theme");
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode({
          'user_id': userId, // Direct user ID use කරන්න
          'user_theme': newTheme,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            userArgs['user_theme'] = newTheme;
            isDarkTheme = newTheme == 1;
          });
          _showSuccessSnackBar(newTheme == 1 ? 'Dark theme activated!' : 'Light theme activated!');
        }
      }
    } catch (e) {
      setState(() => isDarkTheme = !isDarkTheme);
      _showErrorSnackBar('Theme update failed: $e');
    } finally {
      setState(() => isUpdatingTheme = false);
    }
  }

  void _toggleTheme() {
    if (isUpdatingTheme) return;
    final newTheme = isDarkTheme ? 0 : 1;
    setState(() => isDarkTheme = !isDarkTheme);
    _updateThemeInBackend(newTheme);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToChangeProfilePicture() {
    Navigator.pushNamed(
      context,
      '/change-profile-picture',
      arguments: {
        ...userArgs,
        'user_id': userId, // Explicitly pass user ID
      },
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          userArgs = result;
        });
        _showSuccessSnackBar('Profile picture updated!');
      }
    });
  }

  void _navigateToViewProfile() {
    Navigator.pushNamed(
      context,
      '/view-profile',
      arguments: {
        'token': authToken,
        'user_id': userId, // Direct user ID pass කරන්න
        'id': userId, // Backward compatibility සඳහා
        'name': userArgs['name'],
        'email': userArgs['email'],
        'phone': userArgs['phone'] ?? '',
        'address': userArgs['address'] ?? '',
        'user_theme': userArgs['user_theme'] ?? 0,
        'profile_image': userArgs['profile_image'] ?? '',
        'user_type': userArgs['user_type'],
      },
    );
  }

  void _testConnection() async {
    try {
      final url = Uri.parse("$baseUrl/api/test");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Connection successful! User ID: $userId');
      } else {
        _showErrorSnackBar('Connection failed: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Connection error: $e');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Colors.white,
          title: Text(
            'Confirm Logout',
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: isDarkTheme ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final url = Uri.parse("$baseUrl/api/logout");
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode({
          'user_id': userId, // User ID සහ logout කරන්න
        }),
      ).timeout(Duration(seconds: 10));

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Logged out successfully!');
      } else {
        _showErrorSnackBar('Logout failed: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      _showErrorSnackBar('Logout error: $e');
    }

    // Clear userArgs and navigate to login screen
    setState(() {
      userArgs = {};
      authToken = '';
      userId = 0;
    });

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (Route<dynamic> route) => false,
    );
  }

  void showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkTheme ? Color(0xFF1a1a2e) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkTheme ? Colors.white30 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // User ID display කරන්න
              Container(
                padding: EdgeInsets.all(10),
                child: Text(
                  'User ID: $userId',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: isDarkTheme ? Colors.white : Colors.black87),
                title: Text('Change Profile Picture', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToChangeProfilePicture();
                },
              ),
              ListTile(
                leading: Icon(Icons.visibility, color: isDarkTheme ? Colors.white : Colors.black87),
                title: Text('View Profile', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToViewProfile();
                },
              ),
              ListTile(
                leading: Icon(Icons.bug_report, color: isDarkTheme ? Colors.white : Colors.black87),
                title: Text('Test Connection', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  _testConnection();
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = userArgs['name'] ?? 'Unknown';
    final profilePic = userArgs['profile_image'] ?? '';

    return Theme(
      data: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkTheme
                  ? [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)]
                  : [Color(0xFFf8f9ff), Color(0xFFe8f2ff), Color(0xFFd6e9ff)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App Bar with Logout Button
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Admin Dashboard",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                            ),
                          ),
                          Text(
                            "User ID: $userId", // User ID display කරන්න
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkTheme ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Switch(
                            value: isDarkTheme,
                            onChanged: isUpdatingTheme ? null : (_) => _toggleTheme(),
                            activeColor: Colors.blue,
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(
                              Icons.logout,
                              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                            ),
                            onPressed: () => _showLogoutDialog(),
                            tooltip: 'Logout',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Profile Card with Options
                GestureDetector(
                  onTap: showProfileOptions,
                  child: Card(
                    margin: EdgeInsets.all(20),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : null,
                            child: profilePic.isEmpty
                                ? Icon(Icons.person, size: 40)
                                : null,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Welcome Admin",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(name),
                          SizedBox(height: 16),
                          Chip(
                            label: Text(isDarkTheme ? "Dark Theme" : "Light Theme"),
                            avatar: Icon(isDarkTheme ? Icons.nightlight_round : Icons.wb_sunny),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Grid of Navigation Cards
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      crossAxisCount: 2, // 2 cards per row
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2, // Adjust for card proportions
                      children: [
                        _buildNavCard(
                          context,
                          icon: Icons.people,
                          title: 'Users',
                          route: '/users',
                        ),
                        _buildNavCard(
                          context,
                          icon: Icons.work,
                          title: 'Jobs',
                          route: '/jobs',
                        ),
                        _buildNavCard(
                          context,
                          icon: Icons.assessment,
                          title: 'Reports',
                          route: '/reports',
                        ),
                        _buildNavCard(
                          context,
                          icon: Icons.event,
                          title: 'Activities',
                          route: '/activities',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build navigation cards with user ID
  Widget _buildNavCard(BuildContext context, {required IconData icon, required String title, required String route}) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          route,
          arguments: {
            ...userArgs, // Original userArgs
            'user_id': userId, // Explicitly pass user ID
            'current_user_id': userId, // Alternative key name
            'admin_id': userId, // Admin specific ID
          },
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
              ),
            ),
            // Debug info - remove in production
            if (userId > 0)
              Text(
                'ID: $userId',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkTheme ? Colors.white54 : Colors.black38,
                ),
              ),
          ],
        ),
      ),
    );
  }
}