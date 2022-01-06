import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import 'secrets.dart';
import 'add_exam.dart';
import 'add_event.dart';
import 'calendar.dart';
import 'map.dart';
import 'event_map.dart';
import 'login.dart';
import 'location.dart';

typedef ExamAddCallback = void Function(String subjectName, String dateAndTime);
typedef EventAddCallback = void Function(String eventName, String dateAndTime,
    String locationName, double locationLatitude, double locationLongitude);
typedef CalendarCallback = List<String> Function(DateTime day);

class ExamPlanner extends StatefulWidget {
  final String loggedInUser;
  final String homeLocationKey;
  final String homeLatitudeKey;
  final String homeLongitudeKey;
  final String userEventsKey;

  const ExamPlanner(this.loggedInUser, this.homeLocationKey,
      this.homeLatitudeKey, this.homeLongitudeKey, this.userEventsKey);

  @override
  State<StatefulWidget> createState() {
    return _ExamPlannerState(this.loggedInUser, this.homeLocationKey,
        this.homeLatitudeKey, this.homeLongitudeKey, this.userEventsKey);
  }
}

class _ExamPlannerState extends State<ExamPlanner> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<dynamic> exams = [];
  List<dynamic> events = [];

  String loggedInUser;

  String homeLocationKey;
  String homeLatitudeKey;
  String homeLongitudeKey;
  String userEventsKey;

  double? _homeLatitude = 0.000;
  double? _homeLongitude = 0.000;

  // static const String groupKey = Secrets.groupKey; // YOUR GROUP KEY ID HERE
  static const String groupChannelId =
      Secrets.groupChannelId; // YOUR GROUP CHANNEL ID HERE
  static const String groupChannelName =
      Secrets.groupChannelName; // YOUR GROUP CHANNEL NAME HERE
  static const String groupChannelDescription =
      Secrets.groupChannelDescription; // YOUR GROUP CHANNEL DESCRIPTION HERE

  LocationSettings locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
    forceLocationManager: true,
    intervalDuration: const Duration(seconds: 10),
  );

  late Timer timer;

  _ExamPlannerState(this.loggedInUser, this.homeLocationKey,
      this.homeLatitudeKey, this.homeLongitudeKey, this.userEventsKey);

  Future<Map> _init() async {
    final preferences = await SharedPreferences.getInstance();
    final result = {
      'homeLatitude': preferences.getDouble(homeLatitudeKey) ?? null,
      'homeLongitude': preferences.getDouble(homeLongitudeKey) ?? null,
    };
    return result;
  }

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
        const Duration(minutes: 60), (Timer t) => _checkLocation());

    _init().then((result) {
      setState(() {
        _homeLatitude = result['homeLatitude'];
        _homeLongitude = result['homeLongitude'];
      });
    });

    _initializeAndroidNotificationSettings();
    _initializeLocalTimezone();
    _getExams();
    _getEvents();
    _checkLocation();
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

  Future<tz.TZDateTime> _locationInRange() async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    Position pos = await _determineCurrentPosition();

    if (_homeLatitude != null && _homeLongitude != null) {
      double distance = Geolocator.distanceBetween(
          _homeLatitude!, _homeLongitude!, pos.latitude, pos.longitude);

      if (distance <= 100) {
        return tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      }
    }

    return now.subtract(const Duration(seconds: 5));
  }

  Future<void> _checkLocation() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        "Location update.",
        "You are home.",
        await _locationInRange(),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                groupChannelId, groupChannelName,
                channelDescription: groupChannelDescription)),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<Position> _determineCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // ========== SHARED PREFERENCES RELATED COMPONENTS ========== //
  void _addExam(String subjectName, String dateAndTime) {
    setState(() {
      exams.add({"subjectName": subjectName, "dateAndTime": dateAndTime});
    });
    _setExams();
  }

  void _addEvent(String eventName, String dateAndTime, String locationName,
      double locationLatitude, double locationLongitude) {
    setState(() {
      events.add({
        "eventName": eventName,
        "dateAndTime": dateAndTime,
        "locationName": locationName,
        "locationLatitude": locationLatitude,
        "locationLongitude": locationLongitude
      });
    });

    _setEvents();
  }

  List<String> _getObligationsForDay(DateTime day) {
    List<String> dayList = [];

    String formattedDateTime = intl.DateFormat("dd/MM/yyyy").format(day);

    for (int i = 0; i < exams.length; i++) {
      var dateAndTimeSplitted = exams[i]["dateAndTime"].toString().split(" ");
      if (dateAndTimeSplitted[0] == formattedDateTime) {
        dayList.add(exams[i]["subjectName"] +
            " - " +
            dateAndTimeSplitted[1] +
            " " +
            dateAndTimeSplitted[2]);
      }
    }

    for (int i = 0; i < events.length; i++) {
      var dateAndTimeSplitted = events[i]["dateAndTime"].toString().split(" ");
      if (dateAndTimeSplitted[0] == formattedDateTime) {
        dayList.add(events[i]["eventName"] +
            " - At " +
            events[i]["locationName"] +
            " - " +
            dateAndTimeSplitted[1] +
            " " +
            dateAndTimeSplitted[2]);
      }
    }

    return dayList;
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

  void _getEvents() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(userEventsKey)) {
      String? jsonEvents = preferences.getString(userEventsKey);
      var listEvents = jsonDecode(jsonEvents!);
      setState(() {
        events = listEvents;
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

  void _setEvents() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(userEventsKey)) {
      preferences.remove(userEventsKey);
    }
    preferences.setString(userEventsKey, jsonEncode(events));
  }

  // ========== ADD EXAM FORM BUILDER ========== //
  void _addExamForm() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => AddExam(_addExam)));
  }

  // ========== ADD EVENT FORM BUILDER ========== //
  void _addEventForm() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => AddEvent(_addEvent)));
  }

  // ========== CALENDAR BUILDER ========== //
  void _viewCalendar() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Calendar(_getObligationsForDay)));
  }

  // ========== ADD HOME LOCATION FORM BUILDER ========== //
  void _addHomeLocation() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MyLocation(this.homeLocationKey,
                this.homeLatitudeKey, this.homeLongitudeKey)));
  }

  // ========== GENERIC MAP BUILDER ========== //
  void _viewMap() async {
    Position pos = await _determineCurrentPosition();

    double lat = pos.latitude;
    double lng = pos.longitude;

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => MyMap(lat, lng)));
  }

  // ========== EVENT MAP BUILDER ========== //
  void _eventMap() async {
    Position pos = await _determineCurrentPosition();

    double lat = pos.latitude;
    double lng = pos.longitude;

    Navigator.push(context,
        MaterialPageRoute(builder: (context) => MyEventMap(lat, lng, events)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(title: Text("EP", style: TextStyle(fontSize: 25)), actions: [
          Container(
            margin: EdgeInsets.only(top: 18, right: 15),
            child: Text(loggedInUser.split("-")[0],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          IconButton(
              icon: Icon(Icons.add_box_rounded), onPressed: _addExamForm),
          IconButton(
              icon: Icon(Icons.calendar_today_rounded),
              onPressed: _viewCalendar),
          IconButton(
            icon: Icon(Icons.map),
            onPressed: _viewMap,
          ),
          IconButton(
            icon: Icon(Icons.location_on_outlined),
            onPressed: _addHomeLocation,
          ),
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                setState(() {
                  this.loggedInUser = "";
                });
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Login()));
              }),
        ]),
        body: _buildBody());
  }

  Widget _buildBody() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          margin: EdgeInsets.only(top: 15),
          padding: EdgeInsets.only(bottom: 10, left: 15),
          child: Align(
              alignment: Alignment.topLeft,
              child: Text("Exams",
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
      SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          child: ListView.builder(
            itemCount: exams.length,
            itemBuilder: (context, index) {
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                        leading: Icon(Icons.access_time_filled),
                        title: Text(exams[index]["subjectName"].toString(),
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
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
          )),
      Container(
          margin: EdgeInsets.only(top: 15),
          padding: EdgeInsets.only(bottom: 10, left: 15, right: 20),
          child: Align(
              alignment: Alignment.topLeft,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Events",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    Container(
                        margin: EdgeInsets.only(left: 80),
                        child: ElevatedButton(
                            child: Text("View map",
                                style: TextStyle(fontSize: 16)),
                            onPressed: _eventMap,
                            style: ElevatedButton.styleFrom(
                                primary: Colors.green))),
                    ElevatedButton(
                        child:
                            Text("Add event", style: TextStyle(fontSize: 16)),
                        onPressed: _addEventForm)
                  ]))),
      SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                        leading: Icon(Icons.access_time_filled),
                        title: Text(
                            events[index]["eventName"].toString() +
                                " - At " +
                                events[index]["locationName"],
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        subtitle: Text(events[index]["dateAndTime"].toString(),
                            style: TextStyle(fontSize: 17)),
                        trailing: Container(
                            child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    events.removeAt(index);
                                  });
                                  _setEvents();
                                }))),
                  ],
                ),
              );
            },
          ))
    ]);
  }

  // helper function for clearing SharedPreferences data
  void _clearPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }
}
