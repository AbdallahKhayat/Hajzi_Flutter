import 'dart:convert';

import 'package:blogapp/Models/profileModel.dart';
import 'package:blogapp/services/stripe_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Blog/addBlog.dart';
import '../NetworkHandler.dart';
import '../Requests/RequestsScreen.dart';
import '../Screen/HomeScreen.dart';
import '../Profile/ProfileScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'WelcomePage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  final void Function(Locale) setLocale;

  HomePage({super.key, required this.setLocale, required this.filterState});

  int filterState = 0; // Default to "All Posts"
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final storage = FlutterSecureStorage();
  NetworkHandler networkHandler = NetworkHandler();

  int currentState = 0;

  String focusedDrawerItem = "All Posts"; // Tracks which drawer item is focused
  String username = "";
  String? userRole;

  Color appColor = Colors.teal; // Default app theme color
  String selectedLanguage = "English";

  Widget profilePhoto = Container(
    height: 100,
    width: 100,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(50),
    ),
    child: const Icon(Icons.person, size: 50, color: Colors.grey),
  );

  List<Widget> widgets = []; // Initialize as an empty list

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    checkProfile();

    widgets = [
      HomeScreen(filterState: widget.filterState),
      // "All Posts" corresponds to this
      ProfileScreen(),
      RequestsScreen(),
    ];
  }

  Future<void> _loadUserRole() async {
    final role = await storage.read(key: "role");
    setState(() {
      userRole = role;
    });
  }

  void checkProfile() async {
    var response = await networkHandler.get("/profile/checkProfile");
    setState(() {
      username = response["username"] ?? "Username";
      profilePhoto = CircleAvatar(
        radius: 50,
        backgroundImage: response["username"] != null
            ? NetworkHandler().getImage(response["username"])
            : null,
        child: response["username"] == null
            ? const Icon(Icons.person, size: 50, color: Colors.grey)
            : null,
      );
    });
  }

  void pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = appColor; // Preview color
        return AlertDialog(
          title: const Text('Pick a Theme Color'),
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
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Select'),
              onPressed: () {
                setState(() {
                  appColor = tempColor;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    List<String> languages = ["English", "Arabic"];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Language"),
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
                      Locale newLocale = selectedLanguage == "Arabic"
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
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
                    '@$username',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(
              title: AppLocalizations.of(context)!.allposts,
              icon: Icons.launch,
              isFocused: focusedDrawerItem == "All Posts",
              onTap: () {
                setState(() {
                  focusedDrawerItem = "All Posts";
                  widget.filterState = 0;
                  widgets[0] = HomeScreen(
                      filterState: widget.filterState); // Update HomeScreen
                });
                Navigator.pop(context);
              },
            ),
            _drawerItem(
              title: AppLocalizations.of(context)!.barberShopPosts,
              icon: Icons.content_cut,
              isFocused: focusedDrawerItem == "BarberShop Posts",
              onTap: () {
                setState(() {
                  focusedDrawerItem = "BarberShop Posts";
                  widget.filterState = 1;
                  widgets[0] = HomeScreen(
                      filterState: widget.filterState); // Update HomeScreen
                });
                Navigator.pop(context);
              },
            ),
            _drawerItem(
              title: AppLocalizations.of(context)!.hospitalPosts,
              icon: Icons.local_hospital,
              isFocused: focusedDrawerItem == "Hospital Posts",
              onTap: () {
                setState(() {
                  focusedDrawerItem = "Hospital Posts";
                  widget.filterState = 2;
                  widgets[0] = HomeScreen(
                      filterState: widget.filterState); // Update HomeScreen
                });
                Navigator.pop(context);
              },
            ),
            _drawerItem(
              title: AppLocalizations.of(context)!.newstory,
              icon: Icons.add,
              isFocused: focusedDrawerItem == "New Story",
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
              isFocused: focusedDrawerItem == "Settings",
              onTap: () {
                pickColor(context);
              },
            ),
            _drawerItem(
              title: AppLocalizations.of(context)!.changelanguage,
              icon: Icons.language,
              isFocused: focusedDrawerItem == "Change Language",
              onTap: () {
                _showLanguageDialog(context);
              },
            ),
            if (userRole == "user")
              ListTile(
                leading: Icon(Icons.credit_card, color: appColor),
                title: Text(
                  AppLocalizations.of(context)!.customer,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () async {
                  print(username);

                  // Call the payment method with a callback
                  await StripeService.instance
                      .makePayment((bool paymentSuccess) async {
                    if (paymentSuccess) {
                      print("Payment successful. Updating role...");
                      Map<String, dynamic> data = {'role': "customer"};
                      var response = await networkHandler.patch(
                        "/user/updateRole/$username",
                        data,
                      );
                      if (response.statusCode == 200) {
                        // Send an email notification
                        final serviceId = 'service_lap99wb';
                        final templateId = 'template_d58o7p1';
                        final userId = 'tPJQRVN9PQ2jjZ_6C';
                        final url = Uri.parse(
                            'https://api.emailjs.com/api/v1.0/email/send');

                        final emailResponse = await http.post(
                          url,
                          headers: {
                            'origin': "http://192.168.88.7:5000",
                            'Content-Type': 'application/json',
                          },
                          body: json.encode({
                            'service_id': serviceId,
                            'template_id': templateId,
                            'user_id': userId,
                            'template_params': {
                              'user_name': username,
                            },
                          }),
                        );

                        print("Email Response: ${emailResponse.body}");
                        print("User role updated successfully on server.");
                      } else {
                        print(
                            "Failed to update user role on server: Status code ${response.statusCode}");
                      }
                    } else {
                      print(
                          "Payment failed or was cancelled. Role not updated.");
                    }
                  });
                },
              ),
            if (userRole == "customer")
              ListTile(
                leading: Icon(Icons.feedback, color: appColor),
                title: Text(
                  AppLocalizations.of(context)!.feedback,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
            Divider(thickness: 1, color: Colors.grey.shade400),
            ListTile(
              leading: Icon(Icons.power_settings_new, color: Colors.red),
              title: Text(
                AppLocalizations.of(context)!.logout,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red),
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                logout();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: appColor,
        title: Text(
          // titleString[currentState],

          currentState == 0
              ? AppLocalizations.of(context)!.home
              : currentState == 1
                  ? AppLocalizations.of(context)!.profile
                  : AppLocalizations.of(context)!.requests,
          // Assuming "requests" for `currentState == 2`
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.black,
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: userRole != "user"
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentState,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        backgroundColor: appColor,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
          if (userRole == "admin")
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_business),
              label: AppLocalizations.of(context)!.requests,
            ),
        ],
        onTap: (index) => setState(() {
          currentState = index;
        }),
      ),
      body: widgets[currentState],
    );
  }

  Widget _drawerItem({
    required String title,
    required IconData icon,
    required bool isFocused,
    required VoidCallback onTap,
    Color? iconColor, // Default null; fallback to appColor
    Color textColor = Colors.black,
  }) {
    return kIsWeb
        ? SizedBox(
         height: 120,
          child: ListTile(
              leading: Icon(
                icon,
                color: isFocused
                    ? appColor
                    : (iconColor ?? appColor), // Dynamically set the icon color
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isFocused ? appColor : textColor,
                ),
              ),
              trailing: isFocused
                  ? Container(
                      width: 5,
                      height: 30,
                      color: appColor) // Highlight focused item
                  : const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: onTap,
            ),
        )
        : ListTile(
            leading: Icon(
              icon,
              color: isFocused
                  ? appColor
                  : (iconColor ?? appColor), // Dynamically set the icon color
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isFocused ? appColor : textColor,
              ),
            ),
            trailing: isFocused
                ? Container(
                    width: 5,
                    height: 30,
                    color: appColor) // Highlight focused item
                : const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: onTap,
          );
  }
}

