import 'dart:async';

import 'package:examplanner/secrets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as pp;

class MyEventMap extends StatefulWidget {
  final double currentLatitude;
  final double currentLongitude;
  final List<dynamic> events;

  const MyEventMap(this.currentLatitude, this.currentLongitude, this.events);

  @override
  State<StatefulWidget> createState() {
    return _MyEventMapState(
        this.currentLatitude, this.currentLongitude, this.events);
  }
}

class _MyEventMapState extends State<MyEventMap> {
  static const googleApiKey = Secrets.googleApiKey; // YOUR GOOGLE API KEY HERE

  // event variables
  List<dynamic> events;
  double distance = 0.000;
  String selectedEvent = "";
  List<String> eventPlaces = [];

  // current position variables
  double currentLatitude;
  double currentLongitude;

  // start and destination points TextField controllers
  final startPlaceController = TextEditingController();
  final destinationPlaceController = TextEditingController();

  // Google Places configuration
  GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: googleApiKey);

  // Google Maps configuration
  Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> markers = new Set();
  CameraPosition _kGooglePlex = CameraPosition(target: LatLng(0.000, 0.000));
  Polyline polyline = Polyline(polylineId: PolylineId("null"));
  List<LatLng> polylineCoordinates = [];

  _MyEventMapState(this.currentLatitude, this.currentLongitude, this.events);

  @override
  void initState() {
    super.initState();

    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;

    _kGooglePlex = CameraPosition(
      target: LatLng(currentLatitude, currentLongitude),
      tilt: 59,
      zoom: 14,
    );

    _addMarkers();
    _initVariables();
  }

  void _addMarkers() {
    markers.add(Marker(
      //add first marker
      markerId: MarkerId("Current location marker"),
      position: LatLng(currentLatitude, currentLongitude), //position of marker
      infoWindow: InfoWindow(
        //popup info
        title: 'Current location',
        snippet: currentLatitude.toString() + " " + currentLongitude.toString(),
      ),
      icon: BitmapDescriptor.defaultMarker, //Icon for Marker
    ));

    for (int i = 0; i < events.length; i++) {
      markers.add(Marker(
        //add first marker
        markerId: MarkerId(events[i]["locationName"] + " marker"),
        position: LatLng(
            events[i]["locationLatitude"], events[i]["locationLongitude"]),
        //position of marker
        infoWindow: InfoWindow(
          //popup info
          title: events[i]["locationName"],
          snippet: events[i]["locationLatitude"].toString() +
              " " +
              events[i]["locationLongitude"].toString(),
        ),
        icon: BitmapDescriptor.defaultMarker, //Icon for Marker
      ));
    }
  }

  void _initVariables() {
    String startPlaceControllerValue = "Current (" +
        currentLatitude.toString() +
        ", " +
        currentLongitude.toString() +
        ")";
    startPlaceController.value = TextEditingValue(
      text: startPlaceControllerValue,
      selection: TextSelection.fromPosition(
        TextPosition(offset: startPlaceControllerValue.length),
      ),
    );

    selectedEvent = events[0]["locationName"];

    for (int i = 0; i < events.length; i++) {
      eventPlaces.add(events[i]["locationName"]);
    }
  }

  void _currentLocation() async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        bearing: 0,
        target: LatLng(currentLatitude, currentLongitude),
        zoom: 17.0,
      ),
    ));
  }

  dynamic _getSelectedPlaceInformation() {
    print(selectedEvent);
    for (int i = 0; i < events.length; i++) {
      if (events[i]["locationName"] == selectedEvent) {
        print(events[i]);
        return events[i];
      }
    }
  }

  void _createPolyline() async {
    setState(() {
      polyline = Polyline(polylineId: PolylineId("null"));
      polylineCoordinates = [];
      distance = 0.000;
    });

    pp.PolylinePoints polylinePoints = pp.PolylinePoints();
    PolylineId polylineId = PolylineId("Current --> " + selectedEvent);

    dynamic selectedPlaceInformation = _getSelectedPlaceInformation();

    pp.PolylineResult polylineResult =
        await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      pp.PointLatLng(currentLatitude, currentLongitude),
      pp.PointLatLng(selectedPlaceInformation["locationLatitude"],
          selectedPlaceInformation["locationLongitude"]),
      travelMode: pp.TravelMode.transit,
    );

    if (polylineResult.points.isNotEmpty) {
      polylineResult.points.forEach((pp.PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    Polyline finalPolyline = Polyline(
      polylineId: polylineId,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );

    double finalDistance = Geolocator.distanceBetween(
        currentLatitude,
        currentLongitude,
        selectedPlaceInformation["locationLatitude"],
        selectedPlaceInformation["locationLongitude"]);

    setState(() {
      polyline = finalPolyline;
      distance = finalDistance;
    });
  }

  void _clearMapData() {
    setState(() {
      polyline = Polyline(polylineId: PolylineId("null"));
      polylineCoordinates = [];
      distance = 0.000;
      selectedEvent = events[0]["locationName"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Event map viewer", style: TextStyle(fontSize: 23))),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.my_location),
          onPressed: _currentLocation,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Stack(
          children: [
            GoogleMap(
              polylines: <Polyline>{polyline},
              markers: markers,
              mapType: MapType.normal,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Places',
                            style: TextStyle(fontSize: 20.0),
                          ),
                          SizedBox(height: 10),
                          _textField(
                              label: 'Start',
                              hint: '',
                              prefixIcon: Icon(Icons.looks_one),
                              controller: startPlaceController,
                              width: MediaQuery.of(context).size.width,
                              isEnabled: false),
                          SizedBox(height: 10),
                          Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedEvent,
                                icon: const Icon(Icons.arrow_downward),
                                elevation: 16,
                                style:
                                    const TextStyle(color: Colors.deepPurple),
                                underline: Container(
                                  height: 2,
                                  color: Colors.deepPurpleAccent,
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedEvent = newValue!;
                                  });
                                },
                                items: eventPlaces
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              )),
                          SizedBox(height: 5),
                          distance == 0.000
                              ? Text("")
                              : Text(
                                  "Calculated distance: " +
                                      distance.toStringAsFixed(1) +
                                      " meters",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                  child: Text("Calculate route"),
                                  onPressed: _createPolyline),
                              SizedBox(width: 25),
                              ElevatedButton(
                                  child: Text("Clear"),
                                  onPressed: polyline.polylineId.value != "null"
                                      ? _clearMapData
                                      : null),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Widget _textField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      required double width,
      required Icon prefixIcon,
      Widget? suffixIcon,
      required bool isEnabled}) {
    return Container(
      width: width * 0.8,
      child: TextField(
        enabled: isEnabled,
        controller: controller,
        decoration: new InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }
}
