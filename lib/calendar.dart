import 'package:examplanner/exam_planner.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatefulWidget {
  final CalendarCallback callback;

  const Calendar(this.callback);

  @override
  State<StatefulWidget> createState() {
    return _CalendarState(callback);
  }
}

class _CalendarState extends State<Calendar> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late ValueNotifier<List<String>> _selectedObligations;

  CalendarCallback callback;

  _CalendarState(this.callback);

  @override
  void initState() {
    super.initState();

    _selectedObligations = ValueNotifier(_getObligationsForDay(DateTime.now()));
  }

  List<String> _getObligationsForDay(DateTime day) {
    return callback(day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Calendar", style: TextStyle(fontSize: 23))),
        body: Column(
          children: [
            TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: DateTime.now(),
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedObligations.value =
                          _getObligationsForDay(selectedDay);
                    });
                  }
                },
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                  return _getObligationsForDay(
                      day); // ako za nekoj den od kalendarot se vrati lista cij size > 0, go markira denot vo kalendarot (ima exam/s na toj den).
                }),
            const SizedBox(height: 8.0),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _selectedObligations,
                builder: (context, value, _) {
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          onTap: () => print(value[index]),
                          title: Text(value[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ));
  }
}
