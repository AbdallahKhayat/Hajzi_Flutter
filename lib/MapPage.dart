import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatelessWidget {
  final double lat;
  final double lng;

  const MapPage({Key? key, required this.lat, required this.lng}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LatLng shopLocation = LatLng(lat, lng);
    final Marker marker = Marker(
      markerId: const MarkerId('shopLocation'),
      position: shopLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Location'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: shopLocation,
          zoom: 19.0,
        ),
        markers: {marker},
      ),
    );
  }
}
