import 'dart:async';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_tutorial/model/polyline_response.dart';
import 'package:google_maps_flutter_tutorial/screens/polyline_screen.dart';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class PickDestinationScreen extends StatefulWidget {
  const PickDestinationScreen({Key? key}) : super(key: key);

  @override
  State<PickDestinationScreen> createState() => _PickDestinationScreenState();
}

class _PickDestinationScreenState extends State<PickDestinationScreen> {
  TextEditingController origin2 = TextEditingController();
  TextEditingController destination2 = TextEditingController();
  var uuid = Uuid();
  String _sessionToken = "11223344";
  List<dynamic> placeslistForOrigin = [];
  List<dynamic> placeslistForDestination = [];

  double originLat = 0;
  double originLon = 0;
  double destinationLat = 0;
  double destinationLon = 0;

  bool _isVisibleOrigin = true;
  bool _isVisibleDestination = true;

  @override
  void initState() {
    super.initState();

    origin2.addListener(() {
      onChangeForOrigin();
    });
    destination2.addListener(() {
      onChangeForDestination();
    });
  }

  void onChangeForOrigin() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    } else {
      getSuggestionForOrigin(origin2.text);
    }
  }

  void onChangeForDestination() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    } else {
      getSuggestionForDestination(destination2.text);
    }
  }

  void getSuggestionForOrigin(String input) async {
    String api_key = "AIzaSyDXibIT6OM73j0eT_xd28hi-B59puQnT04";
    String request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$api_key&sessiontoken=$_sessionToken';
    var response = await http.get(Uri.parse(request));
    var data = response.body.toString();

    if (response.statusCode == 200) {
      setState(() {
        placeslistForOrigin =
            jsonDecode(response.body.toString())["predictions"];
      });
    } else {
      throw Exception("getsuggestion failed");
    }
  }

  void getSuggestionForDestination(String input) async {
    String api_key = "AIzaSyDXibIT6OM73j0eT_xd28hi-B59puQnT04";
    String request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$api_key&sessiontoken=$_sessionToken';
    var response = await http.get(Uri.parse(request));
    var data = response.body.toString();
    if (response.statusCode == 200) {
      setState(() {
        placeslistForDestination =
            jsonDecode(response.body.toString())["predictions"];
      });
    } else {
      throw Exception("getsuggestion failed");
    }
  }

  CameraPosition initialPosition =
      CameraPosition(target: LatLng(41.0082, 28.9784), zoom: 14);

  final Completer<GoogleMapController> _controller = Completer();

  String totalDistance = "";
  String totalTime = "";

  String apiKey = "AIzaSyDXibIT6OM73j0eT_xd28hi-B59puQnT04";

  PolylineResponse polylineResponse = PolylineResponse();

  Set<Polyline> polylinePoints = {};

  void onTapDestination(int index) async {
    List<Location> locations = await locationFromAddress(
        placeslistForDestination[index]['description']);
    destination2.text = placeslistForDestination[index]['description'];
    destinationLon = locations.last.longitude;
    destinationLat = locations.last.latitude;
    print("baskent::Long: ${locations.last.longitude}");
    print("baskent::Lat: ${locations.last.latitude}");
    setState(() {
      _isVisibleDestination = false;
    });
  }

  void onTapOrigin(int index) async {
    List<Location> locations =
        await locationFromAddress(placeslistForOrigin[index]['description']);
    origin2.text = placeslistForOrigin[index]['description'];

    setState(() {
      originLon = locations.last.longitude;
      originLat = locations.last.latitude;
    });
    GoogleMapController controller = await _controller.future;
    CameraPosition position = CameraPosition(
      target: LatLng(originLat, originLon),
      zoom: 14,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(position));
    setState(() {
      _isVisibleOrigin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        TextFormField(
          onChanged: (value) {
            if (value == "" || value == null) {
              _isVisibleOrigin = false;
            } else {
              _isVisibleOrigin = true;
            }
          },
          controller: origin2,
          decoration: InputDecoration(hintText: "origin"),
        ),
        Expanded(
            child: ListView.builder(
          itemCount: placeslistForOrigin.length,
          itemBuilder: (context, index) {
            return Visibility(
              visible: _isVisibleOrigin,
              child: ListTile(
                onTap: () async {
                  onTapOrigin(index);
                },
                title: Text(placeslistForOrigin[index]['description']),
              ),
            );
          },
        )),
        TextFormField(
          onChanged: (value) {
            if (value == "" || value == null) {
              _isVisibleDestination = false;
            } else {
              _isVisibleDestination = true;
            }
          },
          controller: destination2,
          decoration: InputDecoration(hintText: "destination"),
        ),
        Expanded(
            child: ListView.builder(
          itemCount: placeslistForDestination.length,
          itemBuilder: (context, index) {
            return Visibility(
              visible: _isVisibleDestination,
              child: ListTile(
                onTap: () async {
                  onTapDestination(index);
                },
                title: Text(placeslistForDestination[index]['description']),
              ),
            );
          },
        )),
        ElevatedButton(
            onPressed: () {
              if (origin2.text == "" || destination2.text == "") {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Please input  all the fields"),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PolylineScreen(
                              originLat: originLat,
                              originLon: originLon,
                              destinationLat: destinationLat,
                              destinationLon: destinationLon,
                            )));
              }
            },
            child: Text("click me"))
      ]),
    );
  }
}
