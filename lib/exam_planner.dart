import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ExamPlanner extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ExamPlannerState();
  }
}

class ExamPlannerState extends State<ExamPlanner> {
  final _formKey = GlobalKey<FormState>();
  final subjectNameController = TextEditingController();
  final dateAndTimeController = TextEditingController();

  var elements = [];

  Widget _buildBody() {
    return ListView.builder(
      itemCount: elements.length,
      itemBuilder: (context, index) {
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // po vertikalna oska, bidejki e kolona, kolku da bide istata dolga. Ako se stavi min, dolzinata ke bide ednakva na taa dolzina sto ja zafakjaat decata (children)
            children: [
              ListTile(
                leading: Icon(Icons.access_time_filled),
                title: Text(elements[index]["subjectName"].toString(),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                subtitle: Text(elements[index]["dateAndTime"].toString(),
                    style: TextStyle(fontSize: 17)),
                trailing: Container(child: IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () {
                  setState(() {
                    elements.removeAt(index);
                  });
                },))
              ),
            ],
          ),
        );
      },
    );
  }

  void _process() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        elements.add({ "subjectName": subjectNameController.text, "dateAndTime": dateAndTimeController.text });
        subjectNameController.text = "";
        dateAndTimeController.text = "";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam successfully added')),
      );
    }
  }

  void _addExamForm() {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("Add exam", style: TextStyle(fontSize: 23))),
        body: Container(
          margin: EdgeInsets.only(top: 25),
          child: Form(
              key: _formKey,
              child: Column(
                  children: [
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
                    TextFormField(
                      controller: dateAndTimeController,
                      decoration: const InputDecoration(
                        icon: const Icon(Icons.calendar_today),
                        hintText: 'Enter exam date and time (Day/Month/Year Hour:Minute)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Date and time can't be empty";
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      child: const Text('Submit'),
                      onPressed: _process
                    ),
                  ])),
        )
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Exam Planner", style: TextStyle(fontSize: 25)),
          actions: [
            IconButton(icon: Icon(Icons.add_box_rounded), onPressed: _addExamForm)
          ],
        ),
        body: _buildBody()
    );
  }
}


