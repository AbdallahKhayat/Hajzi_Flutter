import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blogapp/Blog/BlogAfterClick.dart';
import 'package:blogapp/Models/ListBlogModel.dart';
import 'package:blogapp/Models/addBlogModel.dart';
import 'package:blogapp/NetworkHandler.dart';
import '../CustomWidget/BlogCard.dart';

class Blogs extends StatefulWidget {
  final String url;

  const Blogs({super.key, required this.url});

  @override
  State<Blogs> createState() => _BlogsState();
}

class _BlogsState extends State<Blogs> {
  final NetworkHandler networkHandler = NetworkHandler();
  final TextEditingController _searchController = TextEditingController();

  ListBlogModel listBlogModel = ListBlogModel([]);
  List<AddBlogModel> data = [];
  bool _isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData({String searchQuery = ''}) async {
    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    try {
      final response = searchQuery.isNotEmpty
          ? await networkHandler.get("/blogpost/search?query=$searchQuery")
          : await networkHandler.get(widget.url);

      listBlogModel = ListBlogModel.fromJson(response);

      setState(() {
        data = listBlogModel.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load blogs. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: kIsWeb     //Web part//////////////////////
                ? SizedBox(
                 width: 1300,
                  child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Blogs',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            fetchData(); // Fetch all blogs when cleared
                          },
                        ),
                      ),
                      onChanged: (value) {
                        fetchData(
                            searchQuery: value); // Update results based on input
                      },
                    ),
                )
                : TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Blogs',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          fetchData(); // Fetch all blogs when cleared
                        },
                      ),
                    ),
                    onChanged: (value) {
                      fetchData(
                          searchQuery: value); // Update results based on input
                    },
                  ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage.isNotEmpty)
            Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
          else if (data.isEmpty)
            const Center(
              child: Text(
                "No Blogs Currently Available",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              // Important to avoid unbounded height
              physics: const NeverScrollableScrollPhysics(),
              // Disable scrolling for this list
              itemCount: data.length,
              itemBuilder: (context, index) {
                final blog = data[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlogAfterClick(
                          addBlogModel: blog,
                          networkHandler: networkHandler,
                        ),
                      ),
                    );
                  },
                  child: BlogCard(
                    addBlogModel: blog,
                    networkHandler: networkHandler,
                    onDelete: () => fetchData(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
