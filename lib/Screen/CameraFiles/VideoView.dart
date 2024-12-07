import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoViewPage extends StatefulWidget {
  const VideoViewPage({super.key, required this.path});
  final String path;

  @override
  State<VideoViewPage> createState() => _VideoViewPageState();
}

class _VideoViewPageState extends State<VideoViewPage> {
  VideoPlayerController? _controller; // Nullable to avoid late initialization error
  bool isLoading = true; // Used to show loader while video is being initialized
  bool videoLoaded = false; // Indicates if the video is fully loaded
  String errorMessage = ''; // To display why the video failed to load

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      print('Waiting for file to be available...');

      // 1. Ensure the file exists (it may take a few milliseconds to appear)
      int retries = 0;
      while (!File(widget.path).existsSync()) {
        await Future.delayed(const Duration(milliseconds: 200)); // Retry every 200ms
        retries++;
        if (retries > 50) { // Give up after 10 seconds
          print('File not found after 10 seconds: ${widget.path}');
          setState(() {
            isLoading = false;
            errorMessage = 'File not found after 10 seconds';
          });
          return;
        }
      }

      print('File is available at path: ${widget.path}');

      // 2. Initialize the VideoPlayerController
      _controller = VideoPlayerController.file(File(widget.path));

      await _controller!.initialize(); // Ensure the controller is initialized

      setState(() {
        isLoading = false; // Hide the loader
        videoLoaded = true; // Video is ready to play
      });

      print('Video initialized successfully');
    } catch (e) {
      print('Error initializing video: $e');
      setState(() {
        isLoading = false; // Stop the loader
        errorMessage = 'Failed to initialize video: $e'; // Show error message
        videoLoaded = false; // Show error if video failed to load
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Dispose of the controller if it's not null
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.crop_rotate, size: 28),
            tooltip: "Crop & Rotate",
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.emoji_emotions_outlined, size: 28),
            tooltip: "Add Emoji",
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.title, size: 28),
            tooltip: "Add Text",
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 28),
            tooltip: "Edit Video",
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: isLoading
                ? const CircularProgressIndicator(
              color: Colors.white,
            )
                : _controller != null && _controller!.value.isInitialized
                ? LayoutBuilder(
              builder: (context, constraints) {
                double screenWidth = constraints.maxWidth;
                double screenHeight = constraints.maxHeight;
                double videoAspectRatio = _controller!.value.aspectRatio;

                double videoWidth = screenWidth;
                double videoHeight = screenHeight;

                if (screenWidth / screenHeight > videoAspectRatio) {
                  videoWidth = screenHeight * videoAspectRatio;
                } else {
                  videoHeight = screenWidth / videoAspectRatio;
                }

                return Center(
                  child: SizedBox(
                    width: videoWidth,
                    height: videoHeight,
                    child: VideoPlayer(_controller!),
                  ),
                );
              },
            )
                : Center(
              child: Text(
                errorMessage.isNotEmpty
                    ? errorMessage
                    : 'Failed to load video',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_controller != null && _controller!.value.isInitialized)
            Align(
              alignment: Alignment.center,
              child: InkWell(
                onTap: () {
                  if (_controller != null && _controller!.value.isInitialized) {
                    setState(() {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                      } else {
                        _controller!.play();
                      }
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 33,
                  backgroundColor: Colors.black38,
                  child: Icon(
                    _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
