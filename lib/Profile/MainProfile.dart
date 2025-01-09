import 'package:blogapp/Models/profileModel.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Blog/Blogs.dart';
import 'EditProfile.dart';

class MainProfile extends StatefulWidget {
  const MainProfile({super.key});

  @override
  State<MainProfile> createState() => _MainProfileState();
}

class _MainProfileState extends State<MainProfile> {
  bool circular = true;
  NetworkHandler networkHandler = NetworkHandler();
  ProfileModel profileModel = ProfileModel();

  final FlutterSecureStorage storage = FlutterSecureStorage();
  String? userRole;

  // Load the user role from secure storage
  Future<void> _loadUserRole() async {
    final role = await storage.read(key: "role");
    setState(() {
      userRole = role;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Load the role when the widget is initialized
    fetchData();
  }

  void fetchData() async {
    var response = await networkHandler.get("/profile/getData");
    if(mounted)
    setState(() {
      profileModel =
          ProfileModel.fromJson(response["data"]); // Data within 'data'
      circular = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: circular
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.blueAccent,
                  expandedHeight: 200,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      profileModel.name ?? "Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: profileModel.img != null
                        ? CachedNetworkImage(
                      imageUrl: profileModel.img!,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      fit: BoxFit.cover,
                    )
                        : Container(
                            color: Colors.grey,
                            child: Center(
                              child: Text(
                                "No Image Available",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () async {
                        var updatedData = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfile(profileModel: profileModel),
                          ),
                        );
                        if (updatedData != null) {
                          setState(() {
                            profileModel = ProfileModel.fromJson(updatedData);
                          });
                          fetchData();

                        }

                      },
                      color: Colors.white,
                    ),
                  ],
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildProfileHeader(context),
                      Divider(thickness: 1),
                      _buildInfoCard(
                        context,
                        AppLocalizations.of(context)!.about,
                        profileModel.about ?? "No information available",
                      ),
                      _buildInfoCard(
                        context,
                        AppLocalizations.of(context)!.name,
                        profileModel.name ?? "No name provided",
                      ),
                      _buildInfoCard(
                        context,
                        AppLocalizations.of(context)!.profession,
                        profileModel.profession ?? "No profession listed",
                      ),
                      _buildInfoCard(
                        context,
                        AppLocalizations.of(context)!.dob,
                        profileModel.DOB ?? "No date of birth provided",
                      ),
                      Divider(thickness: 1),
                      // if (userRole == "customer")
                      //   Padding(
                      //     padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      //     child: Text(
                      //       AppLocalizations.of(context)!.myblogs,
                      //       style: TextStyle(
                      //         fontSize: 18,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ),
                      // if (userRole == "customer")
                      //   Blogs(url: "/blogpost/getOwnBlog"),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileModel.img != null
                  ? CachedNetworkImageProvider(profileModel.img!)
                  : AssetImage('assets/images/placeholder.png') as ImageProvider, // Use a placeholder image
              backgroundColor: Colors.grey.shade300,
            ),
            SizedBox(height: 10),
            Text(
              profileModel.email ?? "Email not available",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              profileModel.titleline ?? "Title line not available",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value) {
    return kIsWeb
        ? Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 300, vertical: 8.0),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  label,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  value,
                  style: TextStyle(fontSize: 27, color: Colors.grey.shade700),
                ),
              ),
            ),
          )
        : Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  value,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ),
            ),
          );
  }
}

// return Scaffold(
// appBar: AppBar(
// elevation: 0,
// // leading: IconButton(
// //   icon: Icon(Icons.arrow_back),
// //   onPressed: () {},
// //   color: Colors.black,
// // ),
// actions: [
// IconButton(
// icon: Icon(Icons.edit),
// onPressed: () async {
// var updatedData = await Navigator.push(
// context,
// MaterialPageRoute(
// builder: (context) => EditProfile(profileModel: profileModel),
// ),
// );
// if (updatedData != null) {
// setState(() {
// profileModel = ProfileModel.fromJson(updatedData);
// });
// }
// },
// color: Colors.black,
// ),
// ],
// ),
// body:circular?Center(child: CircularProgressIndicator()): ListView(
// children: [
// head(),
// Divider(
// thickness: 0.8,
// ),
// otherDetails("About", profileModel.about ?? "No information available"),
// otherDetails("Name", profileModel.name ?? "No name provided"),
// otherDetails("Profession", profileModel.profession ?? "No profession listed"),
// otherDetails("DOB", profileModel.DOB ?? "No date of birth provided"),
//
//
// Divider(
// thickness: 0.8,
// ),
// SizedBox(
// height: 20,
// ),
// Blogs(url: "/blogpost/getOwnBlog"),
// ],
// ),
// );
