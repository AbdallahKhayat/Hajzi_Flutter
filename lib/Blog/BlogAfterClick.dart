import 'package:blogapp/Blog/BlogsChatPage.dart';
import 'package:blogapp/Models/addBlogApproval.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:flutter/material.dart';
import '../Models/AppointmentModel.dart';
import '../Models/addBlogModel.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // For formatting the date and time
import 'package:carousel_slider/carousel_slider.dart';

class BlogAfterClick extends StatefulWidget {
  BlogAfterClick({super.key, required this.addBlogModel, required this.networkHandler});

  final AddBlogModel addBlogModel;
  // final AddBlogApproval addBlogApproval;
  final NetworkHandler networkHandler;

  @override
  _BlogAfterClickState createState() => _BlogAfterClickState();
}

class _BlogAfterClickState extends State<BlogAfterClick> {
  late int likeCount;
  late bool isLiked;
  late List<DateTime> availableSlots; // List of available slots for booking
  late DateTime selectedTime; // Store the selected time slot for booking

  @override
  void initState() {
    super.initState();
    likeCount = widget.addBlogModel.like ?? 0;
    isLiked = false;

    // Example available slots, in a real app this would come from a backend
    availableSlots = _getAvailableSlots();
    selectedTime = DateTime.now(); // Default to current time
  }

  // Fetch available slots dynamically (could come from a backend API)
  List<DateTime> _getAvailableSlots() {
    return [
      DateTime.now().add(Duration(hours: 2)),
      DateTime.now().add(Duration(hours: 3)),
      DateTime.now().add(Duration(hours: 4)),
    ];
  }

  // Handle Like functionality
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

  // Handle booking appointment
  Future<void> _bookAppointment(DateTime time) async {
    AppointmentModel appointment = AppointmentModel(
      userId: "userId", // Replace with actual user data
      userName: "userName", // Replace with actual user name
      dateTime: time,
      blogOwnerId: widget.addBlogModel.id!,
    );

    Map<String, dynamic> data = {
      "userId": appointment.userId,
      "userName": appointment.userName,
      "dateTime": appointment.dateTime.toIso8601String(),
      "blogOwnerId": appointment.blogOwnerId,
      "isConfirmed": false,
    };

    final response = await widget.networkHandler.post("/appointments/book", data);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment booked successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to book appointment!')));
    }
  }

  // Show available time slots in a dialog
  void _showBookingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select an Available Time Slot"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableSlots.map((slot) {
              return ListTile(
                title: Text(DateFormat('hh:mm a').format(slot)),
                onTap: () {
                  setState(() {
                    selectedTime = slot;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _bookAppointment(selectedTime);
                Navigator.pop(context);
              },
              child: Text("Book Appointment"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        children: [
          // Blog Content Section with Slideshow
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
                    child:CarouselSlider(
                      items: widget.networkHandler
                          .getImages(widget.addBlogModel.coverImages ?? [])
                          .map((image) {
                        return Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: image, // Use the NetworkImage object directly
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
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
                          icon: FaIcon(FontAwesomeIcons.commentDots, size: 20, color: Colors.black),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blog Body Content Section
          SizedBox(height: 10),
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

          // Book Appointment Section
          SizedBox(height: 20),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Card(
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Book an Appointment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Select an available time slot to book an appointment with the blog owner.",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showBookingDialog,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Book Now"),
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

