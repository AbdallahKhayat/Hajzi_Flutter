import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latLng;

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({Key? key}) : super(key: key);

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  latLng.LatLng? selectedLocation;
  final latLng.LatLng defaultCenter = latLng.LatLng(32.22111, 35.25444);
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  List<dynamic> searchResults = [];
  int currentIndex = 0;

  Future<void> _searchShops(String query) async {
    if (query.isEmpty) return;
    final url = Uri.parse("https://nominatim.openstreetmap.org/search?format=json&countrycodes=ps&q=$query");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        searchResults = data;
        currentIndex = 0;
        _showResultAtIndex(currentIndex);
      } else {
        searchResults.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results found in Palestine')),
        );
      }
    } else {
      searchResults.clear();
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
      selectedLocation = latLng.LatLng(lat, lon);
    });
    _mapController.move(selectedLocation!, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    if (selectedLocation != null) {
      markers.add(
        Marker(
          point: selectedLocation!,
          width: 80,
          height: 80,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Shop Location"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchShops,
              decoration: InputDecoration(
                hintText: 'Search for a shop',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchShops(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: defaultCenter,
                initialZoom: 12.0,
                onTap: (tapPosition, latLngValue) {
                  setState(() {
                    selectedLocation = latLngValue;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: markers,
                ),
              ],
            ),
          ),
          if (searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: currentIndex > 0
                        ? () {
                      setState(() {
                        currentIndex--;
                      });
                      _showResultAtIndex(currentIndex);
                    }
                        : null,
                    child: const Icon(Icons.arrow_back),
                  ),
                  Text("Result ${currentIndex + 1} of ${searchResults.length}"),
                  ElevatedButton(
                    onPressed: currentIndex < searchResults.length - 1
                        ? () {
                      setState(() {
                        currentIndex++;
                      });
                      _showResultAtIndex(currentIndex);
                    }
                        : null,
                    child: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          if (selectedLocation != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, selectedLocation);
                },
                icon: const Icon(Icons.check,color: Colors.black,),
                label: const Text("Confirm Location",style: TextStyle(
                  color: Colors.black
                ),),
              ),
            ),
        ],
      ),
    );
  }
}
