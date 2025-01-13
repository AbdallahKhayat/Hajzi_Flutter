import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../NetworkHandler.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomerAppointmentPage extends StatefulWidget {
  final NetworkHandler networkHandler;
  final String blogId;

  const CustomerAppointmentPage({
    Key? key,
    required this.networkHandler,
    required this.blogId,
  }) : super(key: key);

  @override
  _CustomerAppointmentPageState createState() =>
      _CustomerAppointmentPageState();
}

class _CustomerAppointmentPageState extends State<CustomerAppointmentPage> {
  List<Map<String, dynamic>> appointments = [];
  final TextEditingController _openingTimeController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
// NEW: For displaying how much time remains before next appointment
  String _timeUntilNext = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    // Update the countdown every minute (or adjust as needed)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTimeUntilNextAppointment();
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Future<void> showUserProfileDialog({
    required BuildContext context,
    required NetworkHandler networkHandler,
    required String email,
  }) async {
    try {
      // 1) Fetch user data by email
      final response =
          await networkHandler.get("/profile/getDataByEmail?email=$email");

      if (response == null || response['data'] == null) {
        throw Exception("No data found for this user.");
      }

      // 2) Parse the user data
      final userData = response['data']; // This is a Map<String, dynamic>
      // Alternatively, if you want to parse into a ProfileModel:
      // final profile = ProfileModel.fromJson(response['data']);

      // 3) Show the dialog with user information
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.person,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "User Profile: ${userData['name'] ?? 'Unknown'}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display image if available
                  Center(
                    child: userData['img'] != null &&
                            userData['img'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              userData['img'],
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120,
                                  width: 120,
                                  color: Colors.grey[300],
                                  child:
                                      const Icon(Icons.broken_image, size: 50),
                                );
                              },
                            ),
                          )
                        : Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.image, size: 50),
                          ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: "Email",
                    value: userData['email'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.work,
                    label: "Profession",
                    value: userData['profession'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.cake,
                    label: "DOB",
                    value: userData['DOB'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.title,
                    label: "Titleline",
                    value: userData['titleline'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.info,
                    label: "About",
                    value: userData['about'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Close",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (error) {
      debugPrint("Error fetching user profile: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching user profile.")),
      );
    }
  }

  Widget _buildInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.blueAccent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Function to fetch booked appointments and available slots
  Future<void> _fetchAppointments() async {
    try {
      final response = await widget.networkHandler
          .get("/appointment/getAppointments/${widget.blogId}");
      if (response != null && response['data'] != null) {
        setState(() {
          appointments = List<Map<String, dynamic>>.from(response['data']);
        });
        // NEW: Update the "time until next appointment" after we fetch
        _updateTimeUntilNextAppointment();
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    }
  }

  // Function to add a single available time slot
  Future<void> _addAvailableTime() async {
    if (_timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid time.')),
      );
      return;
    }

    try {
      final parsedTime = DateFormat('HH:mm').parse(_timeController.text);
      final formattedTime = DateFormat('HH:mm').format(parsedTime);

      final response =
          await widget.networkHandler.post("/appointment/addAvailableTime", {
        "time": formattedTime,
        "blogId": widget.blogId,
      });

      if (response.statusCode == 200) {
        setState(() {
          appointments.add({
            "userName": "Available Slot",
            "time": formattedTime,
            "duration": 20, // Default duration for available slots
            "status": "available"
          });
        });
        _timeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Available time added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add available time.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid time format. Use HH:mm.')),
      );
    }
  }

  // Function to add slots based on opening time, closing time, and duration
  Future<void> _addAvailableTimeSlots() async {
    if (_openingTimeController.text.isEmpty ||
        _closingTimeController.text.isEmpty ||
        _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the fields.')),
      );
      return;
    }

    try {
      // Step 1: Delete all existing time slots
      await _deleteAllTimeSlots();
      await _fetchAppointments();
      final openingTime =
          DateFormat('HH:mm').parse(_openingTimeController.text);
      final closingTime =
          DateFormat('HH:mm').parse(_closingTimeController.text);
      final int duration = int.parse(_durationController.text);

      if (openingTime.isAfter(closingTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Closing time must be after opening time.')),
        );
        return;
      }

      List<String> generatedTimeSlots = [];
      DateTime currentTime = openingTime;

      while (currentTime.isBefore(closingTime)) {
        final formattedTime = DateFormat('HH:mm').format(currentTime);
        generatedTimeSlots.add(formattedTime);
        currentTime = currentTime.add(Duration(minutes: duration));
      }

      for (String time in generatedTimeSlots) {
        await widget.networkHandler.post("/appointment/addAvailableTime", {
          "time": time,
          "blogId": widget.blogId,
        });
        setState(() {
          appointments.add({
            "userName": "Available Slot",
            "time": time,
            "duration": duration,
            "status": "available"
          });
        });
      }

      // Refresh the appointments after new slots are added

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Available time slots added successfully!')),
      );
    } catch (e) {
      debugPrint("Error adding available time slots: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Invalid input. Please check your time format and duration.')),
      );
    }
  }

  Future<void> _deleteAllTimeSlots() async {
    try {
      final response = await widget.networkHandler
          .delete("/appointment/deleteAll/${widget.blogId}");

      if (response['statusCode'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All time slots deleted successfully!')),
          // Immediately fetch updated slots to refresh the UI
        );
        await _fetchAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No time slots found to delete.')),
        );
      }
    } catch (error) {
      debugPrint("Error deleting all slots: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while deleting time slots.')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(String time) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmDeletion),
          content: Text("${AppLocalizations.of(context)!.sureDelete} $time?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _confirmDeleteSlot(time); // Proceed with deletion
              },
              child: Text(
                AppLocalizations.of(context)!.delete,
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to handle the actual deletion after confirmation
  Future<void> _confirmDeleteSlot(String time) async {
    try {
      final response = await widget.networkHandler
          .delete("/appointment/delete/${widget.blogId}/$time");

      if (response != null &&
          response['message'] == "Time slot deleted successfully!") {
        setState(() {
          appointments = appointments
              .where((appointment) => appointment['time'] != time)
              .toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time slot deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete the time slot.')),
        );
      }
    } catch (error) {
      debugPrint("Error deleting slot: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while deleting the time slot.')),
      );
    }
  }

  // Function to delete an appointment slot
  Future<void> _deleteSlot(String time) async {
    _showDeleteConfirmationDialog(time);
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select Time',
      // Custom help text
      confirmText: 'OK',
      cancelText: 'CANCEL',
    );

    if (picked != null) {
      // Convert TimeOfDay to 24-hour format
      final int hour = picked.hour;
      final int minute = picked.minute;

      // Format time using DateTime for 24-hour conversion
      final now = DateTime.now();
      final DateTime selectedTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      // Format as 'HH:mm' (24-hour format)
      final formattedTime = DateFormat('HH:mm').format(selectedTime);

      setState(() {
        controller.text =
            formattedTime; // Update the TextField with 24-hour format time
      });
    }
  }

  String _formatTimeWithAMPM(String time) {
    try {
      // Parse the time string (assumes 'HH:mm' format)
      final DateFormat inputFormat = DateFormat('HH:mm');
      final DateTime dateTime = inputFormat.parse(time);

      // Format to 12-hour format with AM/PM
      final DateFormat outputFormat = DateFormat('hh:mm a');
      return outputFormat.format(dateTime);
    } catch (e) {
      return time; // If parsing fails, return original time
    }
  }

  // New method to update user email
  // Method to update user email for both booked and available slots
  Future<void> _updateUserEmail(
      String blogId, String time, String currentUserName, String status) async {
    final TextEditingController _emailController = TextEditingController(
        text: currentUserName != "Available Slot" ? currentUserName : "");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.editEmail),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.email,
              hintText: "example@example.com",
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String newEmail = _emailController.text.trim();
                // Basic email validation
                if (newEmail.isNotEmpty &&
                    !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(newEmail)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid Email")),
                  );
                  return;
                }

                try {
                  // If the slot is available and email is provided, booking the slot
                  // If the slot is booked and email is provided, updating the email
                  // If the slot is booked and email is cleared, making it available
                  // If the slot is available and email is cleared, no action

                  Map<String, dynamic> body = {};
                  if (newEmail.isNotEmpty) {
                    body['newUserName'] = newEmail;
                  } else {
                    body['newUserName'] = "Available Slot";
                  }

                  final response = await widget.networkHandler.patch(
                    "/appointment/updateUser/${widget.blogId}/$time",
                    body,
                  );

                  // Parse the response body
                  final responseData = json.decode(response.body);

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(responseData['message'] ??
                              "Email updated successfully")),
                    );
                    _fetchAppointments(); // Refresh the appointments
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(responseData['message'] ?? "Update Failed")),
                    );
                  }
                } catch (error) {
                  debugPrint("Error updating email: $error");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Update Error")),
                  );
                } finally {
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: Text(
                AppLocalizations.of(context)!.save,
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  // NEW: Method to edit the time & duration of a slot
  Future<void> _editTimeDuration(Map<String, dynamic> appointment) async {
    // We store the old time to send with the request
    final String oldTime = appointment['time'];
    final int currentDuration = appointment['duration'] ?? 30;

    // Temporary controllers for the new time/duration
    final TextEditingController timeController =
        TextEditingController(text: oldTime);
    final TextEditingController durationController =
        TextEditingController(text: currentDuration.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Time & Duration"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Time (HH:mm)"),
                onTap: () => _selectTime(context, timeController),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: "Duration (min)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                final newTime = timeController.text.trim();
                final newDuration =
                    int.tryParse(durationController.text.trim()) ?? 30;

                if (newTime.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a valid time")),
                  );
                  return;
                }

                try {
                  final response = await widget.networkHandler.patch(
                    "/appointment/updateSlot/${widget.blogId}/$oldTime",
                    {
                      "newTime": newTime,
                      "newDuration": newDuration,
                    },
                  );

                  final responseData = json.decode(response.body);

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(responseData['message'] ??
                            "Slot updated successfully!"),
                      ),
                    );
                    Navigator.of(context).pop();
                    _fetchAppointments(); // Refresh
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(responseData['message'] ?? "Update Failed"),
                      ),
                    );
                  }
                } catch (error) {
                  debugPrint("Error updating slot: $error");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text("An error occurred while updating the slot.")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // NEW: Compute how much time remains until the next appointment
  void _updateTimeUntilNextAppointment() {
    if (appointments.isEmpty) {
      setState(() {
        _timeUntilNext = "No appointments scheduled";
      });
      return;
    }

    final now = DateTime.now();
    // Attempt to parse each appointment's time into a DateTime for *today*
    // You may need to incorporate actual date logic if your appointments span multiple days
    List<DateTime> futureAppointmentTimes = [];

    for (var appt in appointments) {
      try {
        // appt['time'] is "HH:mm"
        final parts = appt['time'].split(":");
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final DateTime todayAppt = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // Only consider times in the future
        if (todayAppt.isAfter(now)) {
          futureAppointmentTimes.add(todayAppt);
        }
      } catch (e) {
        debugPrint("Could not parse appointment time: $e");
      }
    }

    if (futureAppointmentTimes.isEmpty) {
      setState(() {
        _timeUntilNext = "No upcoming appointments today";
      });
      return;
    }

    // Sort and take the earliest
    futureAppointmentTimes.sort();
    final nextAppt = futureAppointmentTimes.first;

    final diff = nextAppt.difference(now);

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    setState(() {
      if (hours <= 0 && minutes <= 0) {
        _timeUntilNext = "No upcoming appointments at this moment";
      } else {
        _timeUntilNext = "Next appointment in ${hours}h ${minutes}m";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.manageAppointments,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: ValueListenableBuilder<Color>(
          valueListenable: appColorNotifier,
          builder: (context, appColor, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColor.withOpacity(1), appColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW: Display time until next appointment
            Text(
              _timeUntilNext,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    controller: _timeController,
                    decoration: InputDecoration(
                        labelText:
                            '${AppLocalizations.of(context)!.addAvailableTime} (HH:mm)'),
                    readOnly: true,
                    // Prevent manual typing
                    onTap: () => _selectTime(
                        context, _timeController), // Call Time Picker
                  ),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<Color>(
                  valueListenable: appColorNotifier,
                  builder: (context, appColor, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColor, // Dynamic background color
                      ),
                      onPressed: _addAvailableTime,
                      child: Text(
                        AppLocalizations.of(context)!.add,
                        style: TextStyle(
                          color: Colors.black,
                          // You can make this dynamic too if needed
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    controller: _openingTimeController,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.opening),
                    readOnly: true,
                    // Prevent manual typing
                    onTap: () => _selectTime(
                        context, _openingTimeController), // Call Time Picker
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    controller: _closingTimeController,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.closing),
                    readOnly: true,
                    // Prevent manual typing
                    onTap: () => _selectTime(
                        context, _closingTimeController), // Call Time Picker
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    controller: _durationController,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.duration),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<Color>(
                  valueListenable: appColorNotifier,
                  builder: (context, appColor, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColor, // Dynamic background color
                      ),
                      onPressed: _addAvailableTimeSlots,
                      child: Text(
                        AppLocalizations.of(context)!.addSlots,
                        style: TextStyle(
                          color: Colors.black,
                          // You can make this dynamic too if needed
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            appointments.isEmpty
                ? const Center(child: Text("No appointments booked."))
                : Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(
                                label:
                                    Text(AppLocalizations.of(context)!.user)),
                            DataColumn(
                                label:
                                    Text(AppLocalizations.of(context)!.time)),
                            DataColumn(
                                label: Text(
                                    '${AppLocalizations.of(context)!.duration} ${AppLocalizations.of(context)!.min}')),
                            DataColumn(
                                label:
                                    Text(AppLocalizations.of(context)!.status)),
                            DataColumn(
                                label: Text(
                                    AppLocalizations.of(context)!.actions)),
                          ],
                          rows: appointments.map((appointment) {
                            final bool isBooked =
                                appointment['status'] == 'booked';
                            return DataRow(cells: [
                              DataCell(
                                isBooked
                                    ? InkWell(
                                        onTap: () {
                                          // If we have a valid email, open the popup
                                          final email = appointment['userName'];
                                          if (email != null &&
                                              email.contains("@")) {
                                            // call your showUserProfileDialog
                                            showUserProfileDialog(
                                              context: context,
                                              networkHandler:
                                                  widget.networkHandler,
                                              email: email,
                                            );
                                          }
                                        },
                                        child: Text(
                                          appointment['userName'],
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      )
                                    : Text(AppLocalizations.of(context)!
                                        .availableSlot),
                              ),
                              DataCell(Text(
                                _formatTimeWithAMPM(
                                    appointment['time'] ?? 'N/A'),
                              )),
                              DataCell(
                                  Text(appointment['duration'].toString())),
                              DataCell(
                                Text(
                                  isBooked
                                      ? AppLocalizations.of(context)!.booked
                                      : AppLocalizations.of(context)!.available,
                                  style: TextStyle(
                                      color:
                                          isBooked ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    // Delete Icon
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _deleteSlot(appointment['time']),
                                    ),
                                    // Edit Icon (only for booked slots)
                                    // Edit Icon (for both booked and available slots)
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _updateUserEmail(
                                          widget.blogId,
                                          appointment['time'],
                                          appointment['userName'],
                                          appointment['status']),
                                    ),
                                    // NEW: Edit slot (time & duration)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.timer,
                                        color: Colors.teal,
                                      ),
                                      tooltip: "Edit Time & Duration",
                                      onPressed: () => _editTimeDuration(
                                        appointment,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
