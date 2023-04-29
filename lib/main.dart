import 'package:flutter/material.dart';
import 'package:google_maps_flutter_tutorial/home_screen.dart';
import 'package:google_maps_flutter_tutorial/screens/pick_destination_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PickDestinationScreen(),
    );
  }
}
