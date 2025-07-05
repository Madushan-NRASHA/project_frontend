import 'package:flutter/material.dart';
import 'pages/register_screen.dart';
import 'pages/login_screen.dart';
import 'pages/home_screen.dart';
import 'pages/user_dashboard.dart';
import 'pages/admin_dashboard.dart';
import 'pages/ChangeProfilePicture.dart';
// import 'pages/change_profile_picture.dart';
import 'pages/view_profile.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My First App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/register',
      routes: {
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/user_dashboard': (context) => user_dashboard(),
        '/admin_dashboard': (context) => Admin_dashboard(),
        // Profile management routes
        '/user-profile-update': (context) => ChangeProfilePicture(),
        '/change-profile-picture': (context) => ChangeProfilePicture(),
        '/view-profile': (context) => ViewProfile(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}