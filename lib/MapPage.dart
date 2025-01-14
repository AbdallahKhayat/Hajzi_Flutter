import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MapPage extends StatelessWidget {
  final double lat;
  final double lng;

  const MapPage({Key? key, required this.lat, required this.lng})
      : super(key: key);

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
        title: Text(
          AppLocalizations.of(context)!.shopLocation,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: ValueListenableBuilder<Color>(
          valueListenable: appColorNotifier,
          builder: (context, appColor, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColor.withOpacity(1), appColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),
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