// import 'package:blogapp/Models/profileModel.dart';
// import 'package:blogapp/services/stripe_service.dart';
// import 'package:flutter/material.dart';
//
// import '../Blog/addBlog.dart';
// import '../NetworkHandler.dart';
// import '../Requests/RequestsScreen.dart';
// import '../Screen/HomeScreen.dart';
// import '../Profile/ProfileScreen.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'WelcomePage.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
//
// class HomePage extends StatefulWidget {
//   final void Function(Locale) setLocale;
//   const HomePage({super.key,required this.setLocale});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   bool isLoading = true;
//
//   final storage = FlutterSecureStorage();
//
//   int currentState = 0;
//   List<Widget> widgets = [
//     //to switch between screens on body
//     HomeScreen(),
//     ProfileScreen(),
//     RequestsScreen(),
//   ];
//
//   List<String> titleString = ["Home Page", "Profile Page"];
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _loadUserRole();
//     checkProfile();
//   }
//
//   NetworkHandler networkHandler = NetworkHandler();
//   ProfileModel profileModel = ProfileModel();
//
//   String? userRole;
//
//
//   // Load the user role from secure storage
//   Future<void> _loadUserRole() async {
//     final role = await storage.read(key: "role"); // Assume the role is stored under the "role" key
//     setState(() {
//       userRole = role; // Update userRole when data is loaded
//     });
//   }
//
//
//
//
//   void checkProfile() async {
//     var response = await networkHandler.get("/profile/checkProfile");
//     setState(() {
//       username=response["username"];
//     });
//     if (response["Status"] == true) {
//       //if status is true (200)
//       setState(() {
//         profilePhoto = CircleAvatar(
//           radius: 50,
//           backgroundImage: response["username"] == null
//               ? null
//               : NetworkHandler().getImage(response["username"]),
//         );
//       });
//     } else {
//       setState(() {
//         profilePhoto = Container(
//           height: 100,
//           width: 100,
//           decoration: BoxDecoration(
//             color: Colors.black,
//             borderRadius: BorderRadius.circular(50),
//           ),
//         );
//       });
//     }
//   }
//   String username="";
//
//   Widget profilePhoto = Container(
//     height: 100,
//     width: 100,
//     decoration: BoxDecoration(
//       color: Colors.black,
//       borderRadius: BorderRadius.circular(50),
//     ),
//   );
//
//   Color appColor = Colors.teal; // Default color
//   String selectedLanguage = "English"; // Default language
//
//
//
//   void _showLanguageDialog(BuildContext context) {
//     List<String> languages = ["English", "Arabic"]; // Add your supported languages here
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text("Select Language"),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: languages.map((language) {
//                 return RadioListTile(
//                   title: Text(language),
//                   value: language,
//                   groupValue: selectedLanguage, // Tracks the selected language
//                   onChanged: (value) async {
//                     setState(() {
//                       selectedLanguage = value!; // Update selected language
//                       Locale newLocale;
//                       switch (selectedLanguage) {
//                         case "Arabic":
//                           newLocale = Locale('ar', 'AE');
//                           break;
//                         case "English":
//                         default:
//                           newLocale = Locale('en', 'US');
//                           break;
//                       }
//                       widget.setLocale(newLocale); // Use global setLocale
//                     });
//                     Navigator.of(context).pop(); // Close the dialog
//                   },
//                 );
//               }).toList(),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//
//   void pickColor(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         Color tempColor = appColor; // Temporary color for preview
//         return AlertDialog(
//           title: Text('Pick a Theme Color'),
//           content: SingleChildScrollView(
//             child: BlockPicker(
//               pickerColor: tempColor,
//               onColorChanged: (color) {
//                 tempColor = color; // Preview selected color
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text('Select'),
//               onPressed: () {
//                 setState(() {
//                   appColor = tempColor; // Apply the selected color
//                 });
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//   void logout() async {
//     await storage.delete(key: "token");
//     //for language part
//   //  await storage.delete(key: "language"); // Optional: Reset language preference
//   //  widget.setLocale(const Locale('en', 'US')); // Reset locale to default
//
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) => WelcomePage(setLocale: widget.setLocale,)),
//           (route) => false,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: Drawer(
//         child: ListView(
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [appColor.withOpacity(0.8), appColor],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   profilePhoto,
//                   SizedBox(height: 10),
//                   Text(
//                     '@$username' ?? "@Username",
//                     style: TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.launch, color: appColor),
//               title: Text(
//                 AppLocalizations.of(context)!.allposts,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               ),
//               trailing: Icon(Icons.chevron_right, color: Colors.grey),
//               onTap: () {},
//             ),
//             ListTile(
//               leading: Icon(Icons.add, color: appColor),
//               title: Text(
//                 AppLocalizations.of(context)!.newstory,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               ),
//               trailing: Icon(Icons.chevron_right, color: Colors.grey),
//               onTap: () {},
//             ),
//             ListTile(
//               leading: Icon(Icons.settings, color: appColor),
//               title: Text(
//                 AppLocalizations.of(context)!.settings,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               ),
//               trailing: Icon(Icons.chevron_right, color: Colors.grey),
//               onTap: () {
//                 pickColor(context);
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.language, color: appColor),
//               title: Text(
//                 AppLocalizations.of(context)!.changelanguage,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               ),
//               trailing: Icon(Icons.chevron_right, color: Colors.grey),
//               onTap: () {
//                 _showLanguageDialog(context);
//               },
//             ),
//             if(userRole=="user")
//               ListTile(
//                 leading: Icon(Icons.credit_card, color: appColor),
//                 title: Text(
//                   AppLocalizations.of(context)!.customer,
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),
//                 trailing: Icon(Icons.chevron_right, color: Colors.grey),
//                 onTap: () async {
//                   print(username);
//
//                   // Call the payment method with a callback
//                   await StripeService.instance.makePayment((bool paymentSuccess) async {
//                     if (paymentSuccess) {
//                       print("Payment successful. Updating role...");
//                       Map<String, dynamic> data = {'role': "customer"};
//                       var response = await networkHandler.patch(
//                         "/user/updateRole/$username",
//                         data,
//                       );
//                       if (response.statusCode == 200) {
//                         print("User role updated successfully on server.");
//                       } else {
//                         print("Failed to update user role on server: Status code ${response.statusCode}");
//                       }
//                     } else {
//                       print("Payment failed or was cancelled. Role not updated.");
//                     }
//                   });
//                 },
//               ),
//
//             if(userRole=="customer")
//             ListTile(
//               leading: Icon(Icons.feedback, color: appColor),
//               title: Text(
//                 AppLocalizations.of(context)!.feedback,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               ),
//               trailing: Icon(Icons.chevron_right, color: Colors.grey),
//               onTap: () {},
//             ),
//             Divider(thickness: 1, color: Colors.grey.shade400),
//             ListTile(
//               leading: Icon(Icons.power_settings_new, color: Colors.red),
//               title: Text(
//                 AppLocalizations.of(context)!.logout,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
//               ),
//               trailing: Icon(Icons.chevron_right, color: Colors.grey),
//               onTap: () {
//                 logout();
//               },
//             ),
//           ],
//         ),
//       ),
//
//       appBar: AppBar(
//         backgroundColor: appColor,
//         title: Text(
//         // titleString[currentState],
//
//             currentState == 0
//                 ? AppLocalizations.of(context)!.home
//                 : currentState == 1
//                 ? AppLocalizations.of(context)!.profile
//                 : AppLocalizations.of(context)!.requests, // Assuming "requests" for `currentState == 2`
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//
//         ),
//         centerTitle: true,
//         actions: <Widget>[
//           IconButton(
//               icon: Icon(Icons.notifications),
//               color: Colors.black,
//               onPressed: () {})
//         ],
//       ),
//
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//
//       floatingActionButton: userRole!="user"?FloatingActionButton(
//         backgroundColor: appColor,
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddBlog(),
//             ),
//           );
//         },
//         shape: CircleBorder(),
//         child: const Text(
//           "+",
//           style: TextStyle(
//             fontSize: 40,
//             color: Colors.black,
//           ),
//         ),
//       ):null,
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: currentState,
//         selectedItemColor: Colors.white,
//         unselectedItemColor: Colors.black,
//         backgroundColor: appColor,
//         items: [
//           BottomNavigationBarItem(
//               icon: Icon(Icons.home), label: AppLocalizations.of(context)!.home),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.person), label: AppLocalizations.of(context)!.profile),
//           if(userRole=="admin")
//           BottomNavigationBarItem(
//               icon: Icon(Icons.add_business), label: AppLocalizations.of(context)!.requests),
//         ],
//         onTap: (index) => setState(() => currentState = index),
//       ),
//       body: widgets[currentState],
//     );
//
//
//   }
//
//
// //   void logout() async {
// //     //delete token that we stored from the login page/register page
// // //since token is null we will go to welcome page from (main.dart)
// //
// //     await storage.delete(key: "token");
// //     Navigator.pushAndRemoveUntil(
// //         context,
// //         MaterialPageRoute(builder: (context) => WelcomePage()),
// //         (route) =>
// //             false); // when user presses logout it will go to welcome page
// //     //and then if the user press back button it will go to home page
// //     //to fix this issue use pushAndRemoveUntil(remove homePage from stack)
// //   }
//
//
// }
