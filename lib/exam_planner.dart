import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;

import 'add_exam.dart';
import 'calendar.dart';
import 'login.dart';

typedef ExamAddCallback = void Function(String subjectName, String dateAndTime);
typedef CalendarCallback = List<String> Function(DateTime day);

class ExamPlanner extends StatefulWidget {
  final String loggedInUser;

  const ExamPlanner(this.loggedInUser);

  @override
  State<StatefulWidget> createState() {
    return _ExamPlannerState(this.loggedInUser);
  }
}

class _ExamPlannerState extends State<ExamPlanner> {
  List<dynamic> exams = [];
  String loggedInUser;

  _ExamPlannerState(this.loggedInUser);

  @override
  void initState() {
    super.initState();

    _getExams();
  }

  void _addExam(String subjectName, String dateAndTime) {
    setState(() {
      exams.add({"subjectName": subjectName, "dateAndTime": dateAndTime});
    });
    _setExams();
  }

  List<String> _getExamsForDay(DateTime day) {
    List<String> listExams = [];

    String formattedDateTime = intl.DateFormat("dd/MM/yyyy").format(day);

    for (int i = 0; i < exams.length; i++) {
      var dateAndTimeSplitted = exams[i]["dateAndTime"].toString().split(" ");
      if (dateAndTimeSplitted[0] == formattedDateTime) {
        listExams.add(exams[i]["subjectName"] +
            " - " +
            dateAndTimeSplitted[1] +
            " " +
            dateAndTimeSplitted[2]);
      }
    }

    return listExams;
  }

  void _getExams() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(loggedInUser)) {
      String? jsonExams = preferences.getString(loggedInUser);
      var listExams = jsonDecode(jsonExams!);
      setState(() {
        exams = listExams;
      });
    }
  }

  void _setExams() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(loggedInUser)) {
      preferences.remove(loggedInUser);
    }
    preferences.setString(loggedInUser, jsonEncode(exams));
  }

  void _addExamForm() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => AddExam(_addExam)));
  }

  void _viewCalendar() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => Calendar(_getExamsForDay)));
  }

  void _clearPreferences() async {
    // helper function for clearing SharedPreferences data
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Exam Planner", style: TextStyle(fontSize: 25)),
            actions: [
              IconButton(
                  icon: Icon(Icons.calendar_today_rounded),
                  onPressed: _viewCalendar),
              IconButton(
                  icon: Icon(Icons.add_box_rounded), onPressed: _addExamForm),
              IconButton(icon: Icon(Icons.logout), onPressed: () {
                setState(() {
                  this.loggedInUser = "";
                });
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
              }),
            ]),
        body: _buildBody());
  }

  Widget _buildBody() {
    return ListView.builder(
      itemCount: exams.length,
      itemBuilder: (context, index) {
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // po vertikalna oska, bidejki e kolona, kolku da bide istata dolga. Ako se stavi min, dolzinata ke bide ednakva na taa dolzina sto ja zafakjaat decata (children)
            children: [
              ListTile(
                  leading: Icon(Icons.access_time_filled),
                  title: Text(exams[index]["subjectName"].toString(),
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  subtitle: Text(exams[index]["dateAndTime"].toString(),
                      style: TextStyle(fontSize: 17)),
                  trailing: Container(
                      child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              exams.removeAt(index);
                            });
                            _setExams();
                          }))),
            ],
          ),
        );
      },
    );
  }
}
