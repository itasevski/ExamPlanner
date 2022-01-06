import 'package:examplanner/secrets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyLocation extends StatefulWidget {
  final String homeLocationKey;
  final String homeLatitudeKey;
  final String homeLongitudeKey;

  const MyLocation(
      this.homeLocationKey, this.homeLatitudeKey, this.homeLongitudeKey);

  @override
  State<StatefulWidget> createState() {
    return _MyLocationState(
        this.homeLocationKey, this.homeLatitudeKey, this.homeLongitudeKey);
  }
}

class _MyLocationState extends State<MyLocation> {
  static const googleApiKey = Secrets.googleApiKey; // YOUR GOOGLE API KEY HERE

  String homeLocationKey;
  String homeLatitudeKey;
  String homeLongitudeKey;

  String? _homeLocation = 'Unknown';

  GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: googleApiKey);

  _MyLocationState(
      this.homeLocationKey, this.homeLatitudeKey, this.homeLongitudeKey);

  Future<Map> _init() async {
    final preferences = await SharedPreferences.getInstance();
    final result = {
      'homeLocation': preferences.getString(homeLocationKey) ?? 'Unknown',
    };
    return result;
  }

  @override
  void initState() {
    super.initState();

    _init().then((result) {
      setState(() {
        _homeLocation = result['homeLocation'];
      });
    });
  }

  Future<void> addHomeLocation(Prediction? p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await places.getDetailsByPlaceId(p.placeId.toString());

      double? inputLat = detail.result.geometry?.location.lat;
      double? inputLng = detail.result.geometry?.location.lng;

      Position pos = await _determineCurrentPosition();

      print("Current location: " +
          pos.latitude.toString() +
          " ; " +
          pos.longitude.toString());
      print("Input location: " +
          inputLat.toString() +
          " ; " +
          inputLng.toString());

      double distance = Geolocator.distanceBetween(
          inputLat!, inputLng!, pos.latitude, pos.longitude);

      print("Distance between the two locations: " +
          distance.toString() +
          " metres.");

      setState(() {
        _homeLocation = p.description.toString();
      });

      final preferences = await SharedPreferences.getInstance();

      preferences.setString(homeLocationKey, p.description.toString());
      preferences.setDouble(homeLatitudeKey, inputLat);
      preferences.setDouble(homeLongitudeKey, inputLng);
    }
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

  void _clearData() async {
    final preferences = await SharedPreferences.getInstance();

    preferences.remove(homeLocationKey);
    preferences.remove(homeLatitudeKey);
    preferences.remove(homeLongitudeKey);

    setState(() {
      _homeLocation = "Unknown";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Select location", style: TextStyle(fontSize: 23))),
        body: Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                  child: Text("Click to add your home location",
                      style: TextStyle(fontSize: 18)),
                  onPressed: () async {
                    Prediction? p = await PlacesAutocomplete.show(
                        strictbounds: false,
                        region: "mk",
                        language: "en",
                        context: context,
                        mode: Mode.overlay,
                        apiKey: googleApiKey,
                        sessionToken: "tokenxyz",
                        components: [new Component(Component.country, "mk")],
                        types: ["address"],
                        hint: "Input your home street address");

                    await addHomeLocation(p);
                  }),
              _homeLocation != "Unknown"
                  ? Text("Current set home location: " + _homeLocation!,
                      style: TextStyle(fontSize: 17))
                  : Text(""),
              _homeLocation != "Unknown"
                  ? TextButton(child: Text("CLEAR"), onPressed: _clearData)
                  : Text("")
            ],
          ),
        ));
  }
}
