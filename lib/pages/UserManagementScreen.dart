import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Map<String, dynamic> userArgs;
  late String authToken;
  late bool isDarkTheme;
  final String baseUrl = 'http://10.0.2.2:8000';
  List<dynamic> users = [];
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
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final url = Uri.parse("$baseUrl/api/users");
      print("Fetching users from: $url at ${DateTime.now()}");
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
          users = responseData is List ? responseData : responseData['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load users: ${response.statusCode}';
          isLoading = false;
        });
        _showErrorSnackBar(errorMessage!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching users: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  Future<void> _updateUserType(int userId, String userType) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/$userId/user-type");
      print("Updating user type at: $url");
      print("User type: $userType");
      final response = await http.put(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode({'user_type': userType}),
      ).timeout(Duration(seconds: 10));
      print("Update status: ${response.statusCode}");
      print("Update body: ${response.body}");
      if (response.statusCode == 200) {
        _showSuccessSnackBar('User type updated successfully');
        await _fetchUsers();
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to update user type: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating user type: $e');
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/$userId");
      print("Deleting user at: $url at ${DateTime.now()}");
      print("User ID: $userId");
      print("Token: $authToken");
      final response = await http.delete(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));
      print("Delete status: ${response.statusCode}");
      print("Delete body: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _showSuccessSnackBar(responseData['message'] ?? 'User deleted successfully');
        await _fetchUsers();
      } else if (response.statusCode == 404) {
        _showErrorSnackBar('User not found');
      } else if (response.statusCode == 500) {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Server error: ${errorData['message'] ?? 'Unknown error'}');
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to delete user: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print("Delete error: $e");
      _showErrorSnackBar('Error deleting user: $e');
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
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
                user['name'] ?? 'Unknown User',
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
              if (user['email'] != null && user['email'].isNotEmpty) ...[
                Text(
                  'Email:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user['email'],
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
              ],
              if (user['user_type'] != null && user['user_type'].isNotEmpty) ...[
                Text(
                  'User Type:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: user['user_type'] == 'admin'
                        ? (isDarkTheme ? Color(0xFF2d1b69) : Color(0xFFe8f2ff))
                        : (isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f8f5)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user['user_type'] == 'admin'
                          ? (isDarkTheme ? Colors.purple[300]! : Colors.purple)
                          : (isDarkTheme ? Colors.green[300]! : Colors.green),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    user['user_type'].toString().toUpperCase(),
                    style: TextStyle(
                      color: user['user_type'] == 'admin'
                          ? (isDarkTheme ? Colors.purple[300] : Colors.purple[700])
                          : (isDarkTheme ? Colors.green[300] : Colors.green[700]),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
              if (user['user_theme'] != null) ...[
                Text(
                  'Theme Preference:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      user['user_theme'] == 1 ? Icons.dark_mode : Icons.light_mode,
                      size: 16,
                      color: isDarkTheme ? Colors.white60 : Colors.black54,
                    ),
                    SizedBox(width: 4),
                    Text(
                      user['user_theme'] == 1 ? 'Dark' : 'Light',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
              Text(
                'User ID: ${user['id']}',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              if (user['created_at'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Created: ${user['created_at']}',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
              if (user['updated_at'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Updated: ${user['updated_at']}',
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
              _showUserTypeDialog(user);
            },
            icon: Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue),
            label: Text(
              'Change Type',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          if (user['id'] != userArgs['user_id']) // Prevent self-deletion
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(user);
              },
              icon: Icon(Icons.delete, size: 16, color: Colors.red),
              label: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  void _showUserTypeDialog(Map<String, dynamic> user) {
    String selectedUserType = user['user_type'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
          title: Text(
            'Change User Type',
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change user type for "${user['name']}"',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              RadioListTile<String>(
                title: Text(
                  'User',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  'Regular user with standard permissions',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                value: 'user',
                groupValue: selectedUserType,
                onChanged: (value) {
                  setState(() {
                    selectedUserType = value!;
                  });
                },
                activeColor: Colors.green,
              ),
              RadioListTile<String>(
                title: Text(
                  'Admin',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  'Administrator with full permissions',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                value: 'admin',
                groupValue: selectedUserType,
                onChanged: (value) {
                  setState(() {
                    selectedUserType = value!;
                  });
                },
                activeColor: Colors.purple,
              ),
            ],
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
                if (selectedUserType != user['user_type']) {
                  await _updateUserType(user['id'], selectedUserType);
                }
                Navigator.pop(context);
              },
              child: Text(
                'Update',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Text(
          'Delete User',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
          ),
        ),
        content: Text(
          'Are you sure you want to delete user "${user['name']}"?\n\nThis action cannot be undone and will permanently remove the user and all associated data.',
          style: TextStyle(
            color: isDarkTheme ? Colors.white70 : Colors.black87,
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
              await _deleteUser(user['id']);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
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
          title: Text('User Management'),
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchUsers,
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
                  onPressed: _fetchUsers,
                  child: Text('Retry'),
                ),
              ],
            ),
          )
              : users.isEmpty
              ? Center(
            child: Text(
              'No users found',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          )
              : RefreshIndicator(
            onRefresh: _fetchUsers,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isCurrentUser = user['id'] == userArgs['user_id'];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                  child: ListTile(
                    onTap: () => _showUserDetails(user),
                    leading: CircleAvatar(
                      backgroundColor: user['user_type'] == 'admin'
                          ? (isDarkTheme ? Colors.purple[300] : Colors.purple)
                          : (isDarkTheme ? Colors.green[300] : Colors.green),
                      child: Icon(
                        user['user_type'] == 'admin' ? Icons.admin_panel_settings : Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['name'] ?? 'Unknown User',
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDarkTheme ? Colors.blue[800] : Colors.blue[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'YOU',
                              style: TextStyle(
                                color: isDarkTheme ? Colors.blue[300] : Colors.blue[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user['email'] != null)
                          Text(
                            user['email'],
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: user['user_type'] == 'admin'
                                    ? (isDarkTheme ? Color(0xFF2d1b69) : Color(0xFFe8f2ff))
                                    : (isDarkTheme ? Color(0xFF1a2e1a) : Color(0xFFe8f8f5)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: user['user_type'] == 'admin'
                                      ? (isDarkTheme ? Colors.purple[300]! : Colors.purple)
                                      : (isDarkTheme ? Colors.green[300]! : Colors.green),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                (user['user_type'] ?? 'user').toString().toUpperCase(),
                                style: TextStyle(
                                  color: user['user_type'] == 'admin'
                                      ? (isDarkTheme ? Colors.purple[300] : Colors.purple[700])
                                      : (isDarkTheme ? Colors.green[300] : Colors.green[700]),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              user['user_theme'] == 1 ? Icons.dark_mode : Icons.light_mode,
                              size: 14,
                              color: isDarkTheme ? Colors.white60 : Colors.black45,
                            ),
                            SizedBox(width: 4),
                            Text(
                              user['user_theme'] == 1 ? 'Dark' : 'Light',
                              style: TextStyle(
                                color: isDarkTheme ? Colors.white60 : Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to view details',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.blue[300] : Colors.blue,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'details') {
                          _showUserDetails(user);
                        } else if (value == 'change_type') {
                          _showUserTypeDialog(user);
                        } else if (value == 'delete') {
                          if (isCurrentUser) {
                            _showErrorSnackBar('You cannot delete yourself');
                          } else {
                            _showDeleteConfirmation(user);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'change_type',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings, size: 16),
                              SizedBox(width: 8),
                              Text('Change Type'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          enabled: !isCurrentUser,
                          child: Row(
                            children: [
                              Icon(
                                  Icons.delete,
                                  size: 16,
                                  color: isCurrentUser
                                      ? (isDarkTheme ? Colors.grey[600] : Colors.grey[400])
                                      : Colors.red
                              ),
                              SizedBox(width: 8),
                              Text(
                                  'Delete',
                                  style: TextStyle(
                                      color: isCurrentUser
                                          ? (isDarkTheme ? Colors.grey[600] : Colors.grey[400])
                                          : Colors.red
                                  )
                              ),
                            ],
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
      ),
    );
  }
}