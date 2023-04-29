import 'dart:async';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_tutorial/model/polyline_response.dart';
  
import 'package:http/http.dart' as http;

class PolylineScreen extends StatefulWidget {
  final double originLat;
  final double originLon;
  final double destinationLat;
  final double destinationLon;

  const PolylineScreen({
    Key? key,
    required this.originLat,
    required this.originLon,
    required this.destinationLat,
    required this.destinationLon,
  }) : super(key: key);
  @override
  State<PolylineScreen> createState() => _PolylineScreenState();
}

class _PolylineScreenState extends State<PolylineScreen> {
  @override
  void initState() {
    super.initState();

    final originLat = widget.originLat;
    final originLon = widget.originLon;
    final destinationLat = widget.destinationLat;
    final destinationLon = widget.destinationLon;
    drawPolyline(originLat, originLon, destinationLat, destinationLon);
  }

  CameraPosition initialPosition =
      CameraPosition(target: LatLng(41.0082, 28.9784), zoom: 14);

  final Completer<GoogleMapController> _controller = Completer();

  String totalDistance = "";

  String totalTime = "";

  String apiKey = "AIzaSyDXibIT6OM73j0eT_xd28hi-B59puQnT04";

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
            onMapCreated: (GoogleMapController controller) async {
              _controller.complete(controller);
              drawPolyline(widget.originLat, widget.originLon,
                  widget.destinationLat, widget.destinationLon);
                  controller.animateCamera(CameraUpdate.newLatLng(LatLng(widget.originLat, widget.originLon)));

            },
          ),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Total Distance: " + totalDistance),
                Text("Total Time: " + totalTime),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void drawPolyline(double originLat, double originLon, double destinationLat,
      double destinationLon) async {
    LatLng origin = LatLng(originLat, originLon);
    print("huhu:${origin}");
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

    String distance = polylineResponse.routes![0].legs![0].distance!.text!;
    String time = polylineResponse.routes![0].legs![0].duration!.text!;
    print("totaldistance:${distance}");
    print("totalTime:${time}");

    setState(() {
      totalDistance = distance;
      totalTime = time;
      initialPosition = CameraPosition(target: origin, zoom: 14);
    });

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
  }
}
