import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({Key? key}) : super(key: key);

  @override
  _ProfileUpdatePageState createState() => _ProfileUpdatePageState();
}
//
class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userThemeController = TextEditingController();

  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Replace with your actual API base URL
  final String baseUrl = 'https://your-api-url.com/api';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Load existing user data if available
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('user_name') ?? '';
    _emailController.text = prefs.getString('user_email') ?? '';
    _userThemeController.text = prefs.getInt('user_theme')?.toString() ?? '0';
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    setState(() {
      _selectedImages = images.map((image) => File(image.path)).toList();
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        _showSnackBar('Authentication token not found. Please login again.', true);
        return;
      }

      var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/update-profile')
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add form fields (only if they have values)
      if (_nameController.text.isNotEmpty) {
        request.fields['name'] = _nameController.text;
      }
      if (_emailController.text.isNotEmpty) {
        request.fields['email'] = _emailController.text;
      }
      if (_passwordController.text.isNotEmpty) {
        request.fields['password'] = _passwordController.text;
        request.fields['password_confirmation'] = _confirmPasswordController.text;
      }
      if (_userThemeController.text.isNotEmpty) {
        request.fields['user_theme'] = _userThemeController.text;
      }

      // Add images
      for (int i = 0; i < _selectedImages.length; i++) {
        var multipartFile = await http.MultipartFile.fromPath(
          'images[]',
          _selectedImages[i].path,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        if (decodedResponse['success']) {
          _showSnackBar('Profile updated successfully!', false);

          // Save updated user data
          final prefs = await SharedPreferences.getInstance();
          final userData = decodedResponse['user'];
          if (userData != null) {
            await prefs.setString('user_name', userData['name'] ?? '');
            await prefs.setString('user_email', userData['email'] ?? '');
            if (userData['user_theme'] != null) {
              await prefs.setInt('user_theme', userData['user_theme']);
            }
          }

          // Clear password fields
          _passwordController.clear();
          _confirmPasswordController.clear();

          // Clear selected images
          setState(() {
            _selectedImages.clear();
          });

        } else {
          _showSnackBar(decodedResponse['message'] ?? 'Update failed', true);
        }
      } else if (response.statusCode == 422) {
        // Validation errors
        String errorMessage = 'Validation failed:\n';
        if (decodedResponse['errors'] != null) {
          decodedResponse['errors'].forEach((key, value) {
            errorMessage += '${key}: ${value.join(', ')}\n';
          });
        }
        _showSnackBar(errorMessage, true);
      } else if (response.statusCode == 401) {
        _showSnackBar('Authentication failed. Please login again.', true);
      } else {
        _showSnackBar(decodedResponse['message'] ?? 'Update failed', true);
      }

    } catch (e) {
      _showSnackBar('Network error: ${e.toString()}', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Image Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Profile Images',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      if (_selectedImages.isNotEmpty)
                        Container(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: EdgeInsets.only(right: 8),
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: Icon(Icons.photo_library),
                        label: Text('Select Images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Form Fields
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length > 255) {
                            return 'Name must be less than 255 characters';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            if (value.length > 255) {
                              return 'Email must be less than 255 characters';
                            }
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (_passwordController.text.isNotEmpty) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      TextFormField(
                        controller: _userThemeController,
                        decoration: InputDecoration(
                          labelText: 'User Theme (0-10)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.palette),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            int? theme = int.tryParse(value);
                            if (theme == null) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Update Button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Updating...'),
                  ],
                )
                    : Text('Update Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _userThemeController.dispose();
    super.dispose();
  }
}