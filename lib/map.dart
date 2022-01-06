import 'dart:async';

import 'package:examplanner/secrets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as pp;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

class MyMap extends StatefulWidget {
  final double currentLatitude;
  final double currentLongitude;

  const MyMap(this.currentLatitude, this.currentLongitude);

  @override
  State<StatefulWidget> createState() {
    return _MyMapState(this.currentLatitude, this.currentLongitude);
  }
}

class _MyMapState extends State<MyMap> {
  // google variables
  static const googleApiKey = Secrets.googleApiKey; // YOUR GOOGLE API KEY HERE

  // current position variables
  double currentLatitude;
  double currentLongitude;

  // destination variables
  String _destinationPlace = "";
  double _destinationLatitude = 0.000;
  double _destinationLongitude = 0.000;
  double distance = 0.000;

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

  _MyMapState(this.currentLatitude, this.currentLongitude);

  @override
  void initState() {
    super.initState();

    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;

    _kGooglePlex = CameraPosition(
      target: LatLng(currentLatitude, currentLongitude),
      tilt: 59,
      zoom: 14,
    );

    _addCurrentLocationMarker();
    _initVariables();
  }

  void _addCurrentLocationMarker() {
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

  Future<void> _setupDestinationPlace(Prediction? p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await places.getDetailsByPlaceId(p.placeId.toString());

      double? inputLat = detail.result.geometry?.location.lat;
      double? inputLng = detail.result.geometry?.location.lng;

      setState(() {
        _destinationPlace = p.description.toString();
        destinationPlaceController.value = TextEditingValue(
          text: _destinationPlace,
          selection: TextSelection.fromPosition(
            TextPosition(offset: _destinationPlace.length),
          ),
        );
        _destinationLatitude = inputLat!;
        _destinationLongitude = inputLng!;
      });

      if (markers.length > 1) {
        setState(() {
          markers.remove(markers.last);
        });
      }
      setState(() {
        markers.add(Marker(
          //add first marker
          markerId: MarkerId("Destination location marker"),
          position: LatLng(inputLat!, inputLng!), //position of marker
          infoWindow: InfoWindow(
            //popup info
            title: p.description.toString(),
            snippet: inputLat.toString() + " " + inputLng.toString(),
          ),
          icon: BitmapDescriptor.defaultMarker, //Icon for Marker
        ));
      });
    }
  }

  void _createPolyline() async {
    setState(() {
      polyline = Polyline(polylineId: PolylineId("null"));
      polylineCoordinates = [];
    });

    pp.PolylinePoints polylinePoints = pp.PolylinePoints();
    PolylineId polylineId = PolylineId("destination");

    pp.PolylineResult polylineResult =
        await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      pp.PointLatLng(currentLatitude, currentLongitude),
      pp.PointLatLng(_destinationLatitude, _destinationLongitude),
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

    double finalDistance = Geolocator.distanceBetween(currentLatitude,
        currentLongitude, _destinationLatitude, _destinationLongitude);

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
      if (markers.length > 1) {
        markers.remove(markers.last);
      }
      _destinationPlace = "";
      destinationPlaceController.value = TextEditingValue(
        text: _destinationPlace,
        selection: TextSelection.fromPosition(
          TextPosition(offset: _destinationPlace.length),
        ),
      );
      _destinationLatitude = 0.000;
      _destinationLongitude = 0.000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(title: Text("Map viewer", style: TextStyle(fontSize: 23))),
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
                          _textField(
                              label: 'Destination',
                              hint: 'Click button for destination',
                              prefixIcon: Icon(Icons.looks_two),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.add_location),
                                onPressed: () async {
                                  Prediction? p = await PlacesAutocomplete.show(
                                      strictbounds: false,
                                      region: "mk",
                                      language: "en",
                                      context: context,
                                      mode: Mode.overlay,
                                      apiKey: googleApiKey,
                                      sessionToken: "tokencux",
                                      components: [
                                        new Component(Component.country, "mk")
                                      ],
                                      types: [""],
                                      hint: "Search for a place");

                                  await _setupDestinationPlace(p);
                                },
                              ),
                              controller: destinationPlaceController,
                              width: MediaQuery.of(context).size.width,
                              isEnabled: true),
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
                                  onPressed: markers.length <= 1
                                      ? null
                                      : _createPolyline),
                              SizedBox(width: 25),
                              ElevatedButton(
                                  child: Text("Clear"),
                                  onPressed: markers.length <= 1
                                      ? null
                                      : _clearMapData),
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
