import 'dart:io';

import 'package:blogapp/Pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../NetworkHandler.dart';

class CreateProfile extends StatefulWidget {
  const CreateProfile({super.key});

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final _globalkey =
  GlobalKey<FormState>(); //global key used for data Validation

  bool visible = true; // for password icon to hide /unhide password
  final _globalKey =
  GlobalKey<FormState>(); // key for validation when clicking sign up
  NetworkHandler networkHandler =
  NetworkHandler(); // to connect flutter with api

  TextEditingController _nameController =
  TextEditingController(); //controllers to get the values of textfields
  TextEditingController _professionController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _aboutController = TextEditingController();

  String? errorText; //help validate user
  bool validate = false;
  bool circular = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Adding a gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _globalkey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
            children: [
              // Profile image section
              imageProfile(),
              const SizedBox(height: 20),

              // Input fields
              nameTextField(),
              const SizedBox(height: 20),
              professionTextField(),
              const SizedBox(height: 20),
              dobTextField(),
              const SizedBox(height: 20),
              titleTextField(),
              const SizedBox(height: 20),
              aboutTextField(),
              const SizedBox(height: 20),

              // Submit button section
              Center(
                child: Container(
                  height: 50,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.teal.shade300],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () async {
                        setState(() {
                          circular = true; // Show the loading indicator
                        });

                        // Check if the form is valid
                        if (_globalkey.currentState!.validate()) {
                          Map<String, String> data = {
                            "name": _nameController.text,
                            "profession": _professionController.text,
                            "DOB": _dobController.text,
                            "titleline": _titleController.text,
                            "about": _aboutController.text,
                          };

                          var response = await networkHandler.post("/profile/add", data);

                          if (response.statusCode == 200 || response.statusCode == 201) {
                            if (_imageFile != null) {
                              var imageResponse = await networkHandler.patchImage(
                                  "/profile/add/image", _imageFile!.path);
                              if (imageResponse.statusCode == 200) {
                                setState(() {
                                  circular = false; // Hide the loading indicator
                                });
                                Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) => HomePage(
                                          setLocale: (Locale) {},
                                          filterState: 0,
                                        )),
                                        (route) => false);
                              } else {
                                setState(() {
                                  circular = false; // Hide the loading indicator
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Something went wrong"),
                                  ),
                                );
                              }
                            } else {
                              setState(() {
                                circular = false; // Hide the loading indicator
                              });
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => HomePage(
                                      setLocale: (Locale) {},
                                      filterState: 0,
                                    )),
                                    (route) => false,
                              );
                            }
                          }
                        } else {
                          // If validation fails, reset the circular state
                          setState(() {
                            circular = false; // Hide the loading indicator
                          });
                        }
                      },
                      child: Center(
                        child: circular
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget imageProfile() {
    return Center(
      child: Stack(
        //when press camera icon it implements galary or camera
        children: [
          CircleAvatar(
            radius: 80,
            backgroundImage: _imageFile == null
                ? AssetImage("assets/profileImage.png")
                : FileImage(File(_imageFile!.path)) as ImageProvider,
          ),
          Positioned(
            bottom: 25,
            right: 15,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: ((builder) => buttonSheet()),
                );
              },
              child: const Icon(
                Icons.camera_alt,
                color: Colors.teal,
                size: 28,
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> requestPermissions() async {
    if (await Permission.camera.request().isGranted &&
        await Permission.photos.request().isGranted) {
      print("All permissions granted");
    } else {
      print("Camera or Gallery permission denied");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Camera or Gallery permission is required")),
      );
    }
  }

  Widget buttonSheet() {
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: Column(
        children: [
          const Text(
            "Choose Profile Photo",
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  takePhoto(ImageSource.camera);
                },
                icon: const Icon(
                  Icons.camera,
                  color: Colors.black,
                ),
                // The icon to display
                label: const Text(
                  "Camera",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ), // The label text to display
              ),
              SizedBox(
                width: 20,
              ),
              TextButton.icon(
                onPressed: () {
                  takePhoto(ImageSource.gallery);
                },
                icon: const Icon(
                  Icons.image,
                  color: Colors.black,
                ),
                // The icon to display
                label: const Text(
                  "Gallery",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ), // The label text to display
              ),
            ],
          )
        ],
      ),
    );
  }

  void takePhoto(ImageSource source) async {
    await requestPermissions(); // Request permissions

    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    } else {
      print("No image selected.");
    }
  }

  Widget nameTextField() {
    return TextFormField(
      controller: _nameController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Name can't be empty";
        }
        return null;
      },
      decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          prefixIcon: Icon(
            Icons.person,
            color: Colors.green,
          ),
          labelText: "Name",
          helperText: "Name can't be empty",
          hintText: "Ex: Abdallah Khayat"),
    );
  }

  Widget professionTextField() {
    return TextFormField(
      controller: _professionController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Profession can't be empty";
        }
        return null;
      },
      decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          prefixIcon: Icon(
            Icons.business,
            color: Colors.green,
          ),
          labelText: "Profession",
          helperText: "Profession can't be empty",
          hintText: "Ex: Fullstack Developer"),
    );
  }

  Widget dobTextField() {
    return TextFormField(
      controller: _dobController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "DOB can't be empty";
        }
        return null;
      },
      decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          prefixIcon: Icon(
            Icons.calendar_month,
            color: Colors.green,
          ),
          labelText: "Date of birth",
          helperText: "Provide DOB on dd/mm/yyyy format",
          hintText: "Ex: 17/8/2002"),
    );
  }

  Widget titleTextField() {
    return TextFormField(
      controller: _titleController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Title can't be empty";
        }
        return null;
      },
      decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          prefixIcon: Icon(
            Icons.title,
            color: Colors.green,
          ),
          labelText: "Title",
          helperText: "Title can't be empty",
          hintText: "Ex: Flutter Developer"),
    );
  }

  Widget aboutTextField() {
    return TextFormField(
      controller: _aboutController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "About can't be empty";
        }
        return null;
      },
      maxLines: 4,
      decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          labelText: "About",
          helperText: "Write about yourself (optional)",
          hintText: "Ex: I am a Flutter Developer"),
    );
  }
}
