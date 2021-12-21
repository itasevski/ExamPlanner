import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

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
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<dynamic> exams = [];
  String loggedInUser;

  // static const String groupKey = 'mk.ukim.finki.examplanner';
  static const String groupChannelId = 'testchannelid';
  static const String groupChannelName = 'testchannelname';
  static const String groupChannelDescription = 'testchanneldescription';

  _ExamPlannerState(this.loggedInUser);

  @override
  void initState() {
    super.initState();

    _initializeAndroidNotificationSettings();
    _initializeLocalTimezone();
    _getExams();
  }

  // ========== NOTIFICATION SYSTEM RELATED COMPONENTS ========== //
  void _initializeAndroidNotificationSettings() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings("app_icon");

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _initializeLocalTimezone() async {
    await _configureLocalTimeZone();
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  String getExamSubjectsForToday() {
    String result = "";
    String todaysDate = intl.DateFormat("dd/MM/yyyy kk:mm")
        .format(DateTime.now())
        .split(" ")[0];

    bool flag = false;
    for (int i = 0; i < exams.length; i++) {
      String examDateTime = exams[i]["dateAndTime"];
      String examDate = examDateTime.split(" ")[0];
      if (examDate == todaysDate && flag == false) {
        result += exams[i]["subjectName"];
        flag = true;
      } else if (examDate == todaysDate && flag == true) {
        result += ", " + exams[i]["subjectName"];
      }
    }

    return result;
  }

  tz.TZDateTime _upcomingExams() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < exams.length; i++) {
      String examDateTime = exams[i]["dateAndTime"];
      DateTime convertedExamDateTime =
          new intl.DateFormat("dd/MM/yyyy hh:mm").parse(examDateTime);
      tz.TZDateTime tzConvertedExamDateTime =
          tz.TZDateTime.from(convertedExamDateTime, tz.local);
      if (tzConvertedExamDateTime.day == now.day &&
          tzConvertedExamDateTime.month == now.month &&
          tzConvertedExamDateTime.year == now.year) {
        return tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      }
    }

    return now.subtract(const Duration(seconds: 5));
  }

  Future<void> _checkUpcomingExams() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        "You have exam/s today.",
        getExamSubjectsForToday(),
        _upcomingExams(),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                groupChannelId, groupChannelName,
                channelDescription: groupChannelDescription)),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  // ========== SHARED PREFERENCES RELATED COMPONENTS ========== //
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

    _checkUpcomingExams();
  }

  void _setExams() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(loggedInUser)) {
      preferences.remove(loggedInUser);
    }
    preferences.setString(loggedInUser, jsonEncode(exams));
  }

  // ========== ADD EXAM FORM BUILDER ========== //
  void _addExamForm() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => AddExam(_addExam)));
  }

  // ========== CALENDAR BUILDER ========== //
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
              Container(
                margin: EdgeInsets.only(top: 18, right: 15),
                child: Text(loggedInUser.split("-")[0],
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                  icon: Icon(Icons.calendar_today_rounded),
                  onPressed: _viewCalendar),
              IconButton(
                  icon: Icon(Icons.add_box_rounded), onPressed: _addExamForm),
              IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () {
                    setState(() {
                      this.loggedInUser = "";
                    });
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Login()));
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

  // helper function for clearing SharedPreferences data
  void _clearPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }
}
