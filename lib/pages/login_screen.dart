import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  final Logger logger = Logger();

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> loginUser() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse("http://10.0.2.2:8000/api/login");
      logger.i("Sending POST to $url");

      final response = await http.post(
        url,
        headers: {"Accept": "application/json"},
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        },
      );

      logger.i("Status Code: ${response.statusCode}");
      logger.d("Response Body: ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data.containsKey('token') && data.containsKey('user')) {
          final token = data['token'];
          final user = data['user'];
          final userType = (user['user_type'] ?? 'user').toString().toLowerCase();

          logger.i("Token received: $token");

          // Save token locally
          await saveToken(token);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ප්‍රවේශය සාර්ථකයි!'),
              backgroundColor: Colors.green,
            ),
          );

          // Redirect based on user_type and pass token + user data
          if (userType == 'admin') {
            Navigator.pushReplacementNamed(
              context,
              '/admin_dashboard',
              arguments: {
                'token': token,
                'id':user['id'],
                'name': user['name'],
                'email': user['email'],
                'phone': user['phone'] ?? '',
                'address': user['address'] ?? '',
                'user_theme': user['user_theme'] ?? 0,
                'profile_image': user['profile_image'] ?? '',
                'user_type': userType,
              },
            );
          } else {
            Navigator.pushReplacementNamed(
              context,
              '/user_dashboard',
              arguments: {
                'token': token,
                'name': user['name'],
                'email': user['email'],
                'phone': user['phone'] ?? '',
                'address': user['address'] ?? '',
                'user_theme': user['user_theme'] ?? 0,
                'profile_image': user['profile_image'] ?? '',
                'user_type': userType,
              },
            );
          }
        } else {
          logger.w("Login failed: Missing token or user info");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ප්‍රවේශය අසාර්ථකයි: ${data['message'] ?? 'Invalid response from server'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        logger.e("Login error: ${data['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ප්‍රවේශය අසාර්ථකයි: ${data['message'] ?? 'වලංගු නොවන අක්තපත්‍ර'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.e("Exception during login", error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('දෝෂයක්: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0066FF),
              Color(0xFF00CCFF),
              Color(0xFF0099FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.account_circle, size: 80, color: Colors.white),
                        const SizedBox(height: 16),
                        const Text(
                          "ප්‍රවේශ වන්න",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black26,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "ඔබේ ගිණුමට ප්‍රවේශ වීම සඳහා",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: emailController,
                          label: "විද්‍යුත් තැපෑල",
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: passwordController,
                          label: "මුරපදය",
                          icon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : ElevatedButton(
                            onPressed: loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0066FF),
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "ප්‍රවේශ වන්න",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: RichText(
                            text: TextSpan(
                              text: "ගිණුමක් නැද්ද? ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                              children: const [
                                TextSpan(
                                  text: "ලියාපදිංචි වන්න",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ආරක්ෂිත ප්‍රවේශය",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
