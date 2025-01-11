import 'package:flutter/material.dart';

import '../Blog/Blogs.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Blogs(
          url: "/blogpost/getOwnBlog",
          flag: 1,
        ),
      ),
    );
  }
}
