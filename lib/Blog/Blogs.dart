import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blogapp/Blog/BlogAfterClick.dart';
import 'package:blogapp/Models/ListBlogModel.dart';
import 'package:blogapp/Models/addBlogModel.dart';
import 'package:blogapp/NetworkHandler.dart';
import '../CustomWidget/BlogCard.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Blogs extends StatefulWidget {
  final String url;
  final int flag;
  final String searchQuery; // <-- New param
  final bool isRecommendation; // new param
  const Blogs({super.key, required this.url, required this.flag, this.searchQuery = '',   this.isRecommendation = false,});

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
  @override
  void didUpdateWidget(covariant Blogs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the incoming search query changes, re-fetch data
    if (oldWidget.searchQuery != widget.searchQuery) {
      fetchData();
    }
    // Also, if the incoming url changes, we might want to re-fetch
    if (oldWidget.url != widget.url) {
      fetchData();
    }
  }
  Future<void> fetchData({String searchQuery = ''}) async {
    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    try {
      final searchText = widget.searchQuery.trim();

      final response = searchText.isNotEmpty
      // If there's a search query, call your search endpoint:
          ? await networkHandler.get("/blogpost/search?query=$searchText")
      // Otherwise, call the URL that was passed in (recommendations or filter-based):
          : await networkHandler.get(widget.url);


      listBlogModel = ListBlogModel.fromJson(response);

      setState(() {
        data = listBlogModel.data;
        _isLoading = false;
      });
    } catch (e) {
      if(mounted)
      setState(() {
        errorMessage = AppLocalizations.of(context)!.failedToLoadBlogs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading or error states
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    } else if (data.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noBlogsAvailable,
          style: const TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    // ============ HORIZONTAL LAYOUT FOR RECOMMENDATION ============ //
    if (widget.isRecommendation) {
      return SizedBox(
        height: 230,
        // Adjust this height to show smaller cards
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: data.length,
          itemBuilder: (context, index) {
            final blog = data[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: SizedBox(
                width: 220, // smaller width for smaller cards
                child: InkWell(
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
                    flag: widget.flag,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // ============ VERTICAL LAYOUT FOR “ALL SHOPS” ============ //
    // Still handle web vs mobile. If your code uses a grid for web, keep that.
    return kIsWeb
        ? GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.2,
      ),
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
            flag: widget.flag,
          ),
        );
      },
    )
        : ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
            flag: widget.flag,
          ),
        );
      },
    );
  }
}