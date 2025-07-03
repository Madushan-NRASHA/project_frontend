import 'package:flutter/material.dart';

class user_dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || route.settings.arguments == null) {
      return Scaffold(
        appBar: AppBar(title: Text('User Dashboard')),
        body: Center(child: Text('No data found')),
      );
    }

    final args = route.settings.arguments as Map<String, dynamic>;

    final String name = args['name'] ?? 'User';
    final String theme = args['theme'] ?? 'Default';
    final String? profilePic = args['profilePic'];

    return Scaffold(
      appBar: AppBar(title: Text('User Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome $name'),
            SizedBox(height: 8),
            Text('Theme: $theme'),
            SizedBox(height: 16),
            profilePic != null && profilePic.isNotEmpty
                ? Image.network(profilePic)
                : Icon(Icons.account_circle, size: 100),
          ],
        ),
      ),
    );
  }
}
