import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:blogapp/constants.dart'; // Contains appColorNotifier

class SlideshowPage extends StatefulWidget {
  final Function onDone;

  const SlideshowPage({Key? key, required this.onDone}) : super(key: key);

  @override
  State<SlideshowPage> createState() => _SlideshowPageState();
}

class _SlideshowPageState extends State<SlideshowPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Only image paths are stored here.
  final List<String> slideImagePaths = [
    "assets/slide1.png",
    "assets/slide2.png",
    "assets/slide3.png",
    "assets/slide4.png",
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: appColorNotifier,
      builder: (context, mainColor, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background and slide content
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      mainColor.withOpacity(0.7),
                    ],
                    begin: const FractionalOffset(0.0, 1.0),
                    end: const FractionalOffset(0.0, 1.0),
                    stops: const [0.0, 1.0],
                    tileMode: TileMode.repeated,
                  ),
                ),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: slideImagePaths.length,
                  itemBuilder: (context, index) {
                    // Retrieve localized title and description based on index.
                    String title;
                    String description;
                    switch (index) {
                      case 0:
                        title = AppLocalizations.of(context)!.slide1Title;
                        description =
                            AppLocalizations.of(context)!.slide1Description;
                        break;
                      case 1:
                        title = AppLocalizations.of(context)!.slide2Title;
                        description =
                            AppLocalizations.of(context)!.slide2Description;
                        break;
                      case 2:
                        title = AppLocalizations.of(context)!.slide3Title;
                        description =
                            AppLocalizations.of(context)!.slide3Description;
                        break;
                      case 3:
                        title = AppLocalizations.of(context)!.slide4Title;
                        description =
                            AppLocalizations.of(context)!.slide4Description;
                        break;
                      default:
                        title = "";
                        description = "";
                    }
                    return slidePage(
                      context,
                      title: title,
                      description: description,
                      imagePath: slideImagePaths[index],
                    );
                  },
                ),
              ),

              // Left navigation arrow
              if (_currentPage > 0)
                Positioned(
                  left: 20,
                  top: MediaQuery.of(context).size.height / 2 - 30,
                  child: IconButton(
                    icon: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Icon(
                        Icons.arrow_back,
                        size: 40,
                        color: mainColor,
                      ),
                    ),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              // Right navigation arrow
              if (_currentPage < slideImagePaths.length - 1)
                Positioned(
                  right: 20,
                  top: MediaQuery.of(context).size.height / 2 - 30,
                  child: IconButton(
                    icon: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Icon(
                        Icons.arrow_forward,
                        size: 40,
                        color: mainColor,
                      ),
                    ),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),

              // Slide indicators
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slideImagePaths.length,
                        (index) =>
                        buildIndicator(index == _currentPage, mainColor),
                  ),
                ),
              ),

              // Floating button at the bottom
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Center(
                  child: SizedBox(
                    height: 60,
                    width: 200,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: mainColor, // Main app color is used here
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        widget.onDone(); // Navigate to the next page
                      },
                      child: Text(
                        _currentPage == slideImagePaths.length - 1
                            ? AppLocalizations.of(context)!.finish
                            : AppLocalizations.of(context)!.getStarted,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget for an individual slide page.
  Widget slidePage(BuildContext context,
      {required String title,
        required String description,
        required String imagePath}) {
    return kIsWeb
        ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath,
            width: 300, height: 580, fit: BoxFit.fill),
        const SizedBox(height: 20),
        Text(title,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
        ),
      ],
    )
        : Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath,
            width: 170, height: 370, fit: BoxFit.cover),
        const SizedBox(height: 20),
        Text(title,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  // Indicator widget that uses mainColor for the active dot.
  Widget buildIndicator(bool isActive, Color mainColor) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: isActive ? 20 : 10,
      decoration: BoxDecoration(
        color: isActive ? mainColor : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
