import 'package:flutter/material.dart';

import 'exam_planner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.blue[600]),
      home: ExamPlanner()
    );
  }
}