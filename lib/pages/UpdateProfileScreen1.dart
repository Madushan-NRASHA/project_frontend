// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:mime/mime.dart';
// import 'package:path/path.dart'; // To extract the file name
// import 'package:flutter/foundation.dart';
// import 'package:http_parser/http_parser.dart';
//
// class ProfileUpdatePage extends StatefulWidget {
//   const ProfileUpdatePage({Key? key}) : super(key: key);
//
//   @override
//   _ProfileUpdatePageState createState() => _ProfileUpdatePageState();
// }
//
// class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _userThemeController = TextEditingController();
//   List<File> _selectedImages = [];
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _isDarkTheme = false;
//   String? authToken;
//   String? userId;
//   Map<String, dynamic>? userArgs;
//   final String baseUrl = 'http://192.168.0.101:8000';
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//     if (args != null) {
//       authToken = args['token']?.toString();
//       var userIdValue = args['user_id'] ?? args['id'];
//       userId = userIdValue?.toString();
//       _nameController.text = args['name']?.toString() ?? '';
//       _emailController.text = args['email']?.toString() ?? '';
//       int userTheme = 0;
//       if (args['user_theme'] != null) {
//         if (args['user_theme'] is int) {
//           userTheme = args['user_theme'];
//         } else if (args['user_theme'] is String) {
//           userTheme = int.tryParse(args['user_theme']) ?? 0;
//         }
//       }
//       _userThemeController.text = userTheme.toString();
//       setState(() {
//         _isDarkTheme = userTheme == 1;
//       });
//       userArgs = args;
//       print("=== RECEIVED NAVIGATION ARGUMENTS ===");
//       print(
//           "Token: ${authToken != null ? 'Present (${authToken!.length} chars)' : 'Not found'}");
//       print("User ID: $userId");
//       print("Name: ${args['name']}");
//       print("Email: ${args['email']}");
//       print("Phone: ${args['phone']}");
//       print("Address: ${args['address']}");
//       print("User Theme: ${args['user_theme']} (parsed as: $userTheme)");
//       print("Profile Image: ${args['profile_image']}");
//       print("User Type: ${args['user_type']}");
//       print("=====================================");
//     } else {
//       print("No navigation arguments found, loading from SharedPreferences");
//       _loadUserData();
//     }
//   }
//
//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     _nameController.text = prefs.getString('user_name') ?? '';
//     _emailController.text = prefs.getString('user_email') ?? '';
//     int userTheme = prefs.getInt('user_theme') ?? 0;
//     _userThemeController.text = userTheme.toString();
//     setState(() {
//       _isDarkTheme = userTheme == 1;
//     });
//     _logUserData();
//   }
//
//   void _logUserData() {
//     print("=== PROFILE UPDATE - USER DETAILS ===");
//     print(
//         "Auth Token: ${authToken != null ? 'Present (${authToken!.length} chars)' : 'Not found'}");
//     print("User ID: $userId");
//     print("Name: ${_nameController.text}");
//     print("Email: ${_emailController.text}");
//     print(
//         "User Theme: ${_userThemeController.text} (${_isDarkTheme ? 'Dark' : 'Light'})");
//     print("Selected Images Count: ${_selectedImages.length}");
//     print("=====================================");
//   }
//
//   void _toggleTheme() {
//     setState(() {
//       _isDarkTheme = !_isDarkTheme;
//       _userThemeController.text = _isDarkTheme ? '1' : '0';
//     });
//     print(
//         "Theme toggled to: ${_isDarkTheme ? 'Dark' : 'Light'} (${_userThemeController.text})");
//     _saveThemePreference();
//     _showSnackBar(
//         'Theme changed to ${_isDarkTheme ? 'Dark' : 'Light'} mode', false);
//   }
//
//   Future<void> _saveThemePreference() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('user_theme', _isDarkTheme ? 1 : 0);
//   }
//
//   Future<String?> _getAuthToken() async {
//     if (authToken != null && authToken!.isNotEmpty) {
//       print("Using token from navigation arguments");
//       return authToken;
//     }
//     print("Token not found in navigation args, checking SharedPreferences");
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token');
//     print("SharedPreferences token: ${token != null ? 'Found' : 'Not found'}");
//     return token;
//   }
//
//   Future<void> _pickImages() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final List<XFile> images = await picker.pickMultiImage();
//       setState(() {
//         _selectedImages = images.map((image) => File(image.path)).toList();
//       });
//       print("Selected ${_selectedImages.length} images");
//       if (_selectedImages.isNotEmpty) {
//         _showSnackBar('${_selectedImages.length} images selected', false);
//       }
//     } catch (e) {
//       print("Error picking images: $e");
//       _showSnackBar('Error selecting images: $e', true);
//     }
//   }
//
//   Future<void> _updateProfile() async {
//     debugPrint("_updateProfile : ${_formKey.currentState!.validate().toString()}");
//
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     print("Starting profile update...");
//
//     try {
//       final token = await _getAuthToken();
//       if (token == null || token.isEmpty) {
//         print("ERROR: No authentication token available");
//         _showSnackBar(
//             'Authentication token not found. Please login again.', true);
//         return;
//       }
//
//     final uri = Uri.parse('$baseUrl/user-profile-update');
//
//
//
//       print("Using token: ${token.substring(0, 20)}...");
//
//       var request = http.MultipartRequest(
//         'POST',
//         uri
//       );
//
//
//       // Set the headers
//     request.headers.addAll({
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     });
//
//
//    final File? file = _selectedImages.isNotEmpty ? _selectedImages[0] : null;
//
//     // for (int i = 0; i < _selectedImages.length; i++) {
//     //     var multipartFile = await http.MultipartFile.fromPath(
//     //       'images[]',
//     //       _selectedImages[i].path,
//     //     );
//     //     request.files.add(multipartFile);
//     //     print("Added image ${i + 1}: ${_selectedImages[i].path}");
//     //   }
//
//       if (file != null) {
//         final fileName = basename(file.path);
//         final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
//         request.files.add(
//           await http.MultipartFile.fromPath(
//             'profile_image',
//             file.path,
//             filename:  fileName ,
//             contentType: MediaType.parse(mimeType),
//           ),
//         );
//         print("Added profile_image: $fileName with MIME type $mimeType");
//
//
//
//
//       if (userId != null) {
//         request.fields['user_id'] = userId!;
//         print("Adding user_id field: $userId");
//       }
//
//       if (_nameController.text.isNotEmpty) {
//         request.fields['name'] = _nameController.text;
//         print("Adding name field: ${_nameController.text}");
//       }
//
//       if (_emailController.text.isNotEmpty) {
//         request.fields['email'] = _emailController.text;
//         print("Adding email field: ${_emailController.text}");
//       }
//
//       if (_passwordController.text.isNotEmpty) {
//         request.fields['password'] = _passwordController.text;
//         request.fields['password_confirmation'] =
//             _confirmPasswordController.text;
//         print("Adding password fields");
//       }
//
//       if (_userThemeController.text.isNotEmpty) {
//         request.fields['user_theme'] = _userThemeController.text;
//         print("Adding user_theme field: ${_userThemeController.text}");
//       }
//
//
//
//       print("Request headers: ${request.headers}");
//       print("Request fields: ${request.fields}");
//       print("Sending update request...");
//
//       final response = await request.send();
//       final responseData = await response.stream.bytesToString();
//       print("Raw response length: ${responseData.length}");
//       print("Raw response content: $responseData");
//
//       if (response.statusCode != 200) {
//         print("Error status: ${response.statusCode}, Response: $responseData");
//         _showSnackBar('Server error: ${response.statusCode}', true);
//         return;
//       }
//
//       if (responseData.isEmpty) {
//         _showSnackBar('Empty response from server', true);
//         return;
//       }
//
//       Map<String, dynamic>? decodedResponse;
//       try {
//         decodedResponse = json.decode(responseData);
//       } catch (e) {
//         print("JSON parse error: $e");
//         _showSnackBar("Invalid response from server", true);
//         return;
//       }
//
//       if (decodedResponse == null) {
//         print("Error: Decoded response is null");
//         _showSnackBar("Invalid response from server", true);
//         return;
//       }
//
//       if (decodedResponse['success'] != null &&
//           decodedResponse['success'] == true) {
//         final userData = decodedResponse['user'];
//         _showSnackBar('Profile updated successfully!', false);
//
//         if (userData != null) {
//           final prefs = await SharedPreferences.getInstance();
//           await prefs.setString('user_name', userData['name'] ?? '');
//           await prefs.setString('user_email', userData['email'] ?? '');
//           if (userData['user_theme'] != null) {
//             await prefs.setInt('user_theme', userData['user_theme']);
//             setState(() {
//               _isDarkTheme = userData['user_theme'] == 1;
//             });
//           }
//         }
//
//         _passwordController.clear();
//         _confirmPasswordController.clear();
//         setState(() {
//           _selectedImages.clear();
//         });
//
//         print("Profile updated successfully");
//       } else {
//         final message = decodedResponse['message'] ?? 'Update failed';
//         _showSnackBar(message, true);
//       }
//     } catch (e) {
//       print("Network error: $e");
//       _showSnackBar('Network error: ${e.toString()}', true);
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _showSnackBar(String message, bool isError) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         duration: Duration(seconds: 3),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: _isDarkTheme ? ThemeData.dark() : ThemeData.light(),
//       child: Scaffold(
//         body: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: _isDarkTheme
//                   ? [
//                       Color(0xFF1a1a2e),
//                       Color(0xFF16213e),
//                       Color(0xFF0f3460),
//                     ]
//                   : [
//                       Color(0xFFf8f9ff),
//                       Color(0xFFe8f2ff),
//                       Color(0xFFd6e9ff),
//                     ],
//             ),
//           ),
//           child: SafeArea(
//             child: Column(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(20),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: Icon(
//                           Icons.arrow_back,
//                           color:
//                               _isDarkTheme ? Colors.white : Color(0xFF2d3748),
//                         ),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       SizedBox(width: 10),
//                       Expanded(
//                         child: Text(
//                           "Update Profile",
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color:
//                                 _isDarkTheme ? Colors.white : Color(0xFF2d3748),
//                           ),
//                         ),
//                       ),
//                       Container(
//                         decoration: BoxDecoration(
//                           color: _isDarkTheme
//                               ? Colors.white.withOpacity(0.1)
//                               : Colors.black.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(25),
//                         ),
//                         child: IconButton(
//                           icon: Icon(
//                             _isDarkTheme ? Icons.light_mode : Icons.dark_mode,
//                             color: _isDarkTheme ? Colors.yellow : Colors.indigo,
//                           ),
//                           onPressed: _toggleTheme,
//                           tooltip: _isDarkTheme
//                               ? 'Switch to Light Theme'
//                               : 'Switch to Dark Theme',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   margin: EdgeInsets.symmetric(horizontal: 20),
//                   padding: EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     color: _isDarkTheme
//                         ? Colors.white.withOpacity(0.1)
//                         : Colors.white.withOpacity(0.8),
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(
//                       color: _isDarkTheme
//                           ? Colors.white.withOpacity(0.2)
//                           : Colors.black.withOpacity(0.1),
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Profile Details:",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: _isDarkTheme ? Colors.white : Colors.black87,
//                           fontSize: 14,
//                         ),
//                       ),
//                       SizedBox(height: 5),
//                       Text(
//                         "Name: ${_nameController.text.isEmpty ? 'Not set' : _nameController.text} | Theme: ${_isDarkTheme ? 'Dark' : 'Light'} | Images: ${_selectedImages.length}",
//                         style: TextStyle(
//                           color: _isDarkTheme ? Colors.white70 : Colors.black54,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: EdgeInsets.all(16.0),
//                     child: Form(
//                       key: _formKey,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Card(
//                             elevation: 2,
//                             color:
//                                 _isDarkTheme ? Colors.grey[850] : Colors.white,
//                             child: Padding(
//                               padding: EdgeInsets.all(16.0),
//                               child: Column(
//                                 children: [
//                                   Text(
//                                     'Profile Images',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       color: _isDarkTheme
//                                           ? Colors.white
//                                           : Colors.black87,
//                                     ),
//                                   ),
//                                   SizedBox(height: 16),
//                                   if (_selectedImages.isNotEmpty)
//                                     Container(
//                                       height: 120,
//                                       child: ListView.builder(
//                                         scrollDirection: Axis.horizontal,
//                                         itemCount: _selectedImages.length,
//                                         itemBuilder: (context, index) {
//                                           return Container(
//                                             margin: EdgeInsets.only(right: 8),
//                                             width: 120,
//                                             height: 120,
//                                             decoration: BoxDecoration(
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                               image: DecorationImage(
//                                                 image: FileImage(
//                                                     _selectedImages[index]),
//                                                 fit: BoxFit.cover,
//                                               ),
//                                             ),
//                                             child: Stack(
//                                               children: [
//                                                 Positioned(
//                                                   top: 4,
//                                                   right: 4,
//                                                   child: GestureDetector(
//                                                     onTap: () {
//                                                       setState(() {
//                                                         _selectedImages
//                                                             .removeAt(index);
//                                                       });
//                                                       print(
//                                                           "Removed image at index $index");
//                                                     },
//                                                     child: Container(
//                                                       padding:
//                                                           EdgeInsets.all(4),
//                                                       decoration: BoxDecoration(
//                                                         color: Colors.red,
//                                                         shape: BoxShape.circle,
//                                                       ),
//                                                       child: Icon(
//                                                         Icons.close,
//                                                         size: 16,
//                                                         color: Colors.white,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                   SizedBox(height: 16),
//                                   ElevatedButton.icon(
//                                     onPressed: _pickImages,
//                                     icon: Icon(Icons.photo_library),
//                                     label: Text('Select Images'),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.blue,
//                                       foregroundColor: Colors.white,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 16),
//                           Card(
//                             elevation: 2,
//                             color:
//                                 _isDarkTheme ? Colors.grey[850] : Colors.white,
//                             child: Padding(
//                               padding: EdgeInsets.all(16.0),
//                               child: Column(
//                                 children: [
//                                   TextFormField(
//                                     controller: _nameController,
//                                     style: TextStyle(
//                                       color: _isDarkTheme
//                                           ? Colors.white
//                                           : Colors.black87,
//                                     ),
//                                     decoration: InputDecoration(
//                                       labelText: 'Name',
//                                       labelStyle: TextStyle(
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       border: OutlineInputBorder(),
//                                       prefixIcon: Icon(
//                                         Icons.person,
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                     ),
//                                     validator: (value) {
//                                       if (value != null &&
//                                           value.isNotEmpty &&
//                                           value.length > 255) {
//                                         return 'Name must be less than 255 characters';
//                                       }
//                                       return null;
//                                     },
//                                     onChanged: (value) {
//                                       print("Name field changed: $value");
//                                     },
//                                   ),
//                                   SizedBox(height: 16),
//                                   TextFormField(
//                                     controller: _emailController,
//                                     style: TextStyle(
//                                       color: _isDarkTheme
//                                           ? Colors.white
//                                           : Colors.black87,
//                                     ),
//                                     decoration: InputDecoration(
//                                       labelText: 'Email',
//                                       labelStyle: TextStyle(
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       border: OutlineInputBorder(),
//                                       prefixIcon: Icon(
//                                         Icons.email,
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                     ),
//                                     keyboardType: TextInputType.emailAddress,
//                                     validator: (value) {
//                                       if (value != null && value.isNotEmpty) {
//                                         if (!RegExp(
//                                                 r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                                             .hasMatch(value)) {
//                                           return 'Please enter a valid email';
//                                         }
//                                         if (value.length > 255) {
//                                           return 'Email must be less than 255 characters';
//                                         }
//                                       }
//                                       return null;
//                                     },
//                                     onChanged: (value) {
//                                       print("Email field changed: $value");
//                                     },
//                                   ),
//                                   SizedBox(height: 16),
//                                   TextFormField(
//                                     controller: _passwordController,
//                                     style: TextStyle(
//                                       color: _isDarkTheme
//                                           ? Colors.white
//                                           : Colors.black87,
//                                     ),
//                                     decoration: InputDecoration(
//                                       labelText: 'New Password',
//                                       labelStyle: TextStyle(
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       border: OutlineInputBorder(),
//                                       prefixIcon: Icon(
//                                         Icons.lock,
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       suffixIcon: IconButton(
//                                         icon: Icon(
//                                           _obscurePassword
//                                               ? Icons.visibility
//                                               : Icons.visibility_off,
//                                           color: _isDarkTheme
//                                               ? Colors.white70
//                                               : Colors.black54,
//                                         ),
//                                         onPressed: () {
//                                           setState(() {
//                                             _obscurePassword =
//                                                 !_obscurePassword;
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                     obscureText: _obscurePassword,
//                                     validator: (value) {
//                                       if (value != null &&
//                                           value.isNotEmpty &&
//                                           value.length < 8) {
//                                         return 'Password must be at least 8 characters';
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                                   SizedBox(height: 16),
//                                   TextFormField(
//                                     controller: _confirmPasswordController,
//                                     style: TextStyle(
//                                       color: _isDarkTheme
//                                           ? Colors.white
//                                           : Colors.black87,
//                                     ),
//                                     decoration: InputDecoration(
//                                       labelText: 'Confirm Password',
//                                       labelStyle: TextStyle(
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       border: OutlineInputBorder(),
//                                       prefixIcon: Icon(
//                                         Icons.lock_outline,
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       suffixIcon: IconButton(
//                                         icon: Icon(
//                                           _obscureConfirmPassword
//                                               ? Icons.visibility
//                                               : Icons.visibility_off,
//                                           color: _isDarkTheme
//                                               ? Colors.white70
//                                               : Colors.black54,
//                                         ),
//                                         onPressed: () {
//                                           setState(() {
//                                             _obscureConfirmPassword =
//                                                 !_obscureConfirmPassword;
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                     obscureText: _obscureConfirmPassword,
//                                     validator: (value) {
//                                       if (_passwordController.text.isNotEmpty) {
//                                         if (value != _passwordController.text) {
//                                           return 'Passwords do not match';
//                                         }
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                                   SizedBox(height: 16),
//                                   TextFormField(
//                                     controller: _userThemeController,
//                                     style: TextStyle(
//                                       color: _isDarkTheme
//                                           ? Colors.white
//                                           : Colors.black87,
//                                     ),
//                                     decoration: InputDecoration(
//                                       labelText: 'User Theme (0-Light, 1-Dark)',
//                                       labelStyle: TextStyle(
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       border: OutlineInputBorder(),
//                                       prefixIcon: Icon(
//                                         Icons.palette,
//                                         color: _isDarkTheme
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       suffixIcon: IconButton(
//                                         icon: Icon(
//                                           _isDarkTheme
//                                               ? Icons.dark_mode
//                                               : Icons.light_mode,
//                                           color: _isDarkTheme
//                                               ? Colors.yellow
//                                               : Colors.indigo,
//                                         ),
//                                         onPressed: _toggleTheme,
//                                         tooltip: 'Toggle Theme',
//                                       ),
//                                     ),
//                                     keyboardType: TextInputType.number,
//                                     readOnly: true,
//                                     validator: (value) {
//                                       if (value != null && value.isNotEmpty) {
//                                         int? theme = int.tryParse(value);
//                                         if (theme == null ||
//                                             (theme != 0 && theme != 1)) {
//                                           return 'Theme must be 0 (Light) or 1 (Dark)';
//                                         }
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 24),
//                           ElevatedButton(
//                             onPressed: _isLoading ? null : _updateProfile,
//                             child: _isLoading
//                                 ? Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       SizedBox(
//                                         width: 20,
//                                         height: 20,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           valueColor:
//                                               AlwaysStoppedAnimation<Color>(
//                                                   Colors.white),
//                                         ),
//                                       ),
//                                       SizedBox(width: 12),
//                                       Text('Updating...'),
//                                     ],
//                                   )
//                                 : Text('Update Profile'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               foregroundColor: Colors.white,
//                               padding: EdgeInsets.symmetric(vertical: 16),
//                               textStyle: TextStyle(fontSize: 16),
//                             ),
//                           ),
//                           SizedBox(height: 20),
//                           Container(
//                             padding: EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: _isDarkTheme
//                                   ? Colors.white.withOpacity(0.1)
//                                   : Colors.white.withOpacity(0.8),
//                               borderRadius: BorderRadius.circular(15),
//                               border: Border.all(
//                                 color: _isDarkTheme
//                                     ? Colors.white.withOpacity(0.2)
//                                     : Colors.black.withOpacity(0.1),
//                                 width: 1,
//                               ),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Instructions:",
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                     color: _isDarkTheme
//                                         ? Colors.white
//                                         : Color(0xFF2d3748),
//                                   ),
//                                 ),
//                                 SizedBox(height: 10),
//                                 Text(
//                                   "• Fill only the fields you want to update\n"
//                                   "• Password must be at least 8 characters\n"
//                                   "• Images are optional\n"
//                                   "• Theme toggle button changes appearance instantly\n"
//                                   "• All changes are logged in the console\n"
//                                   "• Token and User ID are automatically passed from navigation",
//                                   style: TextStyle(
//                                     color: _isDarkTheme
//                                         ? Colors.white70
//                                         : Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _userThemeController.dispose();
//     super.dispose();
//   }
// }
