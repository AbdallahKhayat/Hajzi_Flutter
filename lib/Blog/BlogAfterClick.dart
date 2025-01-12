import 'dart:convert';

import 'package:blogapp/Blog/BlogsChatPage.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:latlong2/latlong.dart' as latLng; // For lat/lng
import 'package:share_plus/share_plus.dart'; // Import the Share package
import '../MapPage.dart';
import '../Models/addBlogModel.dart';
import '../Pages/ChatPage.dart';
import '../Pages/CustomerAppointmentPage.dart';
import '../Pages/IndividualPage.dart';
import '../Pages/userAppointmentPage.dart';
import '../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BlogAfterClick extends StatefulWidget {
  BlogAfterClick(
      {super.key, required this.addBlogModel, required this.networkHandler});

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
  String blogOwnerName = '';
  final storage = FlutterSecureStorage();
  double _averageRating = 0.0;
  int _numberOfRatings = 0;
  bool _userHasRated = false;


  // Example coordinates for the shop location
  final latLng.LatLng _center =
      latLng.LatLng(37.42796133580664, -122.085749655962);

  @override
  void initState() {
    super.initState();
    availableSlots = _getAvailableSlots();
    selectedTime = DateTime.now();
    fetchBlogDetails();
    _loadUserRole();
    _loadEmailRole();
    _loadUserName();
    _storeLastClickedType(widget.addBlogModel.type ?? 'none');
    _fetchRatingInfo(); // <-- fetch rating after building the page
  }
  Future<void> _fetchRatingInfo() async {
    try {
      final response = await widget.networkHandler.get(
        "/blogpost/ratinginfo/${widget.addBlogModel.id}",
      );
      if (response != null && response['Status'] == true) {
        setState(() {
          _averageRating = (response['averageRating'] as num).toDouble();
          _numberOfRatings = response['numberOfRatings'] as int;
          _userHasRated = response['userHasRated'] as bool;
        });
      }
    } catch (e) {
      debugPrint("Error fetching rating info: $e");
    }
  }

  Future<void> _rateBlog(double ratingValue) async {
    try {
      final body = {"rating": ratingValue};
      final httpResponse = await widget.networkHandler.patch2E(
        "/blogpost/rate/${widget.addBlogModel.id}",
        body,
      );

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        final responseData = jsonDecode(httpResponse.body);
        if (responseData['Status'] == true) {
          setState(() {
            _averageRating =
                (responseData['data']['averageRating'] as num).toDouble();
            _numberOfRatings = responseData['data']['numberOfRatings'] as int;
            _userHasRated = true; // user cannot rate again
          });
        } else {
          debugPrint("Error rating blog: ${responseData['message']}");
        }
      } else {
        debugPrint("Error rating blog: ${httpResponse.body}");
      }
    } catch (e) {
      debugPrint("Exception rating blog: $e");
    }
  }


  Future<void> _storeLastClickedType(String storeType) async {
    try {
      await storage.write(key: "lastClickedStoreType", value: storeType);
      debugPrint("Stored lastClickedStoreType = $storeType");
    } catch (e) {
      debugPrint("Failed to store lastClickedStoreType: $e");
    }
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
      final response = await widget.networkHandler
          .get("/blogpost/getBlogDetails/${widget.addBlogModel.id}");
      if (response != null && response['authorName'] != null) {
        setState(() {
          blogOwnerEmail = response['authorName'];
          blogOwnerName = response['username'];
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

  void _openMapPage() {
    if (widget.addBlogModel.lat != null && widget.addBlogModel.lng != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MapPage(
                lat: widget.addBlogModel.lat!, lng: widget.addBlogModel.lng!)),
      );
    }
  }

  Future<String?> fetchExistingChatId(String partnerEmail) async {
    try {
      final response = await NetworkHandler()
          .get('/chat/existing?partnerEmail=$partnerEmail');
      // Ensure `NetworkHandler().get()` returns the decoded JSON. If it returns a raw response, decode it here.
      if (response != null && response is Map) {
        // If the response contains '_id', it means chat exists
        if (response['_id'] != null) {
          return response['_id'];
        }
      }
      return null; // No existing chat found
    } catch (e) {
      print("Error checking for existing chat: $e");
      return null;
    }
  }

  void _shareBlogDetails() {
    final String blogDetails = "🛒 Check out this amazing Shop!\n\n"
        "Title: ${widget.addBlogModel.title}\n"
        "Description: ${widget.addBlogModel.body}\n\n"
        "View it here 📍: https://www.google.com/maps/search/?api=1&query=${widget.addBlogModel.lat},${widget.addBlogModel.lng}";
    Share.share(blogDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: Text(
          AppLocalizations.of(context)!.shopDetails,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // Center the title for better aesthetics on web
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Define a max width for large screens
          double maxWidth = 800;
          if (constraints.maxWidth > 900) {
            maxWidth = 800;
          } else {
            maxWidth = constraints.maxWidth;
          }

          return Center(
            child: Container(
              width: maxWidth,
              padding: const EdgeInsets.all(16.0),
              child: ListView(
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
                              image: DecorationImage(
                                  image: image, fit: BoxFit.cover),
                            ),
                          );
                        }).toList(),
                        options: CarouselOptions(
                          height: constraints.maxWidth > 600 ? 400 : 230,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          aspectRatio: 16 / 9,
                          viewportFraction: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ===== RATING SECTION =====
                  _buildRatingSection(),
                  // Blog title
                  Text(
                    widget.addBlogModel.title!,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Action row with Find Me, Chat, and Share
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Find Me Button
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.location_on,
                              color: Colors.black),
                          label: Text(
                            AppLocalizations.of(context)!.findMe,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          onPressed: _openMapPage,
                        ),
                      ),

                      if(userRole != "admin")
                      // Chat Button with Label
                      Expanded(
                        child: Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_bubble,
                                  color: Colors.black),
                              onPressed: () async {
                                final existingChatId =
                                    await fetchExistingChatId(blogOwnerEmail);
                                if (userEmail == blogOwnerEmail) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatPage(
                                          chatId: '',
                                          chatPartnerEmail: '',
                                          appBarFlag: 1),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IndividualPage(
                                        initialChatId: existingChatId ?? '',
                                        chatPartnerEmail: blogOwnerEmail,
                                        chatPartnerName: blogOwnerName,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            Text(
                              AppLocalizations.of(context)!.chat,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Share Button with Label
                      Expanded(
                        child: Column(
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.share, color: Colors.black),
                              onPressed: _shareBlogDetails,
                            ),
                             Text(
                              AppLocalizations.of(context)!.share,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        widget.addBlogModel.body!,
                        style: const TextStyle(fontSize: 18),
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder<Color>(
                          valueListenable: appColorNotifier,
                          builder: (context, appColor, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [appColor.withOpacity(1), appColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child:  Text(
                                AppLocalizations.of(context)!.bookAnAppointment,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors
                                      .white, // Required but overridden by the shader
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                         Text(
                          AppLocalizations.of(context)!.bookingText,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ValueListenableBuilder<Color>(
                          valueListenable: appColorNotifier,
                          builder: (context, appColor, child) {
                            return ElevatedButton.icon(
                              onPressed: _navigateToAppointmentPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColor, // Dynamic color
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              icon: const Icon(Icons.calendar_today,
                                  color: Colors.white, size: 24),
                              label: Text(
                                AppLocalizations.of(context)!.bookAppointment,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper widget to keep code clean
  Widget _buildRatingSection() {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Rate This Shop:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Show the star rating bar
            if (!_userHasRated) ...[
              // If user has not rated yet, let them choose
              RatingBar.builder(
                initialRating: _averageRating,
                minRating: 1,
                maxRating: 5,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (ratingValue) async {
                  // Call the rating endpoint
                  await _rateBlog(ratingValue);
                },
              ),
            ] else ...[
              // If user already rated, just show the average rating as "read only"
              RatingBarIndicator(
                rating: _averageRating,
                itemBuilder: (context, index) =>
                const Icon(Icons.star, color: Colors.amber),
                itemSize: 30.0,
              ),
              const SizedBox(height: 8),
              const Text("You have already rated this shop."),
            ],

            const SizedBox(height: 8),
            // Show the average rating
            Text(
              "Average Rating: ${_averageRating.toStringAsFixed(1)} / 5.0",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Number of Ratings: $_numberOfRatings",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
