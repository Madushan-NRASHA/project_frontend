import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late bool isDarkTheme;
  bool isUpdatingTheme = false;
  late Map<String, dynamic> userArgs;
  late String authToken;
  late int userId;

  final String baseUrl = 'http://10.0.2.2:8000';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArgs =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (routeArgs == null || routeArgs['token'] == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar('Authentication required');
        Navigator.pop(context);
      });
      return;
    }

    userArgs = routeArgs;
    authToken = userArgs['token'];
    userId = userArgs['id'] ?? 0;
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
      final response = await http
          .post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode({
          'user_id': userId,
          'user_theme': newTheme,
        }),
      )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            userArgs['user_theme'] = newTheme;
            isDarkTheme = newTheme == 1;
          });
          _showSuccessSnackBar(
              newTheme == 1 ? 'Dark theme activated!' : 'Light theme activated!');
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  void _showSuccessSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _navigateToChangeProfilePicture() {
    Navigator.pushNamed(
      context,
      '/change-profile-picture',
      arguments: {...userArgs, 'user_id': userId},
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() => userArgs = result);
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
        'user_id': userId,
        'id': userId,
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
            style:
            TextStyle(color: isDarkTheme ? Colors.white : Colors.black87),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final url = Uri.parse("$baseUrl/api/logout");
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode({'user_id': userId}),
      ).timeout(Duration(seconds: 10));

      Navigator.pop(context);

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Logged out successfully!');
      } else {
        _showErrorSnackBar('Logout failed: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Logout error: $e');
    }

    setState(() {
      userArgs = {};
      authToken = '';
      userId = 0;
    });

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? (isDarkTheme ? Colors.white : Color(0xFF2d3748)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color ?? (isDarkTheme ? Colors.white : Color(0xFF2d3748)),
        ),
      ),
      onTap: onTap,
      tileColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDarkTheme ? Colors.white70 : Colors.black54,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = userArgs['name'] ?? 'Unknown';

    return Theme(
      data: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Users'),
          backgroundColor:
          isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
          iconTheme: IconThemeData(
              color: isDarkTheme ? Colors.white : Color(0xFF2d3748)),
          elevation: 0,
        ),
        drawer: Drawer(
          child: Container(
            color: isDarkTheme ? Color(0xFF1a1a2e) : Colors.white,
            child: Column(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkTheme
                          ? [Color(0xFF1a1a2e), Color(0xFF16213e)]
                          : [Color(0xFFe8f2ff), Color(0xFFd6e9ff)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          child: Icon(Icons.person,
                              size: 35,
                              color: isDarkTheme
                                  ? Colors.white
                                  : Colors.black54),
                        ),
                        SizedBox(height: 12),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                            isDarkTheme ? Colors.white : Color(0xFF2d3748),
                          ),
                        ),
                        Text(
                          'User ID: $userId',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkTheme
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        icon: Icons.work,
                        title: 'Jobs',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/jobs', arguments: {
                            ...userArgs,
                            'user_id': userId,
                            'current_user_id': userId,
                            'admin_id': userId,
                          });
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.search,
                        title: 'Find Jobs',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/find-jobs',
                              arguments: {
                                ...userArgs,
                                'user_id': userId,
                                'current_user_id': userId,
                                'admin_id': userId,
                              });
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.person,
                        title: 'View Profile',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToViewProfile();
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.photo_camera,
                        title: 'Change Profile Picture',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToChangeProfilePicture();
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.bug_report,
                        title: 'Test Connection',
                        onTap: () {
                          Navigator.pop(context);
                          _testConnection();
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: isDarkTheme ? Colors.white24 : Colors.black12),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkTheme
                  ? [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)]
                  : [Color(0xFFf8f9ff), Color(0xFFe8f2ff), Color(0xFFd6e9ff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Top controls section
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDarkTheme
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkTheme
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Theme toggle section
                        Row(
                          children: [
                            Icon(
                              isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              isDarkTheme ? 'Dark' : 'Light',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                              ),
                            ),
                            SizedBox(width: 8),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: isDarkTheme,
                                onChanged: isUpdatingTheme ? null : (_) => _toggleTheme(),
                                activeColor: Colors.blue,
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),

                        // Logout button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: _showLogoutDialog,
                            tooltip: 'Logout',
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Spacer to fill remaining space
                  Expanded(child: Container()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}