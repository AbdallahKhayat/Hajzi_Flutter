import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blogapp/Models/profileModel.dart';
import 'package:blogapp/NetworkHandler.dart';

class EditProfile extends StatefulWidget {
  final ProfileModel profileModel;

  const EditProfile({Key? key, required this.profileModel}) : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final NetworkHandler networkHandler = NetworkHandler();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _professionController;
  late TextEditingController _dobController;
  late TextEditingController _titlelineController;
  late TextEditingController _aboutController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileModel.name);
    _professionController =
        TextEditingController(text: widget.profileModel.profession);
    _dobController = TextEditingController(text: widget.profileModel.DOB);
    _titlelineController =
        TextEditingController(text: widget.profileModel.titleline);
    _aboutController = TextEditingController(text: widget.profileModel.about);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _dobController.dispose();
    _titlelineController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      Map<String, dynamic> data = {
        "username": widget.profileModel.username, // Include username
        "name": _nameController.text,
        "profession": _professionController.text,
        "DOB": _dobController.text,
        "titleline": _titlelineController.text,
        "about": _aboutController.text,
      };

      var response = await networkHandler.patch("/profile/update", data);
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update failed! Please try again.")),
        );
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: kIsWeb
                    ? Center(
                      child: SizedBox(
                                        width: 800,
                        child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  _buildTextField(
                                      "Titleline", _titlelineController),
                                  _buildTextField("Name", _nameController),
                                  _buildTextField(
                                      "Profession", _professionController),
                                  _buildTextField("Date of Birth", _dobController),
                                  _buildTextField(
                                    "About",
                                    _aboutController,
                                    maxLines: 5,
                                  ),
                                  const SizedBox(height: 30),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _updateProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 15),
                                      ),
                                      child: const Text(
                                        "Save Changes",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ),
                    )
                    : Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              _buildTextField(
                                  "Titleline", _titlelineController),
                              _buildTextField("Name", _nameController),
                              _buildTextField(
                                  "Profession", _professionController),
                              _buildTextField("Date of Birth", _dobController),
                              _buildTextField(
                                "About",
                                _aboutController,
                                maxLines: 5,
                              ),
                              const SizedBox(height: 30),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 15),
                                  ),
                                  child: const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.teal),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
      ),
    );
  }
}
