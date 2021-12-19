import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class FormDateTimePicker extends StatefulWidget {
  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> dateChanged;
  final ValueChanged<TimeOfDay> timeChanged;

  const FormDateTimePicker(
      {required this.date,
      required this.time,
      required this.dateChanged,
      required this.timeChanged});

  @override
  _FormDateTimePickerState createState() => _FormDateTimePickerState();
}

class _FormDateTimePickerState extends State<FormDateTimePicker> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Date and time',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              Text(
                intl.DateFormat('dd/MM/yyyy').format(widget.date) +
                    " " +
                    widget.time.format(context),
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          TextButton(
            child: const Text('Change', style: TextStyle(fontSize: 15)),
            onPressed: () async {
              var newDate = await showDatePicker(
                context: context,
                initialDate: widget.date,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );

              var newTime = await showTimePicker(
                context: context,
                initialTime: widget.time,
              );

              // Don't change the date if the date picker returns null.
              if (newDate == null || newTime == null) {
                return;
              }
              // onChanged:
              // (value) {
              //   setState(() {
              //     newDate = value;
              //   });
              // };

              widget.dateChanged(newDate);
              widget.timeChanged(newTime);
            },
          )
        ],
      ),
    );
  }
}
