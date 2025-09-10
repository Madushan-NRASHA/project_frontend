import 'package:flutter/material.dart';
import 'pages/register_screen.dart';
import 'pages/login_screen.dart';
import 'pages/home_screen.dart';
import 'pages/user_dashboard.dart';
import 'pages/admin_dashboard.dart';
import 'pages/ChangeProfilePicture.dart';
import 'pages/UpdateProfileScreen.dart';
import 'pages/ReportController.dart';
import 'pages/JobController.dart';
import 'pages/UserController.dart';
import 'pages/ActivityController.dart';
import 'pages/JobFilter.dart';
import 'pages/ProjectsScreen.dart';
import 'pages/chat_box.dart';
import 'pages/ChatsListPage.dart';
import 'pages/UserManagementScreen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My First App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/register',

      // ✅ simple routes without arguments
      routes: {
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/user_dashboard': (context) => UsersPage(),
        '/admin_dashboard': (context) => AdminDashboard(),

        // Profile management
        '/user-profile-update': (context) => ChangeProfilePicture(),
        '/change-profile-picture': (context) => ChangeProfilePicture(),
        '/view-profile': (context) => UserProfileScreen(),

        // Other screens
        '/users': (context) => UsersPage(),
        '/jobs': (context) => JobDeleteScreen(),
        '/reports': (context) => ReportsScreen(),
        '/activities': (context) => ActivitiesScreen(),
        '/find-jobs': (context) => JobFilterPage(),
        '/user-projects': (context) => ProjectsScreen(),
        '/ChatsListPage': (context) => ChatsListPage(),
        '/User-managemet':(context)=>UserManagementScreen(),
        // '/user-chat':(context)=>UserChatPage()

      },


      onGenerateRoute: (settings) {
        if (settings.name == '/user-chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => UserChatPage (arguments: args),
          );
        }
        return null;
      },

      debugShowCheckedModeBanner: false,
    );
  }
}
