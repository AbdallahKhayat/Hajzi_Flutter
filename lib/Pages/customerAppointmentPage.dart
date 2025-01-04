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

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
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
          title:  Text(AppLocalizations.of(context)!.confirmDeletion),
          content: Text("${AppLocalizations.of(context)!.sureDelete} $time?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child:  Text(AppLocalizations.of(context)!.cancel,style: TextStyle(color: Colors.black),),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _confirmDeleteSlot(time); // Proceed with deletion
              },
              child:  Text(AppLocalizations.of(context)!.delete,style: TextStyle(color: Colors.red),),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    controller: _timeController,
                    decoration:  InputDecoration(
                        labelText: '${AppLocalizations.of(context)!.addAvailableTime} (HH:mm)'),
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
                      child:  Text(
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
                    decoration:  InputDecoration(labelText: AppLocalizations.of(context)!.opening),
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
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.closing),
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
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.duration),
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
                      child:  Text(
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
                            DataColumn(label: Text(AppLocalizations.of(context)!.user)),
                            DataColumn(label: Text(AppLocalizations.of(context)!.time)),
                            DataColumn(label: Text('${AppLocalizations.of(context)!.duration} (min)')),
                            DataColumn(label: Text(AppLocalizations.of(context)!.status)),
                            DataColumn(label: Text(AppLocalizations.of(context)!.actions)),
                          ],
                          rows: appointments.map((appointment) {
                            final bool isBooked =
                                appointment['status'] == 'booked';
                            return DataRow(cells: [
                              DataCell(Text(isBooked
                                  ? appointment['userName']
                                  :AppLocalizations.of(context)!.availableSlot)),
                              DataCell(Text(
                                _formatTimeWithAMPM(
                                    appointment['time'] ?? 'N/A'),
                              )),
                              DataCell(
                                  Text(appointment['duration'].toString())),
                              DataCell(
                                Text(
                                  isBooked ? AppLocalizations.of(context)!.booked : AppLocalizations.of(context)!.available,
                                  style: TextStyle(
                                      color:
                                          isBooked ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deleteSlot(appointment['time']),
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
