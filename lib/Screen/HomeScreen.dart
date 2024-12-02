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
  final storage = FlutterSecureStorage();
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
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
      print("Error reading user role: $e");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(
        backgroundColor: Color(0xffe9f7ef),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffe9f7ef),
      body: Blogs(
        key: ValueKey(widget.filterState,), // Enforce rebuild on filterState change
        url: _getUrlForFilterState(),
        flag: 0,
      ),
    );
  }
}
