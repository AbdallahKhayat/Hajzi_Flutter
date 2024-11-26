import 'package:flutter/material.dart';
import 'package:blogapp/NetworkHandler.dart';

class BlogsChatPage extends StatefulWidget {
  final String blogId; // Accept the blogId to fetch details

  const BlogsChatPage({super.key, required this.blogId});

  @override
  State<BlogsChatPage> createState() => _BlogsChatPageState();
}

class _BlogsChatPageState extends State<BlogsChatPage> {
  NetworkHandler networkHandler = NetworkHandler();
  String blogTitle = "";
  String authorName = "";

  @override
  void initState() {
    super.initState();
    fetchBlogDetails();
  }

  Future<void> fetchBlogDetails() async {
    try {
      final response = await networkHandler.get("/blogpost/getBlogDetails/${widget.blogId}");
      if (response['blogTitle'] != null && response['authorName'] != null) {
        setState(() {
          blogTitle = response['blogTitle'];
          authorName = response['authorName'];
        });
      }
    } catch (e) {
      print("Error fetching blog details: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: blogTitle.isEmpty || authorName.isEmpty
            ? Text("Loading...")
            : Text("$authorName - $blogTitle"),
        centerTitle: true,
      ),
      body: Center(
        child: Text("Chat functionality will go here."),
      ),
    );
  }
}
