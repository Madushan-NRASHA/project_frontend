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
  bool isLoadingStats = false;
  late Map<String, dynamic> userArgs;
  late String authToken;

  // Dashboard statistics with default values
  Map<String, dynamic> dashboardStats = {
    'total_users': 0,
    'activities': 0,
    'reports': 0,
    'settings': 0,
  };

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
    isDarkTheme = (userArgs['user_theme'] ?? 0) == 1;

    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => isLoadingStats = true);

    try {
      final url = Uri.parse("$baseUrl/api/dashboard-stats");
      print("Fetching dashboard stats from: $url"); // Debug log

      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 30));

      print("Response status: ${response.statusCode}"); // Debug log
      print("Response body: ${response.body}"); // Debug log

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['stats'] != null) {
          setState(() {
            dashboardStats = {
              'total_users': responseData['stats']['total_users'] ?? 0,
              'activities': responseData['stats']['activities'] ?? 0,
              'reports': responseData['stats']['reports'] ?? 0,
              'settings': responseData['stats']['settings'] ?? 0,
            };
          });
          print("Stats updated successfully: $dashboardStats"); // Debug log
        } else {
          // API returned success=false or no stats
          print("API returned success=false or no stats");
          _setFallbackStats();
        }
      } else if (response.statusCode == 401) {
        _showErrorSnackBar('Session expired. Please login again.');
        Navigator.pop(context);
      } else {
        // Other HTTP errors
        print("HTTP error: ${response.statusCode}");
        _setFallbackStats();
        _showErrorSnackBar('Failed to load statistics. Using sample data.');
      }
    } catch (e) {
      print("Exception loading stats: $e"); // Debug log
      _setFallbackStats();
      _showErrorSnackBar('Network error. Using sample data.');
    } finally {
      setState(() => isLoadingStats = false);
    }
  }

  void _setFallbackStats() {
    setState(() {
      dashboardStats = {
        'total_users': 156,
        'activities': 234,
        'reports': 12,
        'settings': 8,
      };
    });
  }

  Future<void> _updateThemeInBackend(int newTheme) async {
    if (userArgs['id'] == null) {
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
          'user_id': userArgs['id'],
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

  // Navigation methods for each stat card
  void _navigateToUsers() {
    Navigator.pushNamed(
      context,
      '/userDisp',
      arguments: userArgs,
    );
  }

  void _navigateToJobs() {
    Navigator.pushNamed(
      context,
      '/jobsDisp',
      arguments: userArgs,
    );
  }

  void _navigateToReports() {
    Navigator.pushNamed(
      context,
      '/reportDisp',
      arguments: userArgs,
    );
  }

  void _navigateToReviews() {
    Navigator.pushNamed(
      context,
      '/reviewDisp',
      arguments: userArgs,
    );
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
              ListTile(
                leading: Icon(
                  Icons.photo_camera,
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                title: Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToChangeProfilePicture();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.visibility,
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                title: Text(
                  'View Profile',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToViewProfile();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                title: Text(
                  'Refresh Statistics',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _loadDashboardStats();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.bug_report,
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                title: Text(
                  'Test Connection',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
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

  Future<void> _testConnection() async {
    try {
      final url = Uri.parse("$baseUrl/api/test");
      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Connection successful!');
      } else {
        _showErrorSnackBar('Connection failed: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Connection error: $e');
    }
  }

  void _navigateToChangeProfilePicture() {
    Navigator.pushNamed(
      context,
      '/change-profile-picture',
      arguments: userArgs,
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
      arguments: userArgs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = userArgs['name'] ?? 'Unknown';
    final profilePic = userArgs['Profile_Pic'] ?? '';

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
                // App Bar
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Admin Dashboard",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: isLoadingStats
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDarkTheme ? Colors.white : Colors.blue,
                                ),
                              ),
                            )
                                : Icon(
                              Icons.refresh,
                              color: isDarkTheme ? Colors.white : Colors.black87,
                            ),
                            onPressed: isLoadingStats ? null : _loadDashboardStats,
                          ),
                          Switch(
                            value: isDarkTheme,
                            onChanged: isUpdatingTheme ? null : (_) => _toggleTheme(),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Profile Card with Popup Menu
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
                                fontWeight: FontWeight.bold
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

                // Stats Grid
                Expanded(
                  child: GridView.count(
                    padding: EdgeInsets.all(20),
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _buildStatCard("Users", dashboardStats['total_users'], Icons.people, Colors.green, _navigateToUsers),
                      _buildStatCard("Jobs", dashboardStats['activities'], Icons.work, Colors.orange, _navigateToJobs),
                      _buildStatCard("Reports", dashboardStats['reports'], Icons.report, Colors.red, _navigateToReports),
                      _buildStatCard("Reviews", dashboardStats['settings'], Icons.star, Colors.blue, _navigateToReviews),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}