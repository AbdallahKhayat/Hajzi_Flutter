import 'package:blogapp/Blog/BlogsChatPage.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';

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
  late int likeCount;
  late bool isLiked;
  late List<DateTime> availableSlots;
  late DateTime selectedTime;
  String? userRole;
  String userName = 'Unknown User';
  String? userEmail; // Current user's email from secure storage
  String blogOwnerEmail = ''; // Blog owner's email from fetchBlogDetails
  final storage = FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    likeCount = widget.addBlogModel.like ?? 0;
    isLiked = false;

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
      final response = await widget.networkHandler.get("/blogpost/getBlogDetails/${widget.addBlogModel.id}");
      if (response != null && response['authorName'] != null) {
        setState(() {
          blogOwnerEmail = response['authorName'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching blog details: $e");
    }
  }


  Future<void> _handleLike() async {
    setState(() {
      isLiked = !isLiked;
      likeCount = isLiked ? likeCount + 1 : likeCount - 1;
    });

    Map<String, dynamic> data = {
      "like": likeCount,
    };

    final response = await widget.networkHandler.patch("/blogPost/updateLikes/${widget.addBlogModel.id}", data);
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");
  }

  void _navigateToAppointmentPage() {
    if (userRole == 'customer' && userEmail == blogOwnerEmail) {
      // If user is a customer and the current user is the owner of the blog, go to CustomerAppointmentPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerAppointmentPage(
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
          builder: (context) => UserAppointmentPage(
            networkHandler: widget.networkHandler,
            blogId: widget.addBlogModel.id!,
            userName: userEmail!,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        children: [
          // Image slideshow
          Container(
            height: 379,
            width: MediaQuery.of(context).size.width,
            child: Card(
              elevation: 8,
              child: Column(
                children: [
                  Container(
                    height: 230,
                    width: MediaQuery.of(context).size.width,
                    child: CarouselSlider(
                      items: widget.networkHandler
                          .getImages(widget.addBlogModel.coverImages ?? [])
                          .map((image) {
                        return Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: image,
                              fit: BoxFit.fill,
                            ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                    child: Text(
                      widget.addBlogModel.title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.thumb_up,
                            color: isLiked ? Colors.blue : Colors.black,
                          ),
                          onPressed: _handleLike,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          likeCount.toString(),
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 15),
                        const Icon(Icons.chat_bubble, size: 20),
                        const SizedBox(width: 5),
                        Text(
                          widget.addBlogModel.comment.toString(),
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 15),
                        const Icon(Icons.share, size: 20),
                        Spacer(flex: 1),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.commentDots, size: 20, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlogsChatPage(blogId: widget.addBlogModel.id!),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blog Body Section
          const SizedBox(height: 10),
          Container(
            width: MediaQuery.of(context).size.width,
            child: Card(
              elevation: 15,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
                child: Text(widget.addBlogModel.body!),
              ),
            ),
          ),

          // Book Appointment Button
          const SizedBox(height: 20),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Card(
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Book an Appointment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Click the button to book an appointment or manage your appointments.",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _navigateToAppointmentPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Book Appointment"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
