import 'package:blogapp/Blog/BlogsChatPage.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:latlong2/latlong.dart' as latLng; // For lat/lng

import '../MapPage.dart';
import '../Models/addBlogModel.dart';
import '../Pages/CustomerAppointmentPage.dart';
import '../Pages/userAppointmentPage.dart';


class BlogAfterClick extends StatefulWidget {
  BlogAfterClick({super.key, required this.addBlogModel, required this.networkHandler});

  final AddBlogModel addBlogModel;
  final NetworkHandler networkHandler;

  @override
  _BlogAfterClickState createState() => _BlogAfterClickState();
}

class _BlogAfterClickState extends State<BlogAfterClick> {
  late List<DateTime> availableSlots;
  late DateTime selectedTime;
  String? userRole;
  String userName = 'Unknown User';
  String? userEmail; // Current user's email from secure storage
  String blogOwnerEmail = ''; // Blog owner's email from fetchBlogDetails
  final storage = FlutterSecureStorage();

  // Example coordinates for the shop location
  final latLng.LatLng _center = latLng.LatLng(37.42796133580664, -122.085749655962);

  @override
  void initState() {
    super.initState();
    availableSlots = _getAvailableSlots();
    selectedTime = DateTime.now();
    fetchBlogDetails();
    _loadUserRole();
    _loadEmailRole();
    _loadUserName();
  }

  // Simulate fetching available slots from the backend
  List<DateTime> _getAvailableSlots() {
    return [
      DateTime.now().add(const Duration(hours: 2)),
      DateTime.now().add(const Duration(hours: 3)),
      DateTime.now().add(const Duration(hours: 4)),
    ];
  }

  // Load the role of the current user
  Future<void> _loadUserRole() async {
    final role = await storage.read(key: "role");
    setState(() {
      userRole = role;
    });
  }

  // Load the email of the current user
  Future<void> _loadEmailRole() async {
    final email = await storage.read(key: "email");
    setState(() {
      userEmail = email;
    });
  }

  // Load the name of the current user
  Future<void> _loadUserName() async {
    try {
      final response = await widget.networkHandler.get("/user/getUserName");
      setState(() {
        userName = response['username'] ?? 'Unknown User';
      });
    } catch (error) {
      debugPrint("Error loading user name: $error");
    }
  }

  // Fetch the blog details (like blogOwnerEmail)
  Future<void> fetchBlogDetails() async {
    try {
      final response = await widget.networkHandler.get(
          "/blogpost/getBlogDetails/${widget.addBlogModel.id}");
      if (response != null && response['authorName'] != null) {
        setState(() {
          blogOwnerEmail = response['authorName'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching blog details: $e");
    }
  }

  void _navigateToAppointmentPage() {
    if (userRole == 'customer' && userEmail == blogOwnerEmail) {
      // If user is a customer and the current user is the owner of the blog, go to CustomerAppointmentPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CustomerAppointmentPage(
                networkHandler: widget.networkHandler,
                blogId: widget.addBlogModel.id!,
              ),
        ),
      );
    } else {
      // Otherwise, go to UserAppointmentPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              UserAppointmentPage(
                networkHandler: widget.networkHandler,
                blogId: widget.addBlogModel.id!,
                userName: userEmail!,
              ),
        ),
      );
    }
  }

  void _openMapPage() {
    if (widget.addBlogModel.lat != null && widget.addBlogModel.lng != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapPage(lat: widget.addBlogModel.lat!, lng: widget.addBlogModel.lng!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          "Shop Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Image carousel
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CarouselSlider(
                items: widget.networkHandler
                    .getImages(widget.addBlogModel.coverImages ?? [])
                    .map((image) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(image: image, fit: BoxFit.cover),
                    ),
                  );
                }).toList(),
                options: CarouselOptions(
                  height: 230,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Blog title
          Text(
            widget.addBlogModel.title!,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Action row with Find Me, Chat, and Share
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.location_on, color: Colors.black),
                label: const Text(
                  "Find Me",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,color: Colors.black),
                ),
                onPressed: _openMapPage,
              ),

              IconButton(
                icon: const Icon(Icons.chat_bubble, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BlogsChatPage(blogId: widget.addBlogModel.id!),
                    ),
                  );
                },
              ),
              const Text(
                "Chat",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),

              IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: () {
                  // Add share functionality here
                },
              ),
              const Text(
                "Share",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Blog description
          Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                widget.addBlogModel.body!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Book Appointment Section
          Container(
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.teal, width: 1),
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Book an Appointment",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Click the button below to book or manage your appointments.",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _navigateToAppointmentPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: const Text(
                    "Book Appointment",
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
