import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constants.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({Key? key}) : super(key: key);

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  LatLng? selectedLocation;
  final LatLng defaultCenter = const LatLng(32.22111, 35.25444);
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  List<dynamic> searchResults = [];
  int currentIndex = 0;
  Set<Marker> markers = {};
  bool _isLocationConfirmed = false;

  // Function to get the user's current location
  Future<void> _goToCurrentLocation() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    _locationData = await location.getLocation();

    LatLng currentLatLng =
        LatLng(_locationData.latitude!, _locationData.longitude!);

    setState(() {
      selectedLocation = currentLatLng;
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('selectedLocation'),
          position: selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLatLng, 14.0),
    );
  }

  Future<void> _searchShops(String query) async {
    if (query.isEmpty) return;
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?format=json&countrycodes=ps&q=$query");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        setState(() {
          searchResults = data;
          currentIndex = 0;
        });
        _showResultAtIndex(currentIndex);
      } else {
        setState(() {
          searchResults.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results found in Palestine')),
        );
      }
    } else {
      setState(() {
        searchResults.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching results')),
      );
    }
  }

  void _showResultAtIndex(int index) {
    if (index < 0 || index >= searchResults.length) return;
    final result = searchResults[index];
    final double lat = double.tryParse(result['lat']) ?? 0.0;
    final double lon = double.tryParse(result['lon']) ?? 0.0;
    setState(() {
      selectedLocation = LatLng(lat, lon);
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('selectedLocation'),
          position: selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(selectedLocation!, 14.0),
    );
  }

  Future<void> _openInGoogleMaps() async {
    if (selectedLocation != null) {
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${selectedLocation!.latitude},${selectedLocation!.longitude}';
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select Shop Location",
          style: TextStyle(fontWeight: FontWeight.bold),
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.my_location,
              color: Colors.black,
            ),
            onPressed: _goToCurrentLocation,
            tooltip: 'Go to Current Location',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onSubmitted: _searchShops,
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<Color>(
                  valueListenable: appColorNotifier,
                  builder: (context, appColor, child) {
                    return ElevatedButton(
                      onPressed: () {
                        _searchShops(_searchController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColor, // Dynamic background color
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: defaultCenter,
                    zoom: 12.0,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (LatLng position) {
                    setState(() {
                      selectedLocation = position;
                      markers.clear();
                      markers.add(
                        Marker(
                          markerId: const MarkerId('selectedLocation'),
                          position: position,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed),
                        ),
                      );
                    });
                  },
                  markers: markers,
                  myLocationEnabled: true,
                ),
                if (searchResults.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: currentIndex > 0
                              ? () {
                                  setState(() {
                                    currentIndex--;
                                  });
                                  _showResultAtIndex(currentIndex);
                                }
                              : null,
                        ),
                        Text(
                            "Result ${currentIndex + 1} of ${searchResults.length}"),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: currentIndex < searchResults.length - 1
                              ? () {
                                  setState(() {
                                    currentIndex++;
                                  });
                                  _showResultAtIndex(currentIndex);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                if (selectedLocation != null)
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: FractionallySizedBox(
                      widthFactor: 0.6,
                      // Adjust this to control the button width (80% of screen width)
                      child: ElevatedButton.icon(
                        onPressed: _openInGoogleMaps,
                        icon: const Icon(Icons.map, color: Colors.black),
                        label: const Text(
                          "Open in Google Maps",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    // Adjust this to control the button width (80% of screen width)
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_isLocationConfirmed) return;
                        Navigator.pop(context, selectedLocation);
                      },
                      icon: const Icon(Icons.check, color: Colors.black),
                      label: const Text(
                        "Confirm Location",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
