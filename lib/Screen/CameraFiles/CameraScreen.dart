import 'package:blogapp/Screen/CameraFiles/VideoView.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'CameraView.dart';

late List<CameraDescription> cameras;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late Future<void> cameravalue;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    cameravalue = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder(
            future: cameravalue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _cameraController.value.aspectRatio,
                    child: CameraPreview(_cameraController),
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
          Positioned(
            bottom: 0.0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              color: Colors.black.withOpacity(0.8),
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.flash_off,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      GestureDetector(
                        onLongPress: () async {
                          try {
                            await _cameraController.startVideoRecording();
                            setState(() {
                              isRecording = true;
                            });
                          } catch (e) {
                            print('Error starting video recording: $e');
                          }
                        },
                        onLongPressUp: () async {
                          try {
                            XFile videoFile = await _cameraController.stopVideoRecording();
                            setState(() {
                              isRecording = false;
                            });

                            print('Video recorded to: ${videoFile.path}');

                            // Navigate to VideoViewPage with the correct path
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (builder) => VideoViewPage(path: videoFile.path),
                              ),
                            );
                          } catch (e) {
                            print('Error stopping video recording: $e');
                          }
                        },
                        onTap: () {
                          if (!isRecording) takePhoto(context);
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isRecording ? Colors.red : Colors.transparent,
                                shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
                                borderRadius: isRecording ? BorderRadius.circular(12) : null,
                              ),
                              child: Icon(
                                isRecording ? Icons.stop : Icons.panorama_fish_eye,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Flip camera functionality (optional).
                        },
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Hold for Video, tap for Photo",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void takePhoto(BuildContext context) async {
    try {
      XFile picture = await _cameraController.takePicture();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (builder) => CameraViewPage(path: picture.path),
        ),
      );
    } catch (e) {
      print('Error capturing photo: $e');
    }
  }
}
