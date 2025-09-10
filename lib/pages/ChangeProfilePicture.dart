import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ChangeProfilePicture extends StatefulWidget {
  @override
  _ChangeProfilePictureState createState() => _ChangeProfilePictureState();
}

class _ChangeProfilePictureState extends State<ChangeProfilePicture> {
  late Map<String, dynamic> userArgs;
  bool isLoading = false;
  bool isDarkTheme = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    isDarkTheme = (userArgs['user_theme'] ?? 0) == 1;

    // Log user details
    _logUserDetails();
  }

  // Log user details
  void _logUserDetails() {
    print("=== USER DETAILS ===");
    print("User ID: ${userArgs['id']}");
    print("User Name: ${userArgs['name'] ?? 'N/A'}");
    print("User Email: ${userArgs['email'] ?? 'N/A'}");
    print("User Theme: ${userArgs['user_theme']} (${isDarkTheme ? 'Dark' : 'Light'})");
    print("Profile Picture: ${userArgs['Profile_Pic'] ?? 'N/A'}");
    print("All User Args: $userArgs");
    print("==================");
  }

  // Toggle theme function
  void _toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme;
      userArgs['user_theme'] = isDarkTheme ? 1 : 0;
    });

    print("Theme toggled to: ${isDarkTheme ? 'Dark' : 'Light'} (${userArgs['user_theme']})");

    // Show snackbar to confirm theme change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isDarkTheme ? 'Dark theme enabled' : 'Light theme enabled'),
        duration: Duration(seconds: 1),
        backgroundColor: isDarkTheme ? Colors.grey[800] : Colors.grey[600],
      ),
    );
  }

  // Check and request permissions
  Future<bool> _checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Check camera permission
        final cameraStatus = await Permission.camera.request();

        // For Android 13+ (API 33+), use photos permission
        // For older versions, use storage permission
        PermissionStatus storageStatus;
        if (await Permission.photos.request().isGranted) {
          storageStatus = PermissionStatus.granted;
        } else {
          storageStatus = await Permission.storage.request();
        }

        return cameraStatus.isGranted && storageStatus.isGranted;
      } else {
        // iOS permissions
        final cameraPermission = await Permission.camera.request();
        final photosPermission = await Permission.photos.request();
        return cameraPermission.isGranted && photosPermission.isGranted;
      }
    } catch (e) {
      print("Permission error: $e");
      // If permission handler fails, try to proceed anyway
      return true;
    }
  }

  Future<void> _pickImage() async {
    print("Button clicked - _pickImage called"); // Debug print

    try {
      // Show dialog immediately without permission check first
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Colors.white,
            title: Text(
              'ප්‍රොෆයිල් පින්තූරය තෝරන්න',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black87,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                  title: Text(
                    'ගැලරියෙන්',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _selectFromGallery();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                  title: Text(
                    'කැමරාවෙන්',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _selectFromCamera();
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("Error showing dialog: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dialog error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Colors.white,
          title: Text(
            'අවසරය අවශ්‍යයි',
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'ගැලරිය සහ කැමරාව ප්‍රවේශ කිරීමට අවසරය අවශ්‍යයි. කරුණාකර සැකසීම් වලින් අවසර ලබා දෙන්න.',
            style: TextStyle(
              color: isDarkTheme ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'අවලංගු කරන්න',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text(
                'සැකසීම්',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectFromGallery() async {
    print("Gallery selection started"); // Debug

    try {
      // Try to pick image directly first
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        print("Image selected from gallery: ${pickedFile.path}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('පින්තූරය සාර්ථකව තෝරන ලදී!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Gallery error: $e"); // Debug

      // If permission error, try to handle it
      if (e.toString().contains('permission')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ගැලරිය ප්‍රවේශ කිරීමට අවසරය අවශ්‍යයි'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'සැකසීම්',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ගැලරිය ප්‍රවේශ කිරීමේ දෝෂයක්: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectFromCamera() async {
    print("Camera selection started"); // Debug

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        print("Image captured from camera: ${pickedFile.path}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('පින්තූරය සාර්ථකව ගන්නා ලදී!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Camera error: $e"); // Debug

      if (e.toString().contains('permission')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('කැමරාව ප්‍රවේශ කිරීමට අවසරය අවශ්‍යයි'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'සැකසීම්',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('කැමරාව ප්‍රවේශ කිරීමේ දෝෂයක්: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('පින්තූරයක් තෝරන්න'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    print("Starting profile picture upload for user ID: ${userArgs['id']}");

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.0.2.2:8000/api/upload-profile-picture"),
      );

      request.fields['user_id'] = userArgs['id'].toString();
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          _selectedImage!.path,
        ),
      );

      print("Sending upload request...");
      var response = await request.send();
      print("Upload response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);

        print("Upload successful: $jsonData");

        userArgs['Profile_Pic'] = jsonData['profile_picture_url'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ප්‍රොෆයිල් පින්තූරය සාර්ථකව යාවත්කාලීන කරන ලදී!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, userArgs);
      } else {
        print("Upload failed with status: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ප්‍රොෆයිල් පින්තූරය යාවත්කාලීන කිරීමේ දෝෂයක්!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('දෝෂයක්: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // Custom App Bar with Theme Toggle
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                        ),
                        onPressed: () => Navigator.pop(context, userArgs),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "ප්‍රොෆයිල් පින්තූරය වෙනස් කරන්න",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                          ),
                        ),
                      ),
                      // Theme Toggle Button
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isDarkTheme ? Icons.light_mode : Icons.dark_mode,
                            color: isDarkTheme ? Colors.yellow : Colors.indigo,
                          ),
                          onPressed: _toggleTheme,
                          tooltip: isDarkTheme ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                        ),
                      ),
                    ],
                  ),
                ),

                // User Details Display (Debug Info)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "User Details:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkTheme ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "ID: ${userArgs['id'] ?? 'N/A'} | Name: ${userArgs['name'] ?? 'N/A'} | Theme: ${isDarkTheme ? 'Dark' : 'Light'}",
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(height: 20),

                        // Current Profile Picture
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isDarkTheme
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.blue.withOpacity(0.2),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _selectedImage != null
                                ? Image.file(
                              _selectedImage!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                                : userArgs['Profile_Pic'] != null && userArgs['Profile_Pic'].isNotEmpty
                                ? Image.network(
                              userArgs['Profile_Pic'],
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.blue, Colors.purple],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                                : Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.blue, Colors.purple],
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 40),

                        // Select Image Button
                        Container(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              print("Button pressed!"); // Debug
                              _pickImage();
                            },
                            icon: Icon(Icons.photo_library, color: Colors.white),
                            label: Text(
                              "පින්තූරයක් තෝරන්න",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Upload Button
                        if (_selectedImage != null)
                          Container(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _uploadProfilePicture,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: isLoading
                                  ? CircularProgressIndicator(
                                color: Colors.white,
                              )
                                  : Text(
                                "අප්ලෝඩ් කරන්න",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        SizedBox(height: 40),

                        // Instructions
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDarkTheme
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isDarkTheme
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "උපදෙස්",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "• හොඳ ප්‍රතිඵලයක් සඳහා ඉහළ ගුණාත්මක පින්තූරයක් තෝරන්න\n"
                                    "• චතුරස්‍ර පින්තූරයක් වඩා හොඳයි\n"
                                    "• ෆයිල් ප්‍රමාණය 5MB ට වඩා අඩු විය යුතුයි\n"
                                    "• ගැලරිය ප්‍රවේශ කිරීමට අවසර ලබා දෙන්න\n"
                                    "• Theme toggle button එක top right corner එකේ තියෙනවා",
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
}