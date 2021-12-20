import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exam_planner.dart';

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginState();
  }
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool validationError = false;

  Future<bool> _validate() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    if(!preferences.containsKey(usernameController.text)) {
      setState(() {
        validationError = true;
      });
      return false;
    }

    if(passwordController.text.hashCode == preferences.get(usernameController.text).hashCode) {
      return true;
    }

    setState(() {
      validationError = true;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Login', style: TextStyle(fontSize: 25)),
        ),
        body: Form(
          key: _formKey,
          child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 5),
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.only(top: 40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: Center(
                    child: Text("ExamPlanner Login", style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
                  ),
                ),
                validationError ? Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.only(top: 15, bottom: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: Center(
                    child: Text("Invalid authentication attempt", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                ) : Text(""),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          validationError = false;
                        });
                        return 'Please enter your username';
                      }
                      return null;
                    },
                    controller: usernameController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Username',
                        hintText: 'Enter your username'),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          validationError = false;
                        });
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                        hintText: 'Enter your password'),
                  ),
                ),
                Container(
                  height: 50,
                  width: 250,
                  decoration: BoxDecoration(
                      color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                  child: TextButton(
                      child: Text(
                        'Login',
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        bool isUserValidated = await _validate();
                        if(!isUserValidated) {
                          return;
                        }

                        setState(() {
                          validationError = false;
                        });

                        Navigator.pop(context);
                        Navigator.push(
                            context, MaterialPageRoute(builder: (context) => ExamPlanner(usernameController.text + "-current")));
                      }
                  ),
                ),
              ]
          ),
        )
    );
  }
}
