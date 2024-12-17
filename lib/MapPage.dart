// MapPage.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;

class MapPage extends StatelessWidget {
  final double lat;
  final double lng;

  const MapPage({Key? key, required this.lat, required this.lng}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shopLocation = latLng.LatLng(lat, lng);
    final marker = Marker(
      point: shopLocation,
      width: 80,
      height: 80,
      child:  const Icon(
        Icons.location_on,
        color: Colors.red,
        size: 40,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Location'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: shopLocation,
          initialZoom: 19.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [marker],
          ),
        ],
      ),
    );
  }
}
