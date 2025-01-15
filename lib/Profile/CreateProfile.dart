import 'dart:io';

import 'package:blogapp/Pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../NetworkHandler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final storage = FlutterSecureStorage();


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
                            //    await storage.write(key: "profileFlag", value: "1");
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
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.somethingWentWrong),
                                  ),
                                );
                              }
                            } else {
                              // Set profileFlag to 1 even if no image is uploaded
                           //   await storage.write(key: "profileFlag", value: "1");
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
                            : Text(
                          AppLocalizations.of(context)!.submit, // CHANGED
                          style: const TextStyle(
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
        SnackBar(content: Text(AppLocalizations.of(context)!.cameraGalleryPermission)), // CHANGED
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
          Text(
            AppLocalizations.of(context)!.chooseProfilePhoto, // CHANGED
            style: const TextStyle(
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
                label: Text(
                  AppLocalizations.of(context)!.camera, // CHANGED
                  style: const TextStyle(
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
                label: Text(
                  AppLocalizations.of(context)!.gallery, // CHANGED
                  style: const TextStyle(
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
          return AppLocalizations.of(context)!.nameEmpty; // CHANGED
        }
        return null;
      },
      decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          prefixIcon: const Icon(
            Icons.person,
            color: Colors.green,
          ),
          labelText: AppLocalizations.of(context)!.name, // CHANGED
          helperText: AppLocalizations.of(context)!.nameHelper, // CHANGED
          hintText: AppLocalizations.of(context)!.nameHint, // CHANGED
    ),
    );
  }

  Widget professionTextField() {
    return TextFormField(
      controller: _professionController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.professionEmpty; // CHANGED
        }
        return null;
      },
      decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          prefixIcon: const Icon(
            Icons.business,
            color: Colors.green,
          ),
        labelText: AppLocalizations.of(context)!.profession, // CHANGED
        helperText: AppLocalizations.of(context)!.professionHelper, // CHANGED
        hintText: AppLocalizations.of(context)!.professionHint, // CHANGED
      ),
    );
  }

  Widget dobTextField() {
    return TextFormField(
      controller: _dobController,
      readOnly: true, // prevents manual editing
      onTap: () async {
        // Show the date picker when the field is tapped.
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(), // default date displayed
          firstDate: DateTime(1900),   // earliest date allowed
          lastDate: DateTime.now(),    // latest date allowed
        );

        if (pickedDate != null) {
          // Format the selected date using the intl package.
          String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
          setState(() {
            _dobController.text = formattedDate;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.dobEmpty; // CHANGED
        }
        return null;
      },
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.teal,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.orange,
            width: 2,
          ),
        ),
        prefixIcon: const Icon(
          Icons.calendar_month,
          color: Colors.green,
        ),
        labelText: AppLocalizations.of(context)!.dob, // CHANGED
        helperText: AppLocalizations.of(context)!.dobHelper, // CHANGED
        hintText: AppLocalizations.of(context)!.dobHint, // CHANGED

      ),
    );
  }

  Widget titleTextField() {
    return TextFormField(
      controller: _titleController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.titleEmpty; // CHANGED
        }
        return null;
      },
      decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          prefixIcon: const Icon(
            Icons.title,
            color: Colors.green,
          ),
              labelText: AppLocalizations.of(context)!.title, // CHANGED
              helperText: AppLocalizations.of(context)!.titleHelper, // CHANGED
              hintText: AppLocalizations.of(context)!.titleHint, // CHANGED

      ),
    );
  }

  Widget aboutTextField() {
    return TextFormField(
      controller: _aboutController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.aboutEmpty; // CHANGED
        }
        return null;
      },
      maxLines: 4,
      decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
              labelText: AppLocalizations.of(context)!.about, // CHANGED
              helperText: AppLocalizations.of(context)!.aboutHelper, // CHANGED
              hintText: AppLocalizations.of(context)!.aboutHint, // CHANGED

      ),
    );
  }
}
