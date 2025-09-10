import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Map<String, dynamic> userArgs;
  late String authToken;
  late bool isDarkTheme;
  final String baseUrl = 'http://10.0.2.2:8000';
  Map<String, dynamic>? currentUser;
  bool isLoading = false;
  String? errorMessage;

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
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final url = Uri.parse("$baseUrl/api/users/${userArgs['user_id']}");
      print("Fetching user profile from: $url at ${DateTime.now()}");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));
      print("Fetch status: ${response.statusCode}");
      print("Fetch body: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          currentUser = responseData['data'] ?? responseData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load profile: ${response.statusCode}';
          isLoading = false;
        });
        _showErrorSnackBar(errorMessage!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching profile: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  Future<void> _updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/${userArgs['user_id']}");
      print("Updating user profile at: $url");
      print("User data: $userData");
      final response = await http.put(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode(userData),
      ).timeout(Duration(seconds: 10));
      print("Update status: ${response.statusCode}");
      print("Update body: ${response.body}");
      if (response.statusCode == 200) {
        _showSuccessSnackBar('Profile updated successfully');
        await _fetchUserProfile();
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to update profile: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating profile: $e');
    }
  }

  void _showUserDetails() {
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.person,
              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Profile Details',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', currentUser!['name'], Icons.person),
              SizedBox(height: 16),
              _buildDetailRow('Email', currentUser!['email'], Icons.email),
              SizedBox(height: 16),
              _buildUserTypeRow(),
              SizedBox(height: 16),
              Text(
                'User ID: ${currentUser!['id']}',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              if (currentUser!['created_at'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Member since: ${currentUser!['created_at']}',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
              if (currentUser!['updated_at'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Last updated: ${currentUser!['updated_at']}',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditProfileForm();
            },
            icon: Icon(Icons.edit, size: 16, color: Colors.blue),
            label: Text(
              'Edit Profile',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDarkTheme ? Colors.white60 : Colors.black54,
            ),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                value ?? 'Not provided',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeRow() {
    final userType = currentUser!['user_type'] ?? 'user';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: userType == 'admin'
                ? (isDarkTheme ? Color(0xFF2e1a1a) : Color(0xFFffebee))
                : (isDarkTheme ? Color(0xFF1a2e1a) : Color(0xFFe8f5e8)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: userType == 'admin'
                  ? (isDarkTheme ? Colors.red[300]! : Colors.red)
                  : (isDarkTheme ? Colors.green[300]! : Colors.green),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                userType == 'admin' ? Icons.admin_panel_settings : Icons.person,
                size: 16,
                color: userType == 'admin'
                    ? (isDarkTheme ? Colors.red[300] : Colors.red[700])
                    : (isDarkTheme ? Colors.green[300] : Colors.green[700]),
              ),
              SizedBox(width: 4),
              Text(
                userType.toString().toUpperCase(),
                style: TextStyle(
                  color: userType == 'admin'
                      ? (isDarkTheme ? Colors.red[300] : Colors.red[700])
                      : (isDarkTheme ? Colors.green[300] : Colors.green[700]),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditProfileForm() {
    if (currentUser == null) return;

    final nameController = TextEditingController(text: currentUser!['name'] ?? '');
    final emailController = TextEditingController(text: currentUser!['email'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(
                    Icons.person,
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white70 : Colors.blue,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(
                    Icons.email,
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white70 : Colors.blue,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFf0f4f8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkTheme ? Colors.orange[300]! : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: isDarkTheme ? Colors.orange[300] : Colors.orange[700],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'User type cannot be changed. Contact admin if needed.',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.orange[300] : Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                final userData = {
                  'name': nameController.text,
                  'email': emailController.text,
                  'user_type': currentUser!['user_type'], // Keep existing user type
                };
                await _updateUserProfile(userData);
                Navigator.pop(context);
              } else {
                _showErrorSnackBar('Please fill all required fields (*)');
              }
            },
            child: Text(
              'Update Profile',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
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
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Profile'),
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
          actions: [
            if (currentUser != null)
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showEditProfileForm(),
              ),
          ],
        ),
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
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  errorMessage!,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchUserProfile,
                  child: Text('Retry'),
                ),
              ],
            ),
          )
              : currentUser == null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Profile not found',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchUserProfile,
                  child: Text('Reload'),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _fetchUserProfile,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Profile Avatar
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: isDarkTheme ? Colors.white70 : Color(0xFF2d3748),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Name
                          Text(
                            currentUser!['name'] ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                            ),
                          ),
                          SizedBox(height: 8),
                          // Email
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email,
                                size: 16,
                                color: isDarkTheme ? Colors.white60 : Colors.black54,
                              ),
                              SizedBox(width: 4),
                              Text(
                                currentUser!['email'] ?? 'No email',
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // User Type Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: (currentUser!['user_type'] ?? 'user') == 'admin'
                                  ? (isDarkTheme ? Color(0xFF2e1a1a) : Color(0xFFffebee))
                                  : (isDarkTheme ? Color(0xFF1a2e1a) : Color(0xFFe8f5e8)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (currentUser!['user_type'] ?? 'user') == 'admin'
                                    ? (isDarkTheme ? Colors.red[300]! : Colors.red)
                                    : (isDarkTheme ? Colors.green[300]! : Colors.green),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (currentUser!['user_type'] ?? 'user') == 'admin'
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                  size: 16,
                                  color: (currentUser!['user_type'] ?? 'user') == 'admin'
                                      ? (isDarkTheme ? Colors.red[300] : Colors.red[700])
                                      : (isDarkTheme ? Colors.green[300] : Colors.green[700]),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  (currentUser!['user_type'] ?? 'user').toString().toUpperCase(),
                                  style: TextStyle(
                                    color: (currentUser!['user_type'] ?? 'user') == 'admin'
                                        ? (isDarkTheme ? Colors.red[300] : Colors.red[700])
                                        : (isDarkTheme ? Colors.green[300] : Colors.green[700]),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showUserDetails,
                                  icon: Icon(Icons.info_outline),
                                  label: Text('View Details'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
                                    foregroundColor: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showEditProfileForm,
                                  icon: Icon(Icons.edit),
                                  label: Text('Edit Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Profile Information Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildInfoTile(
                            'User ID',
                            currentUser!['id'].toString(),
                            Icons.badge,
                          ),
                          if (currentUser!['created_at'] != null)
                            _buildInfoTile(
                              'Member Since',
                              currentUser!['created_at'],
                              Icons.calendar_today,
                            ),
                          if (currentUser!['updated_at'] != null)
                            _buildInfoTile(
                              'Last Updated',
                              currentUser!['updated_at'],
                              Icons.update,
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
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDarkTheme ? Colors.white60 : Colors.black54,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkTheme ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}