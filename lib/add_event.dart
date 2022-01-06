import 'package:examplanner/secrets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_maps_webservice/places.dart';

import 'datetime_picker.dart';
import 'exam_planner.dart';

class AddEvent extends StatefulWidget {
  final EventAddCallback callback;

  const AddEvent(this.callback);

  @override
  State<StatefulWidget> createState() {
    return _AddEventState(this.callback);
  }
}

class _AddEventState extends State<AddEvent> {
  final _formKey = GlobalKey<FormState>();

  GoogleMapsPlaces places = GoogleMapsPlaces(
      apiKey: Secrets.googleApiKey); // YOUR GOOGLE API KEY HERE

  final eventNameController = TextEditingController();
  final locationNameController = TextEditingController();

  DateTime eventDate = DateTime.now();
  String formattedDate = "";
  TimeOfDay eventTime = TimeOfDay.now();
  String formattedTime = "";

  String locationName = "";
  double locationLatitude = 0.000;
  double locationLongitude = 0.000;

  EventAddCallback callback;

  _AddEventState(this.callback);

  void _process() {
    if (_formKey.currentState!.validate()) {
      callback(eventNameController.text, formattedDate + " " + formattedTime,
          locationName, locationLatitude, locationLongitude);

      setState(() {
        eventNameController.text = "";
        locationNameController.text = "";
        eventDate = DateTime.now();
        eventTime = TimeOfDay.now();
        formattedDate = intl.DateFormat('dd/MM/yyyy').format(eventDate);
        formattedTime = eventTime.format(context);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event successfully added.')),
      );
    }
  }

  Future<void> _setupEventPlace(Prediction? p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await places.getDetailsByPlaceId(p.placeId.toString());

      double? inputLat = detail.result.geometry?.location.lat;
      double? inputLng = detail.result.geometry?.location.lng;

      setState(() {
        locationName = p.description.toString();
        locationNameController.value = TextEditingValue(
          text: locationName,
          selection: TextSelection.fromPosition(
            TextPosition(offset: locationName.length),
          ),
        );
        locationLatitude = inputLat!;
        locationLongitude = inputLng!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add event", style: TextStyle(fontSize: 23))),
      body: Container(
        margin: EdgeInsets.only(top: 25),
        child: Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                controller: eventNameController,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.article_outlined),
                  hintText: 'Enter event name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Event name can't be empty";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: locationNameController,
                decoration: InputDecoration(
                  icon: const Icon(Icons.location_city),
                  hintText: 'Click the button to select a place',
                  suffixIcon: IconButton(
                      icon: Icon(Icons.add_location),
                      onPressed: () async {
                        Prediction? p = await PlacesAutocomplete.show(
                            strictbounds: false,
                            region: "mk",
                            language: "en",
                            context: context,
                            mode: Mode.overlay,
                            apiKey: Secrets.googleApiKey,
                            sessionToken: "tokenvic",
                            components: [
                              new Component(Component.country, "mk")
                            ],
                            types: [""],
                            hint: "Search for a place");

                        await _setupEventPlace(p);
                      }),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Event name can't be empty";
                  }
                  return null;
                },
              ),
              FormDateTimePicker(
                  date: eventDate,
                  time: eventTime,
                  dateChanged: (value) {
                    setState(() {
                      eventDate = value;
                      formattedDate =
                          intl.DateFormat('dd/MM/yyyy').format(eventDate);
                    });
                  },
                  timeChanged: (value) {
                    setState(() {
                      eventTime = value;
                      formattedTime = eventTime.format(context);
                    });
                  }),
              Container(
                margin: EdgeInsets.only(top: 15),
                child: ElevatedButton(
                    child: const Text('Submit', style: TextStyle(fontSize: 18)),
                    onPressed: (locationLatitude != 0.000 ||
                            locationLongitude != 0.000)
                        ? _process
                        : null),
              )
            ])),
      ),
    );
  }
}
