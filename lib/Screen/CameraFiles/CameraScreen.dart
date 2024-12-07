import 'package:blogapp/Screen/CameraFiles/VideoView.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

import 'CameraView.dart';

late List<CameraDescription> cameras;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  Future<void>? cameravalue;
  bool isRecording = false;
  bool isFrontCamera = false;
  FlashMode currentFlashMode = FlashMode.off;
  bool isCameraLoading = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  // Initialize the camera
  void initializeCamera() {
    setState(() {
      isCameraLoading = true;
      cameravalue = null;
    });

    _cameraController = CameraController(
      isFrontCamera ? cameras[1] : cameras[0],
      ResolutionPreset.high,
    );

    cameravalue = _cameraController.initialize().then((_) {
      _cameraController.setFlashMode(currentFlashMode);
      setState(() {
        isCameraLoading = false;
      });
    }).catchError((e) {
      print('Error initializing camera: $e');
      setState(() {
        isCameraLoading = false;
      });
    });
  }

  // Flip the camera
  void flipCamera() async {
    setState(() {
      isCameraLoading = true;
      isFrontCamera = !isFrontCamera;
    });

    await _cameraController.dispose();
    initializeCamera();
  }

  // Toggle flash mode
  void toggleFlashMode() {
    setState(() {
      switch (currentFlashMode) {
        case FlashMode.off:
          currentFlashMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          currentFlashMode = FlashMode.always;
          break;
        case FlashMode.always:
          currentFlashMode = FlashMode.torch;
          break;
        case FlashMode.torch:
          currentFlashMode = FlashMode.off;
          break;
        default:
          currentFlashMode = FlashMode.off;
      }
    });

    if (_cameraController.value.isInitialized) {
      _cameraController.setFlashMode(currentFlashMode);
    }
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
          if (!isCameraLoading)
            FutureBuilder(
              future: cameravalue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final screenHeight = constraints.maxHeight;
                      final cameraAspectRatio = _cameraController.value.aspectRatio;

                      double previewWidth;
                      double previewHeight;

                      if (screenWidth / screenHeight > cameraAspectRatio) {
                        previewWidth = screenWidth;
                        previewHeight = screenWidth / cameraAspectRatio;
                      } else {
                        previewHeight = screenHeight;
                        previewWidth = screenHeight * cameraAspectRatio;
                      }

                      return Center(
                        child: ClipRect(
                          child: OverflowBox(
                            maxWidth: previewWidth,
                            maxHeight: previewHeight,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: screenWidth,
                                height: screenHeight,
                                child: isFrontCamera
                                    ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(3.14159), // Mirror front camera
                                  child: CameraPreview(_cameraController),
                                )
                                    : CameraPreview(_cameraController),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            )
          else
            Container(
              color: Colors.black,
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
                        onPressed: toggleFlashMode,
                        icon: Icon(
                          currentFlashMode == FlashMode.off
                              ? Icons.flash_off
                              : currentFlashMode == FlashMode.auto
                              ? Icons.flash_auto
                              : currentFlashMode == FlashMode.always
                              ? Icons.flash_on
                              : Icons.highlight,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      GestureDetector(
                        onLongPressStart: (details) async {
                          try {
                            await _cameraController.setFlashMode(currentFlashMode);
                            await _cameraController.startVideoRecording();
                            setState(() {
                              isRecording = true;
                            });
                          } catch (e) {
                            print('Error starting video recording: $e');
                          }
                        },
                        onLongPressEnd: (details) async {
                          if (isRecording) {
                            try {
                              // Stop recording
                              XFile videoFile = await _cameraController.stopVideoRecording();

                              // Delay to ensure file finalization
                              await Future.delayed(const Duration(milliseconds: 500));

                              // Check if file exists and has a valid size
                              final file = File(videoFile.path);
                              if (file.existsSync() && file.lengthSync() > 0) {
                                setState(() {
                                  isRecording = false;
                                });

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (builder) => VideoViewPage(path: videoFile.path),
                                  ),
                                );
                              } else {
                                // Handle invalid file gracefully
                                setState(() {
                                  isRecording = false;
                                });
                                print('Error: Video file is invalid or empty!');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Video recording failed. Please try again.")),
                                );
                              }
                            } catch (e) {
                              print('Error stopping video recording: $e');
                              setState(() {
                                isRecording = false;
                              });
                            }
                          }
                        },
                        onTap: () async {
                          if (isRecording) {
                            // Force stop recording
                            try {
                              XFile videoFile = await _cameraController.stopVideoRecording();

                              // Delay to ensure file finalization
                              await Future.delayed(const Duration(milliseconds: 500));

                              // Check if file exists and has a valid size
                              final file = File(videoFile.path);
                              if (file.existsSync() && file.lengthSync() > 0) {
                                setState(() {
                                  isRecording = false;
                                });

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (builder) => VideoViewPage(path: videoFile.path),
                                  ),
                                );
                              } else {
                                // Handle invalid file gracefully
                                setState(() {
                                  isRecording = false;
                                });
                                print('Error: Video file is invalid or empty!');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Video recording failed. Please try again.")),
                                );
                              }
                            } catch (e) {
                              print('Error forcing stop video recording: $e');
                              setState(() {
                                isRecording = false;
                              });
                            }
                          } else {
                            takePhoto(context);
                          }
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
                                shape: BoxShape.circle,
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
                        onPressed: flipCamera,
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
      if (isFrontCamera) {
        picture = await _flipImageHorizontally(picture.path);
      }
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

  Future<void> stopRecording(BuildContext context) async {
    try {
      XFile videoFile = await _cameraController.stopVideoRecording();
      setState(() {
        isRecording = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (builder) => VideoViewPage(path: videoFile.path),
        ),
      );
    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  Future<XFile> _flipImageHorizontally(String imagePath) async {
    final image = img.decodeImage(File(imagePath).readAsBytesSync());
    final flippedImage = img.flipHorizontal(image!);
    final newPath = imagePath.replaceFirst('.jpg', '_flipped.jpg');
    final newImageFile = File(newPath)..writeAsBytesSync(img.encodeJpg(flippedImage));
    return XFile(newImageFile.path);
  }
}
