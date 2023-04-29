import 'dart:async';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_tutorial/model/nearby_response.dart';
import 'package:google_maps_flutter_tutorial/model/polyline_response.dart';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class PolylineScreen extends StatefulWidget {
  const PolylineScreen({Key? key}) : super(key: key);

  @override
  State<PolylineScreen> createState() => _PolylineScreenState();
}

class _PolylineScreenState extends State<PolylineScreen> {
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

  LatLng origin = const LatLng(41.0082, 28.9784);
  LatLng destination = const LatLng(41.0144, 28.9674);

  PolylineResponse polylineResponse = PolylineResponse();

  Set<Polyline> polylinePoints = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Polyline"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            polylines: polylinePoints,
            zoomControlsEnabled: false,
            initialCameraPosition: initialPosition,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            //color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Total Distance: " + totalDistance),
                Text("Total Time: " + totalTime),
                TextFormField(
                  controller: origin2,
                  decoration: InputDecoration(hintText: "origin"),
                ),
                Expanded(
                    child: ListView.builder(
                  itemCount: placeslistForOrigin.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () async {
                        List<Location> locations = await locationFromAddress(
                            placeslistForOrigin[index]['description']);
                        origin2.text =
                            placeslistForOrigin[index]['description'];
                        
                        setState(() {
                          originLon = locations.last.longitude;
                          originLat = locations.last.latitude;
                        });
                        GoogleMapController controller =
                            await _controller.future;
                        CameraPosition position = CameraPosition(
                          target: LatLng(originLat, originLon),
                          zoom: 14,
                        );
                        controller.animateCamera(
                            CameraUpdate.newCameraPosition(position));
                      },
                      title: Text(placeslistForOrigin[index]['description']),
                    );
                  },
                )),
                TextFormField(
                  controller: destination2,
                  decoration: InputDecoration(hintText: "destination"),
                ),
                Expanded(
                    child: ListView.builder(
                  itemCount: placeslistForDestination.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () async {
                        List<Location> locations = await locationFromAddress(
                            placeslistForDestination[index]['description']);
                        destination2.text =
                            placeslistForDestination[index]['description'];
                        destinationLon = locations.last.longitude;
                        destinationLat = locations.last.latitude;
                      },
                      title:
                          Text(placeslistForDestination[index]['description']),
                    );
                  },
                )),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          drawPolyline(originLat, originLon, destinationLat, destinationLon);
        },
        child: const Icon(Icons.directions),
      ),
    );
  }

  void drawPolyline(double originLat, double originLon, double destinationLat,
      double destinationLon) async {
    initialPosition =
        CameraPosition(target: LatLng(originLat, originLon), zoom: 14);

    var response = await http.post(Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?key=" +
            apiKey +
            "&units=metric&origin=" +
            originLat.toString() +
            "," +
            originLon.toString() +
            "&destination=" +
            destinationLat.toString() +
            "," +
            destinationLon.toString() +
            "&mode=driving"));

    polylineResponse = PolylineResponse.fromJson(jsonDecode(response.body));

    totalDistance = polylineResponse.routes![0].legs![0].distance!.text!;
    totalTime = polylineResponse.routes![0].legs![0].duration!.text!;

    for (int i = 0;
        i < polylineResponse.routes![0].legs![0].steps!.length;
        i++) {
      polylinePoints.add(Polyline(
          polylineId: PolylineId(
              polylineResponse.routes![0].legs![0].steps![i].polyline!.points!),
          points: [
            LatLng(
                polylineResponse
                    .routes![0].legs![0].steps![i].startLocation!.lat!,
                polylineResponse
                    .routes![0].legs![0].steps![i].startLocation!.lng!),
            LatLng(
                polylineResponse
                    .routes![0].legs![0].steps![i].endLocation!.lat!,
                polylineResponse
                    .routes![0].legs![0].steps![i].endLocation!.lng!)
          ],
          width: 3,
          color: Colors.red));
    }

    setState(() {});
  }
  
}
