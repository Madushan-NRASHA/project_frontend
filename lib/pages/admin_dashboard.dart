import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Admin_dashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<Admin_dashboard> with TickerProviderStateMixin {
  late bool isDarkTheme;
  late AnimationController _profileAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _profileScaleAnimation;
  late Animation<double> _cardSlideAnimation;
  bool isProfileHovered = false;
  bool isUpdatingTheme = false;
  late Map<String, dynamic> userArgs;

  @override
  void initState() {
    super.initState();

    // Animation controllers
    _profileAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Animations
    _profileScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _profileAnimationController,
      curve: Curves.easeInOut,
    ));

    _cardSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    // Start card animation
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _profileAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _updateThemeInBackend(int newTheme) async {
    setState(() {
      isUpdatingTheme = true;
    });

    try {
      final url = Uri.parse("http://10.0.2.2:8000/api/update-theme"); // Your Laravel API endpoint
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: json.encode({
          'user_id': userArgs['id'], // Assuming user has ID field
          'user_theme': newTheme,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Update local user data
        setState(() {
          userArgs['user_theme'] = newTheme;
          isDarkTheme = newTheme == 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newTheme == 1 ? 'අඳුරු තේමාව සක්‍රිය කරන ලදී!' : 'සුදු තේමාව සක්‍රිය කරන ලදී!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('තේමාව වෙනස් කිරීමේ දෝෂයක්!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('දෝෂයක්: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isUpdatingTheme = false;
      });
    }
  }

  void _toggleTheme() {
    if (isUpdatingTheme) return; // Prevent multiple clicks during update

    final newTheme = isDarkTheme ? 0 : 1;
    _updateThemeInBackend(newTheme);
  }

  // Show profile options bottom sheet
  void _showProfileOptions() {
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
                  'ප්‍රොෆයිල් පින්තූරය වෙනස් කරන්න',
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
                  'ප්‍රොෆයිල් බලන්න',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToViewProfile();
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Navigate to Change Profile Picture Page
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ප්‍රොෆයිල් පින්තූරය යාවත්කාලීන කරන ලදී!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Navigate to View Profile Page
  void _navigateToViewProfile() {
    Navigator.pushNamed(
      context,
      '/view-profile',
      arguments: userArgs,
    );
  }

  @override
  Widget build(BuildContext context) {
    userArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final name = userArgs['name'] ?? 'Unknown';
    final theme = userArgs['user_theme'] ?? 0;
    final profilePic = userArgs['Profile_Pic'] ?? '';

    // Initialize theme based on user preference
    if (!isUpdatingTheme) {
      isDarkTheme = theme == 1;
    }

    return Theme(
      data: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkTheme
                  ? [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
              ]
                  : [
                Color(0xFFf8f9ff),
                Color(0xFFe8f2ff),
                Color(0xFFd6e9ff),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Container(
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
                      // Theme Toggle Button
                      GestureDetector(
                        onTap: _toggleTheme,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: 60,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isDarkTheme ? Colors.blue : Colors.orange,
                            boxShadow: [
                              BoxShadow(
                                color: (isDarkTheme ? Colors.blue : Colors.orange).withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: Duration(milliseconds: 300),
                                left: isDarkTheme ? 30 : 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: isUpdatingTheme
                                      ? Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDarkTheme ? Colors.blue : Colors.orange,
                                    ),
                                  )
                                      : Icon(
                                    isDarkTheme ? Icons.nightlight_round : Icons.wb_sunny,
                                    color: isDarkTheme ? Colors.blue : Colors.orange,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Profile Card
                        AnimatedBuilder(
                          animation: _cardSlideAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - _cardSlideAnimation.value)),
                              child: Opacity(
                                opacity: _cardSlideAnimation.value,
                                child: Container(
                                  padding: EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    color: isDarkTheme
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDarkTheme
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.1),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDarkTheme
                                            ? Colors.black.withOpacity(0.3)
                                            : Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Profile Picture with Animation
                                      MouseRegion(
                                        onEnter: (_) {
                                          setState(() {
                                            isProfileHovered = true;
                                          });
                                          _profileAnimationController.forward();
                                        },
                                        onExit: (_) {
                                          setState(() {
                                            isProfileHovered = false;
                                          });
                                          _profileAnimationController.reverse();
                                        },
                                        child: GestureDetector(
                                          onTap: _showProfileOptions,
                                          child: AnimatedBuilder(
                                            animation: _profileScaleAnimation,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: _profileScaleAnimation.value,
                                                child: Container(
                                                  width: 120,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: isDarkTheme
                                                            ? Colors.blue.withOpacity(0.5)
                                                            : Colors.blue.withOpacity(0.3),
                                                        blurRadius: isProfileHovered ? 20 : 10,
                                                        offset: Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      ClipOval(
                                                        child: profilePic.isNotEmpty
                                                            ? Image.network(
                                                          profilePic,
                                                          width: 120,
                                                          height: 120,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              width: 120,
                                                              height: 120,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                gradient: LinearGradient(
                                                                  colors: [Colors.blue, Colors.purple],
                                                                ),
                                                              ),
                                                              child: Icon(
                                                                Icons.person,
                                                                size: 60,
                                                                color: Colors.white,
                                                              ),
                                                            );
                                                          },
                                                        )
                                                            : Container(
                                                          width: 120,
                                                          height: 120,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            gradient: LinearGradient(
                                                              colors: [Colors.blue, Colors.purple],
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            Icons.person,
                                                            size: 60,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      // Edit overlay icon
                                                      if (isProfileHovered)
                                                        Positioned.fill(
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: Colors.black.withOpacity(0.5),
                                                            ),
                                                            child: Icon(
                                                              Icons.edit,
                                                              color: Colors.white,
                                                              size: 30,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: 20),

                                      // Welcome Text
                                      Text(
                                        "ආයුබෝවන් Admin",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                                        ),
                                      ),

                                      SizedBox(height: 8),

                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkTheme ? Colors.blue[300] : Colors.blue[600],
                                        ),
                                      ),

                                      SizedBox(height: 20),

                                      // Theme Status
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isDarkTheme
                                              ? Colors.blue.withOpacity(0.2)
                                              : Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(25),
                                          border: Border.all(
                                            color: isDarkTheme ? Colors.blue : Colors.blue[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isDarkTheme ? Icons.nightlight_round : Icons.wb_sunny,
                                              color: isDarkTheme ? Colors.blue[300] : Colors.blue[600],
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              isDarkTheme ? "අඳුරු තේමාව" : "සුදු තේමාව",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: isDarkTheme ? Colors.blue[300] : Colors.blue[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 30),

                        // Admin Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "පරිශීලකයින්",
                                "1,234",
                                Icons.people,
                                Colors.green,
                                isDarkTheme,
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                "ක්‍රියාකාරකම්",
                                "5,678",
                                Icons.analytics,
                                Colors.orange,
                                isDarkTheme,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "වාර්තා",
                                "234",
                                Icons.report,
                                Colors.red,
                                isDarkTheme,
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                "සැකසීම්",
                                "12",
                                Icons.settings,
                                Colors.blue,
                                isDarkTheme,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 30),

                        // Quick Actions
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDarkTheme
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isDarkTheme
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ඉක්මන් ක්‍රියා",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                "Admin dashboard හි ප්‍රධාන කාර්යයන් සඳහා ඉක්මන් ප්‍රවේශය",
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: color,
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF2d3748),
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}