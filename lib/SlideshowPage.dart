import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SlideshowPage extends StatefulWidget {
  final Function onDone;

  const SlideshowPage({Key? key, required this.onDone}) : super(key: key);

  @override
  State<SlideshowPage> createState() => _SlideshowPageState();
}

class _SlideshowPageState extends State<SlideshowPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> slides = [
    {
      "title": "Welcome to Our App!",
      "description": "Discover amazing features tailored for you.",
      "imagePath": "assets/slide1.png",
    },
    {
      "title": "Stay Connected",
      "description": "Search for the Place you would like to Appoint with.",
      "imagePath": "assets/slide2.png",
    },
    {
      "title": "Appoint Now",
      "description":
          "After Clicking the Place, Appoint now And enjoy saving time",
      "imagePath": "assets/slide3.png",
    },
    {
      "title": "Achieve More",
      "description":
          "Upgrade to Customer to achieve more features like adding your own Place.",
      "imagePath": "assets/slide4.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background and content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.green[400]!,
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
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return slidePage(
                  context,
                  title: slide["title"]!,
                  description: slide["description"]!,
                  imagePath: slide["imagePath"]!,
                );
              },
            ),
          ),

          // Left and right navigation arrows
          if (_currentPage > 0)
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: 40, color: Colors.teal),
                onPressed: () {
                  _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                },
              ),
            ),
          if (_currentPage < slides.length - 1)
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: Icon(Icons.arrow_forward, size: 40, color: Colors.teal),
                onPressed: () {
                  _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
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
                slides.length,
                (index) => buildIndicator(index == _currentPage),
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
                    backgroundColor: Colors.teal.shade500, // Button color
                    padding: const EdgeInsets.symmetric(
                        vertical: 15), // Button padding
                  ),
                  onPressed: () {
                    widget.onDone(); // Navigate to the next page
                  },
                  child: Text(
                    _currentPage == slides.length - 1
                        ? "Finish"
                        : "Get Started",
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
  }

  // Slide page widget
  Widget slidePage(BuildContext context,
      {required String title,
      required String description,
      required String imagePath}) {
    return kIsWeb //web part///////////////////
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

  // Indicator widget
  Widget buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: isActive ? 20 : 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.teal : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// class SlideshowPage extends StatelessWidget {
//   final Function onDone;
//
//   const SlideshowPage({Key? key, required this.onDone}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background and content
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.white,
//                   Colors.green[200]!,
//                 ],
//                 begin: const FractionalOffset(0.0, 1.0),
//                 end: const FractionalOffset(0.0, 1.0),
//                 stops: const [0.0, 1.0],
//                 tileMode: TileMode.repeated,
//               ),
//             ),
//             child: PageView(
//               children: [
//                 slidePage(
//                   context,
//                   title: "Welcome to Our App!",
//                   description: "Discover amazing features tailored for you.",
//                   imagePath: "assets/images/slide1.png",
//                 ),
//                 slidePage(
//                   context,
//                   title: "Stay Connected",
//                   description: "Engage with a vibrant community.",
//                   imagePath: "assets/images/slide2.png",
//                 ),
//                 slidePage(
//                   context,
//                   title: "Achieve More",
//                   description: "Use tools designed to boost your productivity.",
//                   imagePath: "assets/images/slide3.png",
//                 ),
//               ],
//               onPageChanged: (index) {
//                 // Optional: Handle events when a page changes
//               },
//             ),
//           ),
//
//           // Floating button at the bottom
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: Center(
//               child: SizedBox(
//                 height: 60,
//                 width: 200,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     backgroundColor: Colors.teal.shade500, // Button color
//                     padding: const EdgeInsets.symmetric(vertical: 15), // Button padding
//                   ),
//                   onPressed: () {
//                     onDone(); // Navigate to the next page
//                   },
//                   child: const Text(
//                     "Get Started",
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget slidePage(BuildContext context,
//       {required String title,
//         required String description,
//         required String imagePath}) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Image.asset(imagePath, height: 300, fit: BoxFit.cover),
//         const SizedBox(height: 20),
//         Text(title,
//             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 10),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20.0),
//           child: Text(description,
//               textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
//         ),
//       ],
//     );
//   }
// }
