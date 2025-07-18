import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Map<String, dynamic> userArgs;
  late String authToken;
  late bool isDarkTheme;
  final String baseUrl = 'http://10.0.2.2:8000';
  List<dynamic> users = [];
  bool isLoading = false;
  String? errorMessage;
  TextEditingController searchController = TextEditingController();
  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = true;

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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Fetch all users
  Future<void> _fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("$baseUrl/api/users");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            users = responseData['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to load users';
            isLoading = false;
          });
          _showErrorSnackBar(errorMessage!);
        }
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

  // Fetch paginated users
  Future<void> _fetchPaginatedUsers(int page) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("$baseUrl/api/users/paginated?page=$page&per_page=10");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            if (page == 1) {
              users = responseData['data'] ?? [];
            } else {
              users.addAll(responseData['data'] ?? []);
            }
            currentPage = responseData['pagination']['current_page'];
            totalPages = responseData['pagination']['last_page'];
            hasMore = currentPage < totalPages;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to load users';
            isLoading = false;
          });
          _showErrorSnackBar(errorMessage!);
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching users: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  // Search users
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _fetchUsers();
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("$baseUrl/api/users/search?query=${Uri.encodeComponent(query)}");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            users = responseData['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Search failed';
            isLoading = false;
          });
          _showErrorSnackBar(errorMessage!);
        }
      } else {
        setState(() {
          errorMessage = 'Search failed: ${response.statusCode}';
          isLoading = false;
        });
        _showErrorSnackBar(errorMessage!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error searching users: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  // Create user
  Future<void> _createUser(String name, String email, String password, String userType) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("$baseUrl/api/users");
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'user_type': userType,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            users.add(responseData['data']);
            isLoading = false;
          });
          _showSuccessSnackBar('User created successfully');
          _fetchUsers(); // Refresh the list
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to create user';
            isLoading = false;
          });
          _showErrorSnackBar(errorMessage!);
        }
      } else {
        setState(() {
          errorMessage = 'Failed to create user: ${response.statusCode}';
          isLoading = false;
        });
        _showErrorSnackBar(errorMessage!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error creating user: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  // Update user
  Future<void> _updateUser(int userId, String name, String email, String userType) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("$baseUrl/api/users/$userId");
      final response = await http.put(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: json.encode({
          'name': name,
          'email': email,
          'user_type': userType,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            final index = users.indexWhere((user) => user['id'] == userId);
            if (index != -1) {
              users[index] = responseData['data'];
            }
            isLoading = false;
          });
          _showSuccessSnackBar('User updated successfully');
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to update user';
            isLoading = false;
          });
          _showErrorSnackBar(errorMessage!);
        }
      } else {
        setState(() {
          errorMessage = 'Failed to update user: ${response.statusCode}';
          isLoading = false;
        });
        _showErrorSnackBar(errorMessage!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error updating user: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  // Update user type
  Future<void> _updateUserType(int userId, String userType) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("$baseUrl/api/users/$userId/user-type");
      final response = await http.put(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: json.encode({
          'user_type': userType,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            final index = users.indexWhere((user) => user['id'] == userId);
            if (index != -1) {
              users[index] = responseData['data'];
            }
            isLoading = false;
          });
          _showSuccessSnackBar('User type updated successfully');
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to update user type';
            isLoading = false;
          });
          _showErrorSnackBar(errorMessage!);
        }
      } else {
        setState(() {
          errorMessage = 'Failed to update user type: ${response.statusCode}';
          isLoading = false;
        });
        _showErrorSnackBar(errorMessage!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error updating user type: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  // Delete user
  Future<void> _deleteUser(int userId) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/$userId");
      final response = await http.delete(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            users.removeWhere((user) => user['id'] == userId);
          });
          _showSuccessSnackBar('User deleted successfully');
        } else {
          _showErrorSnackBar(responseData['message'] ?? 'Failed to delete user');
        }
      } else {
        _showErrorSnackBar('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting user: $e');
    }
  }

  // Get user count
  Future<void> _getUserCount() async {
    try {
      final url = Uri.parse("$baseUrl/api/users/count");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showSuccessSnackBar('Total users: ${responseData['count']}');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error getting user count: $e');
    }
  }

  // Show user details dialog
  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
          title: Text(
            'User Details',
            style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${user['id']}', style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54)),
              SizedBox(height: 8),
              Text('Name: ${user['name']}', style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54)),
              SizedBox(height: 8),
              Text('Email: ${user['email']}', style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54)),
              SizedBox(height: 8),
              Text('Type: ${user['user_type']}', style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54)),
              SizedBox(height: 8),
              Text('Created: ${user['created_at']}', style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditUserForm(user);
              },
              child: Text('Edit', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(user);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Show create user form
  void _showCreateUserForm() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String userType = 'user';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
          title: Text(
            'Create User',
            style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: userType,
                  dropdownColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'User Type',
                    labelStyle: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['user', 'admin'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      userType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
                  _showErrorSnackBar('All fields are required');
                  return;
                }
                Navigator.pop(context);
                _createUser(
                  nameController.text,
                  emailController.text,
                  passwordController.text,
                  userType,
                );
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // Show edit user form
  void _showEditUserForm(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    String userType = user['user_type'] ?? 'user';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
          title: Text(
            'Edit User',
            style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: userType,
                  dropdownColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'User Type',
                    labelStyle: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['user', 'admin'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      userType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty || emailController.text.isEmpty) {
                  _showErrorSnackBar('Name and email are required');
                  return;
                }
                Navigator.pop(context);
                _updateUser(
                  user['id'],
                  nameController.text,
                  emailController.text,
                  userType,
                );
              },
              child: Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateUserType(user['id'], userType);
              },
              child: Text('Update Type Only', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
          title: Text(
            'Delete User',
            style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
          ),
          content: Text(
            'Are you sure you want to delete ${user['name']}?',
            style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteUser(user['id']);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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
          title: Text('Users'),
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchUsers,
            ),
            IconButton(
              icon: Icon(Icons.numbers),
              onPressed: _getUserCount,
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
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: TextStyle(color: isDarkTheme ? Colors.white54 : Colors.black54),
                    prefixIcon: Icon(Icons.search, color: isDarkTheme ? Colors.white54 : Colors.black54),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: isDarkTheme ? Colors.white54 : Colors.black54),
                      onPressed: () {
                        searchController.clear();
                        _fetchUsers();
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      _fetchUsers();
                    }
                  },
                  onSubmitted: _searchUsers,
                ),
              ),
              // Users list
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                        textAlign: TextAlign.center,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: isDarkTheme ? Colors.white30 : Colors.black26,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == users.length && hasMore) {
                      _fetchPaginatedUsers(currentPage + 1);
                      return Center(child: CircularProgressIndicator());
                    }
                    final user = users[index];
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
                          child: Text(
                            (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user['name'] ?? 'Unknown',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['email'] ?? '',
                              style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ID: ${user['id']} | Type: ${user['user_type']}',
                              style: TextStyle(
                                color: isDarkTheme ? Colors.white38 : Colors.black38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          icon: Icon(Icons.more_vert, color: isDarkTheme ? Colors.white : Colors.black),
                          color: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: isDarkTheme ? Colors.white : Colors.black),
                                  SizedBox(width: 8),
                                  Text('Details', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: isDarkTheme ? Colors.white : Colors.black),
                                  SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'details') {
                              _showUserDetails(user);
                            } else if (value == 'edit') {
                              _showEditUserForm(user);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(user);
                            }
                          },
                        ),
                        onTap: () => _showUserDetails(user),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateUserForm,
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
          child: Icon(Icons.add, color: isDarkTheme ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}