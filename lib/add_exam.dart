import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:core';

import 'exam_planner.dart';
import 'datetime_picker.dart';

class AddExam extends StatefulWidget {
  final ExamAddCallback callback;

  const AddExam(this.callback);

  @override
  State<StatefulWidget> createState() {
    return _AddExamState(callback);
  }
}

class _AddExamState extends State<AddExam> {
  final _formKey = GlobalKey<FormState>();

  final subjectNameController = TextEditingController();

  DateTime examDate = DateTime.now();
  String formattedDate = "";
  TimeOfDay examTime = TimeOfDay.now();
  String formattedTime = "";

  ExamAddCallback callback;

  _AddExamState(this.callback);

  void _process() {
    if (_formKey.currentState!.validate()) {
      callback(subjectNameController.text, formattedDate + " " + formattedTime);

      setState(() {
        subjectNameController.text = "";
        examDate = DateTime.now();
        examTime = TimeOfDay.now();
        formattedDate = intl.DateFormat('dd/MM/yyyy').format(examDate);
        formattedTime = examTime.format(context);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam successfully added.')),
      );
    }
  }

  void _initDateTime() {
    setState(() {
      formattedDate = intl.DateFormat('dd/MM/yyyy').format(examDate);
      formattedTime = examTime.format(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    _initDateTime();
    return Scaffold(
        appBar: AppBar(title: Text("Add exam", style: TextStyle(fontSize: 23))),
        body: Container(
          margin: EdgeInsets.only(top: 25),
          child: Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: subjectNameController,
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.article_outlined),
                    hintText: 'Enter subject name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Subject name can't be empty";
                    }
                    return null;
                  },
                ),
                FormDateTimePicker(
                    date: examDate,
                    time: examTime,
                    dateChanged: (value) {
                      setState(() {
                        examDate = value;
                        formattedDate =
                            intl.DateFormat('dd/MM/yyyy').format(examDate);
                      });
                    },
                    timeChanged: (value) {
                      setState(() {
                        examTime = value;
                        formattedTime = examTime.format(context);
                      });
                    }),
                Container(
                  margin: EdgeInsets.only(top: 15),
                  child: ElevatedButton(
                      child:
                          const Text('Submit', style: TextStyle(fontSize: 18)),
                      onPressed: _process),
                )
              ])),
        ));
  }
}
