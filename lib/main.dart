import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  void _initialize() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey("admin")) {
      preferences.setInt("admin", "admin123".hashCode);
    }
    if (!preferences.containsKey("user")) {
      preferences.setInt("user", "user123".hashCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initialize();
    return MaterialApp(
        theme: ThemeData(primaryColor: Colors.blue[600]), home: Login());
  }
}
