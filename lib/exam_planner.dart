import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;

import 'add_exam.dart';
import 'calendar.dart';

typedef ExamAddCallback = void Function(String subjectName, String dateAndTime);
typedef CalendarCallback = List<String> Function(DateTime day);

class ExamPlanner extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ExamPlannerState();
  }
}

class _ExamPlannerState extends State<ExamPlanner> {
  List<dynamic> exams = [];

  @override
  void initState() {
    _getExams();
    super.initState();
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
    if (preferences.containsKey("exams")) {
      String? jsonExams = preferences.getString("exams");
      var listExams = jsonDecode(jsonExams!);
      setState(() {
        exams = listExams;
      });
    }
  }

  void _setExams() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey("exams")) {
      preferences.remove("exams");
    }
    preferences.setString("exams", jsonEncode(exams));
  }

  void _addExamForm() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => AddExam(_addExam)));
  }

  void _viewCalendar() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => Calendar(_getExamsForDay)));
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
                icon: Icon(Icons.add_box_rounded), onPressed: _addExamForm)
          ],
        ),
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
