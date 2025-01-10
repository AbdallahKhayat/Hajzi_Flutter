import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:blogapp/Models/profileModel.dart';
import 'package:blogapp/Screen/chatscreen.dart';
import 'package:blogapp/Screen/usersScreen.dart';
import 'package:blogapp/services/stripe_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Blog/addBlog.dart';
import '../NetworkHandler.dart';
import '../Notifications/push_notifications.dart';
import '../Requests/RequestsScreen.dart';
import '../Screen/ChatBotScreen.dart';
import '../Screen/DashboardScreen.dart';
import '../Screen/HomeScreen.dart';
import '../Profile/ProfileScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../Screen/notificationScreen.dart';
import '../Screen/shopsscreen.dart';
import 'WelcomePage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:blogapp/constants.dart';

class HomePage extends StatefulWidget {
  final void Function(Locale) setLocale;
  int filterState = 0; // 0 => "All Posts", 1 => "BarberShop", 2 => "Hospital"

  HomePage({super.key, required this.setLocale, required this.filterState});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  NetworkHandler networkHandler = NetworkHandler();

  // -----------------------------------------
  // Common variables (mobile + web)
  // -----------------------------------------
  String email = "";
  String? userRole;

  int currentState = 0; // This controls which screen index is shown (0..n).
  int userCount = 0; // For Admin: number of users
  int requestCount = 0; // For Admin: number of requests
  int notificationsCount = 0;

  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  Widget profilePhoto = Container(
    height: 100,
    width: 100,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(50),
    ),
    child: const Icon(Icons.person, size: 50, color: Colors.grey),
  );

  // For side navigation on web
  bool isDrawerCollapsed = false;

  // For language selection
  String selectedLanguage = "English";

  // We'll have a common list of screens for mobile's bottom nav + web main content
  // Index: 0 => HomeScreen(...)  [filtered by widget.filterState]
  //        1 => ProfileScreen()
  //        2 => ChatScreen()
  //        3 => ShopsScreen() OR UsersScreen() depending on userRole
  //        4 => RequestsScreen()
  List<Widget> widgets = [];
  ProfileModel profileModel = ProfileModel();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    checkProfile();
    //fetchData();

    // Poll for counts every 20 seconds
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      fetchCounts();
    });

    // Notification wiggle
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: -0.5, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notificationsCount > 0) {
        _startAnimation();
      }
    });
    _animationController.repeat(reverse: true);

    // Initialize the screen list
    widgets = [
      DashboardScreen(),
      HomeScreen(filterState: widget.filterState), // Index 0
      ProfileScreen(), // Index 1

      if(userRole != "admin")
      ChatScreen(), // Index 2

      ShopsScreen(), // Index 3 (if customer), or UsersScreen() if admin
      UsersScreen(),
      RequestsScreen(), // Index 4 (admin only)
    ];
  }

  void _startAnimation() => _animationController.repeat(reverse: true);

  void _stopAnimation() => _animationController.stop();

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // -----------------------------------------
  // Load user role
  // -----------------------------------------
  Future<void> _loadUserRole() async {
    final role = await storage.read(key: "role");
    setState(() {
      userRole = role;
    });
  }

  // void fetchData() async {
  //   var response = await networkHandler.get("/profile/getData");
  //   if(mounted)
  //     setState(() {
  //       profileModel =
  //           ProfileModel.fromJson(response["data"]); // Data within 'data'
  //     });
  // }

  // -----------------------------------------
  // Check profile (email + photo)
  // -----------------------------------------
  void checkProfile() async {
    var response = await networkHandler.get("/profile/checkProfile");

    // Ensure the response is a Map and contains the necessary fields
    if (response is Map<String, dynamic> && response['Status'] == true) {
      setState(() {
        email = response["email"] ?? "email";

        // Update profileModel with the img field
        profileModel.img =
            response["img"]; // Ensure ProfileModel has an 'img' field

        profilePhoto = CircleAvatar(
          radius: 50,
          backgroundImage: (profileModel.img != null &&
                  profileModel.img!.isNotEmpty)
              ? CachedNetworkImageProvider(profileModel.img!)
              : AssetImage('assets/images/placeholder.png') as ImageProvider,
          child: (profileModel.img == null || profileModel.img!.isEmpty)
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
        );
      });
    } else {
      setState(() {
        email = "email";
        profilePhoto = CircleAvatar(
          radius: 50,
          backgroundImage:
              AssetImage('assets/images/placeholder.png') as ImageProvider,
          child: const Icon(Icons.person, size: 50, color: Colors.grey),
        );
      });
    }
  }

  // -----------------------------------------
  // Theme color picker
  // -----------------------------------------
  void pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = appColorNotifier.value;
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.pickThemeColor),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.select),
              onPressed: () {
                setState(() {
                  appColorNotifier.value = tempColor;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // -----------------------------------------
  // Language dialog
  // -----------------------------------------
  void _showLanguageDialog(BuildContext context) {
    List<String> languages = ["English", "العربية"];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: SingleChildScrollView(
            child: Column(
              children: languages.map((language) {
                return RadioListTile(
                  title: Text(language),
                  value: language,
                  groupValue: selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      selectedLanguage = value!;
                      Locale newLocale = (selectedLanguage == "العربية")
                          ? const Locale('ar', 'AE')
                          : const Locale('en', 'US');
                      widget.setLocale(newLocale);
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------
  // Logout
  // -----------------------------------------
  void logout() async {
    await storage.delete(key: "token");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => WelcomePage(setLocale: widget.setLocale),
      ),
      (route) => false,
    );
  }

  // -----------------------------------------
  // Fetch counts: users, requests, notifications
  // -----------------------------------------
  Future<void> fetchCounts() async {
    try {
      // user count
      var userResponse = await networkHandler.get("/user/getUsers");
      if (userResponse != null && userResponse['data'] != null) {
        setState(() {
          userCount = userResponse['data'].length;
        });
      }

      // request count
      var requestResponse =
          await networkHandler.get("/AddBlogApproval/requests");
      if (requestResponse != null && requestResponse['data'] != null) {
        setState(() {
          requestCount = requestResponse['data'].length;
        });
      }

      // notifications
      String? email = await storage.read(key: "email");
      if (email != null) {
        var notificationResponse =
            await networkHandler.get("/notifications/unreadCount/$email");
        if (notificationResponse != null &&
            notificationResponse['count'] != null) {
          setState(() {
            notificationsCount = notificationResponse['count'];
            if (notificationsCount > 0) {
              _startAnimation();
            } else {
              _stopAnimation();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching counts: $e");
    }
  }

  // -----------------------------------------
  // Build: check if web or mobile
  // -----------------------------------------
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return buildWebLayout(context);
    } else {
      return buildMobileLayout(context);
    }
  }

  // -----------------------------------------
  // Mobile Layout (Drawer + BottomNav)
  // -----------------------------------------
  Widget buildMobileLayout(BuildContext context) {
    // Build the visible screens
    List<Widget> visibleWidgets = [
      // index 0 => Home (with filter)
      // index 1 => Profile
      // index 2 => Chat
      // then conditional:
    ];
    if (userRole == "admin") visibleWidgets.add(DashboardScreen());

    visibleWidgets.add(widgets[1]); // HomeScreen with filterState
    visibleWidgets.add(widgets[2]); // ProfileScreen
    if(userRole != "admin")
    visibleWidgets.add(widgets[3]); // ChatScreen

    if (userRole == "customer") {
      // index 3 => Shops
      visibleWidgets.add(widgets[4]);
    } else if (userRole == "admin") {
      // index 3 => Users
      // index 4 => Requests
      visibleWidgets.add(UsersScreen()); // override index 3
      visibleWidgets.add(RequestsScreen()); // override index 4
    }

    // Build nav items
    List<BottomNavigationBarItem> navItems = [
      if (userRole == "admin")
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: AppLocalizations.of(context)!.dashboard,
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.home),
        label: AppLocalizations.of(context)!.home,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person),
        label: AppLocalizations.of(context)!.profile,
      ),
      if(userRole != "admin")
      BottomNavigationBarItem(
        icon: const Icon(Icons.chat),
        label: AppLocalizations.of(context)!.chat,
      ),
    ];

    if (userRole == "customer") {
      navItems.add(
        BottomNavigationBarItem(
          icon: const Icon(Icons.shop_two),
          label: AppLocalizations.of(context)!.myshops,
        ),
      );
    } else if (userRole == "admin") {
      navItems.add(
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.people),
              if (userCount > 0)
                Positioned(
                  right: 2,
                  top: 0,
                  bottom: 7,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$userCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          label: AppLocalizations.of(context)!.users,
        ),
      );
      navItems.add(
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.add_business),
              if (requestCount > 0)
                Positioned(
                  right: 2,
                  top: 0,
                  bottom: 7,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$requestCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          label: AppLocalizations.of(context)!.requests,
        ),
      );
    }

    // Safety check
    if (currentState >= visibleWidgets.length) {
      currentState = 0;
    }

    return ValueListenableBuilder<Color>(
      valueListenable: appColorNotifier,
      builder: (context, appColor, child) {
        return Scaffold(
          drawer: Drawer(
            child: ListView(
              children: [
                // Drawer header
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [appColor.withOpacity(0.8), appColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      profilePhoto,
                      const SizedBox(height: 10),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        // Adds ellipsis when text overflows
                        maxLines: 1, // Restricts the text to a single line
                      ),
                    ],
                  ),
                ),
                // "All Posts" => sets filterState=0
                _drawerItem(
                  title: AppLocalizations.of(context)!.allposts,
                  icon: Icons.list,
                  isFocused: widget.filterState == 0,
                  onTap: () {
                    setState(() {
                      widget.filterState = 0;
                      // Rebuild the home screen with new filter
                      widgets[1] = HomeScreen(filterState: widget.filterState);
                    });
                    Navigator.pop(context);
                  },
                ),
                // "BarberShop Posts" => sets filterState=1
                _drawerItem(
                  title: AppLocalizations.of(context)!.barberShopPosts,
                  icon: Icons.content_cut,
                  isFocused: widget.filterState == 1,
                  onTap: () {
                    setState(() {
                      widget.filterState = 1;
                      widgets[1] = HomeScreen(filterState: widget.filterState);
                    });
                    Navigator.pop(context);
                  },
                ),
                // "Hospital Posts" => sets filterState=2
                _drawerItem(
                  title: AppLocalizations.of(context)!.hospitalPosts,
                  icon: Icons.local_hospital,
                  isFocused: widget.filterState == 2,
                  onTap: () {
                    setState(() {
                      widget.filterState = 2;
                      widgets[1] = HomeScreen(filterState: widget.filterState);
                    });
                    Navigator.pop(context);
                  },
                ),

                // "New Story" (if userRole != "user")
                if (userRole != "user")
                  _drawerItem(
                    title: AppLocalizations.of(context)!.newstory,
                    icon: Icons.add,
                    isFocused: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddBlog()),
                      );
                    },
                  ),
                _drawerItem(
                  title: AppLocalizations.of(context)!.settings,
                  icon: Icons.settings,
                  isFocused: false,
                  onTap: () => pickColor(context),
                ),
                _drawerItem(
                  title: AppLocalizations.of(context)!.changelanguage,
                  icon: Icons.language,
                  isFocused: false,
                  onTap: () => _showLanguageDialog(context),
                ),
                // "Upgrade to Customer" if userRole == "user"
                if (userRole == "user")
                  ListTile(
                    leading: Icon(Icons.credit_card, color: appColor),
                    title: Text(
                      AppLocalizations.of(context)!.customer,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _upgradeToCustomer,
                  ),
                // Feedback (AI chat)
                ListTile(
                  leading:
                      Icon(FontAwesomeIcons.robot, size: 21, color: appColor),
                  title: Text(
                    AppLocalizations.of(context)!.feedback,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showChatBotModeDialog,
                ),
                Divider(thickness: 1, color: Colors.grey.shade400),
                // Logout
                ListTile(
                  leading:
                      const Icon(Icons.power_settings_new, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(context)!.logout,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: logout,
                ),
              ],
            ),
          ),
          appBar: AppBar(
            backgroundColor: appColor,
            title: Text(
              _getMobileAppBarTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              // Notification icon
              Stack(
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: notificationsCount > 0
                            ? 0.5 * math.sin(_animation.value * math.pi)
                            : 0.0,
                        child: IconButton(
                          icon: const Icon(Icons.notifications),
                          color: Colors.black,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  if (notificationsCount > 0)
                    Positioned(
                      right: 6,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 5,
                        ),
                        child: Text(
                          '$notificationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: (userRole != "user")
              ? FloatingActionButton(
                  backgroundColor: appColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 500),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            AddBlog(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: animation.drive(
                              Tween(
                                begin: const Offset(0.0, 1.0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeInOut)),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          // Bottom Nav
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentState,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.black,
            backgroundColor: appColor,
            selectedFontSize: 14, // Adjust font size
            unselectedFontSize: 12, // Adjust font size
            type: BottomNavigationBarType.fixed,
            items: navItems,
            onTap: (index) {
              setState(() {
                currentState = index;
                checkProfile();
                // If admin in "Users" or "Requests" tab
                if (userRole == "admin" &&
                    (currentState == 2 ||
                        currentState == 3 ||
                        currentState == 0)) {
                  fetchCounts();
                }
              });
            },
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: visibleWidgets[currentState],
          ),
        );
      },
    );
  }

  // The mobile app bar title, based on currentState and userRole
  String _getMobileAppBarTitle() {
    if (userRole == "admin") {
      if (currentState == 0) {
        return AppLocalizations.of(context)!.dashboard;
      } else if (currentState == 1) {
        return AppLocalizations.of(context)!.home;
      } else if (currentState == 2) {
        return AppLocalizations.of(context)!.profile;
      // } else if (currentState == 3) {
      //   return AppLocalizations.of(context)!.chat;
      } else if (currentState == 3) {
        return AppLocalizations.of(context)!.users;
      } else {
        // admin & currentState == 5
        return AppLocalizations.of(context)!.requests;
      }
    } else {
      if (currentState == 0) {
        return AppLocalizations.of(context)!.home;
      } else if (currentState == 1) {
        return AppLocalizations.of(context)!.profile;
      } else if (currentState == 2) {
        return AppLocalizations.of(context)!.chat;
      } else if (userRole == "customer" && currentState == 3) {
        return AppLocalizations.of(context)!.myshops;
      } else if (userRole == "admin" && currentState == 3) {
        return AppLocalizations.of(context)!.users;
      } else {
        // admin & currentState == 5
        return AppLocalizations.of(context)!.requests;
      }
    }
  }

  // -----------------------------------------
  // WEB LAYOUT
  // -----------------------------------------
  Widget buildWebLayout(BuildContext context) {
    Widget mainContent = buildMainContentWeb();

    return ValueListenableBuilder<Color>(
      valueListenable: appColorNotifier,
      builder: (context, appColor, child) {
        return Scaffold(
          body: Row(
            children: [
              // Side nav
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isDrawerCollapsed ? 70 : 230,
                color: appColor,
                child: Column(
                  children: [
                    // Header with profile
                    Container(
                      height: 140,
                      padding: const EdgeInsets.all(4.0),
                      color: appColor.withOpacity(0.9),
                      alignment: Alignment.center,
                      child: isDrawerCollapsed
                          ? IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  isDrawerCollapsed = !isDrawerCollapsed;
                                });
                              },
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipOval(
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: profilePhoto,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.chevron_left,
                                        color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        isDrawerCollapsed = !isDrawerCollapsed;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                    // Nav items
                    Expanded(
                      child: SingleChildScrollView(
                        child: userRole == "admin"
                            ? Column(
                                children: [
                                  _webNavItem(
                                    icon: Icons.dashboard,
                                    label: AppLocalizations.of(context)!.dashboard,
                                    isActive: currentState == 0,
                                    onTap: () {
                                      setState(() {
                                        currentState = 0;
                                      });
                                    },
                                  ),
                                  // All Posts => filter=0, currentState=0
                                  _webNavItem(
                                    icon: Icons.list,
                                    label:
                                        AppLocalizations.of(context)!.allposts,
                                    // We consider isActive if filterState=0 & currentState=0
                                    isActive: (currentState == 1 &&
                                        widget.filterState == 0),
                                    onTap: () {
                                      setState(() {
                                        currentState = 1;
                                        widget.filterState = 0;
                                        widgets[1] = HomeScreen(filterState: 0);
                                      });
                                    },
                                  ),
                                  // BarberShop => filter=1, still index=0
                                  _webNavItem(
                                    icon: Icons.content_cut,
                                    label: AppLocalizations.of(context)!
                                        .barberShopPosts,
                                    isActive: (currentState == 1 &&
                                        widget.filterState == 1),
                                    onTap: () {
                                      setState(() {
                                        currentState = 1;
                                        widget.filterState = 1;
                                        widgets[1] = HomeScreen(filterState: 1);
                                      });
                                    },
                                  ),
                                  // Hospital => filter=2, still index=0
                                  _webNavItem(
                                    icon: Icons.local_hospital,
                                    label: AppLocalizations.of(context)!
                                        .hospitalPosts,
                                    isActive: (currentState == 1 &&
                                        widget.filterState == 2),
                                    onTap: () {
                                      setState(() {
                                        currentState = 1;
                                        widget.filterState = 2;
                                        widgets[1] = HomeScreen(filterState: 2);
                                      });
                                    },
                                  ),
                                  // Profile => currentState=1
                                  _webNavItem(
                                    icon: Icons.person,
                                    label:
                                        AppLocalizations.of(context)!.profile,
                                    isActive: currentState == 2,
                                    onTap: () {
                                      setState(() {
                                        currentState = 2;
                                      });
                                    },
                                  ),
                                  // Chat => currentState=2
                                  if(userRole!="admin")
                                  _webNavItem(
                                    icon: Icons.chat,
                                    label: AppLocalizations.of(context)!.chat,
                                    isActive: currentState == 3,
                                    onTap: () {
                                      setState(() {
                                        currentState = 3;
                                      });
                                    },
                                  ),
                                  // If customer => MyShops => index=3
                                  if (userRole == "customer")
                                    _webNavItem(
                                      icon: Icons.shop_two,
                                      label:
                                          AppLocalizations.of(context)!.myshops,
                                      isActive: currentState == 4,
                                      onTap: () {
                                        setState(() {
                                          currentState = 4;
                                        });
                                      },
                                    ),
                                  // If admin => Users (3), Requests (4)
                                  if (userRole == "admin") ...[
                                    _webNavItem(
                                      icon: Icons.people,
                                      label:
                                          AppLocalizations.of(context)!.users,
                                      isActive: currentState == 4,
                                      countBadge: userCount,
                                      onTap: () {
                                        setState(() {
                                          currentState = 4;
                                          fetchCounts();
                                        });
                                      },
                                    ),
                                    _webNavItem(
                                      icon: Icons.add_business,
                                      label: AppLocalizations.of(context)!
                                          .requests,
                                      isActive: currentState == 5,
                                      countBadge: requestCount,
                                      onTap: () {
                                        setState(() {
                                          currentState = 5;
                                          fetchCounts();
                                        });
                                      },
                                    ),
                                  ],
                                  // new story if userRole != "user"
                                  if (userRole != "user")
                                    _webNavItem(
                                      icon: Icons.add,
                                      label: AppLocalizations.of(context)!
                                          .newstory,
                                      isActive: false,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => AddBlog()),
                                        );
                                      },
                                    ),
                                  // settings
                                  _webNavItem(
                                    icon: Icons.settings,
                                    label:
                                        AppLocalizations.of(context)!.settings,
                                    isActive: false,
                                    onTap: () => pickColor(context),
                                  ),
                                  // language
                                  _webNavItem(
                                    icon: Icons.language,
                                    label: AppLocalizations.of(context)!
                                        .changelanguage,
                                    isActive: false,
                                    onTap: () => _showLanguageDialog(context),
                                  ),
                                  // upgrade to customer if userRole=="user"
                                  if (userRole == "user")
                                    _webNavItem(
                                      icon: Icons.credit_card,
                                      label: AppLocalizations.of(context)!
                                          .customer,
                                      isActive: false,
                                      onTap: _upgradeToCustomer,
                                    ),
                                  // feedback
                                  _webNavItem(
                                    icon: FontAwesomeIcons.robot,
                                    label:
                                        AppLocalizations.of(context)!.feedback,
                                    isActive: false,
                                    onTap: _showChatBotModeDialog,
                                  ),
                                  // Logout
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Divider(color: Colors.white70),
                                  ),
                                  _webNavItem(
                                    icon: Icons.power_settings_new,
                                    label: AppLocalizations.of(context)!.logout,
                                    isActive: false,
                                    iconColor: Colors.red,
                                    textColor: Colors.red,
                                    onTap: logout,
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  // All Posts => filter=0, currentState=0
                                  _webNavItem(
                                    icon: Icons.list,
                                    label:
                                        AppLocalizations.of(context)!.allposts,
                                    // We consider isActive if filterState=0 & currentState=0
                                    isActive: (currentState == 0 &&
                                        widget.filterState == 0),
                                    onTap: () {
                                      setState(() {
                                        currentState = 0;
                                        widget.filterState = 0;
                                        widgets[1] = HomeScreen(filterState: 0);
                                      });
                                    },
                                  ),
                                  // BarberShop => filter=1, still index=0
                                  _webNavItem(
                                    icon: Icons.content_cut,
                                    label: AppLocalizations.of(context)!
                                        .barberShopPosts,
                                    isActive: (currentState == 0 &&
                                        widget.filterState == 1),
                                    onTap: () {
                                      setState(() {
                                        currentState = 0;
                                        widget.filterState = 1;
                                        widgets[1] = HomeScreen(filterState: 1);
                                      });
                                    },
                                  ),
                                  // Hospital => filter=2, still index=0
                                  _webNavItem(
                                    icon: Icons.local_hospital,
                                    label: AppLocalizations.of(context)!
                                        .hospitalPosts,
                                    isActive: (currentState == 0 &&
                                        widget.filterState == 2),
                                    onTap: () {
                                      setState(() {
                                        currentState = 0;
                                        widget.filterState = 2;
                                        widgets[1] = HomeScreen(filterState: 2);
                                      });
                                    },
                                  ),
                                  // Profile => currentState=1
                                  _webNavItem(
                                    icon: Icons.person,
                                    label:
                                        AppLocalizations.of(context)!.profile,
                                    isActive: currentState == 1,
                                    onTap: () {
                                      setState(() {
                                        currentState = 1;
                                      });
                                    },
                                  ),
                                  // Chat => currentState=2
                                  _webNavItem(
                                    icon: Icons.chat,
                                    label: AppLocalizations.of(context)!.chat,
                                    isActive: currentState == 2,
                                    onTap: () {
                                      setState(() {
                                        currentState = 2;
                                      });
                                    },
                                  ),
                                  // If customer => MyShops => index=3
                                  if (userRole == "customer")
                                    _webNavItem(
                                      icon: Icons.shop_two,
                                      label:
                                          AppLocalizations.of(context)!.myshops,
                                      isActive: currentState == 3,
                                      onTap: () {
                                        setState(() {
                                          currentState = 3;
                                        });
                                      },
                                    ),
                                  // If admin => Users (3), Requests (4)
                                  if (userRole == "admin") ...[
                                    _webNavItem(
                                      icon: Icons.people,
                                      label:
                                          AppLocalizations.of(context)!.users,
                                      isActive: currentState == 3,
                                      countBadge: userCount,
                                      onTap: () {
                                        setState(() {
                                          currentState = 3;
                                          fetchCounts();
                                        });
                                      },
                                    ),
                                    _webNavItem(
                                      icon: Icons.add_business,
                                      label: AppLocalizations.of(context)!
                                          .requests,
                                      isActive: currentState == 4,
                                      countBadge: requestCount,
                                      onTap: () {
                                        setState(() {
                                          currentState = 4;
                                          fetchCounts();
                                        });
                                      },
                                    ),
                                  ],
                                  // new story if userRole != "user"
                                  if (userRole != "user")
                                    _webNavItem(
                                      icon: Icons.add,
                                      label: AppLocalizations.of(context)!
                                          .newstory,
                                      isActive: false,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => AddBlog()),
                                        );
                                      },
                                    ),
                                  // settings
                                  _webNavItem(
                                    icon: Icons.settings,
                                    label:
                                        AppLocalizations.of(context)!.settings,
                                    isActive: false,
                                    onTap: () => pickColor(context),
                                  ),
                                  // language
                                  _webNavItem(
                                    icon: Icons.language,
                                    label: AppLocalizations.of(context)!
                                        .changelanguage,
                                    isActive: false,
                                    onTap: () => _showLanguageDialog(context),
                                  ),
                                  // upgrade to customer if userRole=="user"
                                  if (userRole == "user")
                                    _webNavItem(
                                      icon: Icons.credit_card,
                                      label: AppLocalizations.of(context)!
                                          .customer,
                                      isActive: false,
                                      onTap: _upgradeToCustomer,
                                    ),
                                  // feedback
                                  _webNavItem(
                                    icon: FontAwesomeIcons.robot,
                                    label:
                                        AppLocalizations.of(context)!.feedback,
                                    isActive: false,
                                    onTap: _showChatBotModeDialog,
                                  ),
                                  // Logout
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Divider(color: Colors.white70),
                                  ),
                                  _webNavItem(
                                    icon: Icons.power_settings_new,
                                    label: AppLocalizations.of(context)!.logout,
                                    isActive: false,
                                    iconColor: Colors.red,
                                    textColor: Colors.red,
                                    onTap: logout,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Top bar
                    Container(
                      color: appColor,
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          if (isDrawerCollapsed)
                            IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  isDrawerCollapsed = !isDrawerCollapsed;
                                });
                              },
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getWebAppBarTitle(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          // Notification icon
                          Stack(
                            children: [
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: notificationsCount > 0
                                        ? 0.5 *
                                            math.sin(_animation.value * math.pi)
                                        : 0.0,
                                    child: IconButton(
                                      icon: const Icon(Icons.notifications),
                                      color: Colors.white,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const NotificationScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              if (notificationsCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 5,
                                    ),
                                    child: Text(
                                      '$notificationsCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    Expanded(child: mainContent),
                  ],
                ),
              ),
            ],
          ),
          // Optionally add floatingActionButton on web
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: (userRole != "user")
              ? FloatingActionButton(
                  backgroundColor: appColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddBlog()),
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  /// Decide which screen to show in main content on web (based on currentState + userRole)
  Widget buildMainContentWeb() {
    if (userRole == "admin") {
      if (userRole == "admin" && currentState == 0) {
        return const DashboardScreen();
      } else if (currentState == 1) {
        // HomeScreen with the chosen filter
        return HomeScreen(filterState: widget.filterState);
      } else if (currentState == 2) {
        return ProfileScreen();
      } else if (currentState == 3) {
        return ChatScreen();
      } else if (userRole == "customer" && currentState == 4) {
        return ShopsScreen();
      } else if (userRole == "admin") {
        if (currentState == 4) {
          return UsersScreen();
        } else if (currentState == 5) {
          return RequestsScreen();
        }
      }
      if (userRole == "admin") {
        return const DashboardScreen();
      } else {
        // fallback
        return HomeScreen(filterState: widget.filterState);
      }
    }
    if (currentState == 0) {
      // HomeScreen with the chosen filter
      return HomeScreen(filterState: widget.filterState);
    } else if (currentState == 1) {
      return ProfileScreen();
    } else if (currentState == 2) {
      return ChatScreen();
    } else if (userRole == "customer" && currentState == 3) {
      return ShopsScreen();
    } else if (userRole == "admin") {
      if (currentState == 3) {
        return UsersScreen();
      } else if (currentState == 4) {
        return RequestsScreen();
      }
    }
    // fallback
    return HomeScreen(filterState: widget.filterState);
  }

  /// The web top AppBar title
  String _getWebAppBarTitle() {
    if ( userRole == "admin"){

      if (currentState == 0) {
        return AppLocalizations.of(context)!.dashboard;
      }

     else if (currentState == 1) {
        // Might refine the title based on widget.filterState
        switch (widget.filterState) {
          case 0:
            return AppLocalizations.of(context)!.allposts;
          case 1:
            return AppLocalizations.of(context)!.barberShopPosts;
          case 2:
            return AppLocalizations.of(context)!.hospitalPosts;
        }
        return AppLocalizations.of(context)!.home;
      } else if (currentState == 2) {
        return AppLocalizations.of(context)!.profile;
      } else if (currentState == 3) {
        return AppLocalizations.of(context)!.chat;
      } else if (userRole == "customer" && currentState == 4) {
        return AppLocalizations.of(context)!.myshops;
      } else if (userRole == "admin" && currentState == 4) {
        return AppLocalizations.of(context)!.users;
      } else if (userRole == "admin" && currentState == 5) {
        return AppLocalizations.of(context)!.requests;
      }
      return AppLocalizations.of(context)!.home;
    }

    if (currentState == 0) {
      // Might refine the title based on widget.filterState
      switch (widget.filterState) {
        case 0:
          return AppLocalizations.of(context)!.allposts;
        case 1:
          return AppLocalizations.of(context)!.barberShopPosts;
        case 2:
          return AppLocalizations.of(context)!.hospitalPosts;
      }
      return AppLocalizations.of(context)!.home;
    } else if (currentState == 1) {
      return AppLocalizations.of(context)!.profile;
    } else if (currentState == 2) {
      return AppLocalizations.of(context)!.chat;
    } else if (userRole == "customer" && currentState == 3) {
      return AppLocalizations.of(context)!.myshops;
    } else if (userRole == "admin" && currentState == 3) {
      return AppLocalizations.of(context)!.users;
    } else if (userRole == "admin" && currentState == 4) {
      return AppLocalizations.of(context)!.requests;
    }
      return AppLocalizations.of(context)!.home;
  }

  // -----------------------------------------
  // Helper widgets
  // -----------------------------------------
  /// Drawer item for mobile
  Widget _drawerItem({
    required String title,
    required IconData icon,
    required bool isFocused,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isFocused ? appColorNotifier.value : appColorNotifier.value,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isFocused ? appColorNotifier.value : Colors.black,
        ),
      ),
      trailing: isFocused
          ? Container(width: 5, height: 30, color: appColorNotifier.value)
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  /// Side-nav item for the web
  Widget _webNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    int countBadge = 0,
  }) {
    final activeColor = Colors.white;
    final inactiveColor = Colors.white70;
    final color =
        isActive ? (textColor ?? activeColor) : (textColor ?? inactiveColor);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: isDrawerCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            if (countBadge > 0)
              Stack(
                children: [
                  Icon(icon, color: iconColor ?? color),
                  Positioned(
                    right: -2,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        '$countBadge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Icon(icon, color: iconColor ?? color),
            if (!isDrawerCollapsed) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Upgrade to Customer if user
  Future<void> _upgradeToCustomer() async {
    if (kIsWeb) {
      _showErrorDialog(
          "This method isn't currently available on WEB pls switch to mobile app.");
      return;
    }
    await StripeService.instance.makePayment(
      (bool paymentSuccess) async {
        if (paymentSuccess) {
          Map<String, dynamic> data = {'role': "customer"};
          var response = await networkHandler.patch(
            "/user/updateRole/$email",
            data,
          );
          if (response.statusCode == 200) {
            await storage.write(key: "role", value: "customer");
            // Send an email notification
            final serviceId = 'service_lap99wb';
            final templateId = 'template_d58o7p1';
            final userId = 'tPJQRVN9PQ2jjZ_6C';
            final url =
                Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

            final emailResponse = await http.post(
              url,
              headers: {
                'origin': "https://hajzi-6883b1f029cf.herokuapp.com",
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'service_id': serviceId,
                'template_id': templateId,
                'user_id': userId,
                'template_params': {
                  'user_name': email,
                },
              }),
            );

            print("Email Response: ${emailResponse.body}");

            final notificationResponse = await networkHandler.post(
              "/notifications/notifyAdmins/customer/$email",
              // Note: Ensure proper string interpolation
              {},
            );

            print(
                "Notification Response Code: ${notificationResponse.statusCode}");
            print("Notification Response Body: ${notificationResponse.body}");

            if (notificationResponse.statusCode == 200) {
              print("Admin notification sent successfully");
              PushNotifications.init();
            } else {
              print("Failed to notify admins");
            }

            print("User role updated successfully on server.");
            // Show success
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Congratulations!",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  content: const Text(
                    "You have successfully upgraded to Customer.",
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Close",
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                );
              },
            );

            // Reload with new role
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  setLocale: widget.setLocale,
                  filterState: 0,
                ),
              ),
              (route) => false,
            );
          } else {
            // Handle server error when updating role
            _showProfileCreationDialog();
          }
        } else {
          // Handle payment failure (e.g., user hasn't created a profile)
          _showProfileCreationDialog();
        }
      },
    );
  }

  /// Helper method to show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Feature not provided yet"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Helper method to prompt user to create a profile
  void _showProfileCreationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Profile Required"),
          content: const Text(
              "Please create a profile before upgrading to Customer."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to profile creation page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(), // Replace with your profile creation page
                  ),
                );
              },
              child: const Text(
                "Create Profile",
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Feedback (ChatBot) selection
  void _showChatBotModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.chooseMode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text(AppLocalizations.of(context)!.aiMode),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('chat_history_$email');
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatBotScreen(
                        userEmail: email,
                        isAIModeInitial: true,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.question_answer),
                title: Text(AppLocalizations.of(context)!.predefinedMode),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('chat_history_$email');
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatBotScreen(
                        userEmail: email,
                        isAIModeInitial: false,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
