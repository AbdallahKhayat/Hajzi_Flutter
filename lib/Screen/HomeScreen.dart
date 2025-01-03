import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Blog/Blogs.dart';

class HomeScreen extends StatefulWidget {
  final int filterState;

  const HomeScreen({super.key, required this.filterState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  String? userRole;
  String? lastClickedStoreType;
  String _searchQuery = ''; // We'll manage the search text here

  bool get hasRecommendations {
    // If lastClickedStoreType is null, empty, or 'none', we consider that "no recommendations yet"
    if (lastClickedStoreType == null ||
        lastClickedStoreType!.isEmpty ||
        lastClickedStoreType == 'none') {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadLastClickedStoreType();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await storage.read(key: "role");
      if (mounted) {
        setState(() {
          userRole = role;
        });
      }
    } catch (e) {
      debugPrint("Error reading user role: $e");
    }
  }

  Future<void> _loadLastClickedStoreType() async {
    try {
      final type = await storage.read(key: "lastClickedStoreType");
      if (mounted) {
        setState(() {
          lastClickedStoreType = type;
        });
      }
    } catch (e) {
      debugPrint("Error reading lastClickedStoreType: $e");
    }
  }

  /// Your original filter-based URL logic
  String _getUrlForFilterState() {
    switch (widget.filterState) {
      case 1:
        return "/blogpost/getBarberBlogs";
      case 2:
        return "/blogpost/getHospitalBlogs";
      default:
        return "/blogpost/getBlogs";
    }
  }

  /// Recommendation-based URL logic
  String _getUrlForRecommendation() {
    switch (lastClickedStoreType) {
      case 'barbershop':
        return "/blogpost/getBarberBlogs";
      case 'hospital':
        return "/blogpost/getHospitalBlogs";
      case 'restaurant':
        return "/blogpost/getRestaurantBlogs";
      // Extend with more store types if needed
      default:
        // If no recommendation type is found, use a default
        return "/blogpost/getBlogs";
    }
  }

  @override
  Widget build(BuildContext context) {
    // If user role not yet loaded, show a loading spinner
    if (userRole == null) {
      return const Scaffold(
        backgroundColor: Color(0xffe9f7ef),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffe9f7ef),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============ SINGLE SEARCH BAR AT THE TOP ============ //
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Shops',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // ============ RECOMMENDATIONS SECTION ============ //
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Recommendations",
                style: kIsWeb
                    ? TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)
                    : TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
              ),
            ),
            if (hasRecommendations)
              Blogs(
                key: const ValueKey("recommendations"),
                url: _getUrlForRecommendation(),
                flag: 0,
                searchQuery: "",
                // pass the search query here
                isRecommendation:
                    true, // <--- Renders horizontally with smaller cards
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "No recommendations yet",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),

            // ============ ALL SHOPS SECTION ============ //
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  "All Shops",
                  style: kIsWeb
                      ? TextStyle(
                          color: Colors.black,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)
                      : TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Blogs(
              key: ValueKey("allShops-${widget.filterState}"),
              url: _getUrlForFilterState(),
              flag: 0,
              searchQuery: _searchQuery,
              // pass the search query here too
              isRecommendation:
                  false, // <--- Renders horizontally with smaller cards
            ),
          ],
        ),
      ),
    );
  }
}
