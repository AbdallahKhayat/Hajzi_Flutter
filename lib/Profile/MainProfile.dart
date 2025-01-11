import 'package:blogapp/Models/profileModel.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Blog/Blogs.dart';
import 'EditProfile.dart';

class MainProfile extends StatefulWidget {
  const MainProfile({Key? key}) : super(key: key);

  @override
  State<MainProfile> createState() => _MainProfileState();
}

class _MainProfileState extends State<MainProfile> {
  bool circular = true;
  NetworkHandler networkHandler = NetworkHandler();
  ProfileModel profileModel = ProfileModel();

  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    fetchData();
  }

  // Load the user role from secure storage
  Future<void> _loadUserRole() async {
    final role = await storage.read(key: "role");
    setState(() {
      userRole = role;
    });
  }

  void fetchData() async {
    var response = await networkHandler.get("/profile/getData");
    if (mounted) {
      setState(() {
        // Data is within 'data' key
        profileModel = ProfileModel.fromJson(response["data"]);
        circular = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: circular
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            title: Text(
              profileModel.name ?? AppLocalizations.of(context)!.profile,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
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
                    // Re-fetch data if needed
                    fetchData();
                  }
                },
                color: Colors.white,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (profileModel.img != null &&
                      profileModel.img!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: profileModel.img!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          Container(color: Colors.grey),
                    )
                  else
                    Container(
                      color: Colors.grey,
                      child: const Center(
                        child: Text(
                          "No Image Available",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  // A subtle gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body content
          SliverList(
            delegate: SliverChildListDelegate(
              [
                // Header with profile picture, email, etc.
                _buildProfileHeader(context),

                const Divider(thickness: 1),

                // Info sections without Cards (using Container)
                _buildInfoSection(
                  context,
                  label: AppLocalizations.of(context)!.about,
                  value:
                  profileModel.about ?? "No information available",
                ),
                _buildInfoSection(
                  context,
                  label: AppLocalizations.of(context)!.name,
                  value: profileModel.name ?? "No name provided",
                ),
                _buildInfoSection(
                  context,
                  label: AppLocalizations.of(context)!.profession,
                  value:
                  profileModel.profession ?? "No profession listed",
                ),
                _buildInfoSection(
                  context,
                  label: AppLocalizations.of(context)!.dob,
                  value: profileModel.DOB ?? "No date of birth provided",
                ),

                const Divider(thickness: 1),

                // Uncomment if you want to show user blogs
                // if (userRole == "customer") ...[
                //   Padding(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 16.0,
                //       vertical: 12.0,
                //     ),
                //     child: Text(
                //       AppLocalizations.of(context)!.myblogs,
                //       style: const TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                //   Blogs(url: "/blogpost/getOwnBlog"),
                // ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the top section with avatar, email, and title line.
  Widget _buildProfileHeader(BuildContext context) {
    final double avatarRadius = 50;
    final double horizontalPadding =
    kIsWeb ? MediaQuery.of(context).size.width * 0.25 : 16;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          // Subtle background to make it stand out
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: (profileModel.img != null &&
                  profileModel.img!.isNotEmpty)
                  ? CachedNetworkImageProvider(profileModel.img!)
                  : const AssetImage('assets/images/placeholder.png')
              as ImageProvider,
            ),
            const SizedBox(height: 16),
            Text(
              profileModel.email ?? "Email not available",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profileModel.titleline ?? "Title line not available",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build each info section with a labeled row (no Card).
  Widget _buildInfoSection(
      BuildContext context, {
        required String label,
        required String value,
      }) {
    final double horizontalPadding =
    kIsWeb ? MediaQuery.of(context).size.width * 0.25 : 16;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              offset: const Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: kIsWeb ? 20 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            // Value
            Text(
              value,
              style: TextStyle(
                fontSize: kIsWeb ? 18 : 14,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
