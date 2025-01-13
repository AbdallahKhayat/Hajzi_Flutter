import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../NetworkHandler.dart';
import '../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserAppointmentPage extends StatefulWidget {
  final NetworkHandler networkHandler;
  final String blogId;
  final String userName;

  const UserAppointmentPage({
    Key? key,
    required this.networkHandler,
    required this.blogId,
    required this.userName,
  }) : super(key: key);

  @override
  _UserAppointmentPageState createState() => _UserAppointmentPageState();
}

class _UserAppointmentPageState extends State<UserAppointmentPage> {
  List<Map<String, dynamic>> appointments = [];
  bool hasBooked = false; // Track if the user has booked an appointment

  @override
  void initState() {
    super.initState();
    _fetchAvailableSlots();
  }

  // Function to fetch available and booked appointments
  Future<void> _fetchAvailableSlots() async {
    try {
      final response = await widget.networkHandler
          .get("/appointment/getAppointments/${widget.blogId}");
      if (response != null && response['data'] != null) {
        setState(() {
          appointments = List<Map<String, dynamic>>.from(response['data']);
          hasBooked = appointments.any((appointment) =>
              appointment['status'] == 'booked' &&
              appointment['userName'] ==
                  widget.userName); // Check if user has already booked a slot
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch available slots.')),
      );
    }
  }

  // Helper to check if an appointment time is in the past
  bool isInPast(String timeStr) {
    try {
      final now = DateTime.now();
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final apptTime = DateTime(now.year, now.month, now.day, hour, minute);
      return apptTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  // Function to show a confirmation dialog
  Future<void> _showConfirmationDialog(String time) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmBooking),
          content: Text("${AppLocalizations.of(context)!.sureBooking} $time?"),
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
                _confirmBooking(time); // Proceed with booking
              },
              child: Text(
                AppLocalizations.of(context)!.confirm,
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

// Function to handle the actual booking after confirmation
  Future<void> _confirmBooking(String time) async {
    if (hasBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already booked an appointment.'),
        ),
      );
      return;
    }

    try {
      // Send only the "HH:mm" part of the time
      final formattedTime =
          time.length == 5 ? time : time.substring(0, 5); // e.g., 09:30

      final response = await widget.networkHandler.post("/appointment/book", {
        "time": formattedTime,
        "blogId": widget.blogId,
        "userName": widget.userName,
        "duration": 30, // Default duration
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
        _fetchAvailableSlots(); // Refresh the available slots
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book appointment.')),
        );
      }
    } catch (error) {
      debugPrint("Error booking appointment: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while booking the appointment.')),
      );
    }
  }

  // Function to book an appointment
  Future<void> _bookAppointment(String time) async {
    _showConfirmationDialog(time);
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
        title: Text(
          AppLocalizations.of(context)!.availableSlots,
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
      body: appointments.isEmpty
          ? Center(
              child: Text(AppLocalizations.of(context)!.noAvailableSlots),
            )
          : ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final isBooked = appointment['status'] == 'booked';
                final time = appointment['time'];
                final isBookedByUser =
                    appointment['userName'] == widget.userName;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      "${AppLocalizations.of(context)!.time}: ${_formatTimeWithAMPM(appointment['time'] ?? 'N/A')}",
                      style: TextStyle(
                        color: isBooked ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: isBooked
                        ? Text(
                            "${AppLocalizations.of(context)!.bookedBy}: ${appointment['userName'] ?? 'N/A'}")
                        : isInPast(time)
                            ? const Text("Expired")
                            : Text(AppLocalizations.of(context)!.availableSlot),
                    trailing: (hasBooked || isBooked ||  isInPast(time))
                        ? const Icon(Icons.lock, color: Colors.red)
                        : ValueListenableBuilder<Color>(
                            valueListenable: appColorNotifier,
                            builder: (context, appColor, child) {
                              return ElevatedButton(
                                onPressed: () => _bookAppointment(time),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      appColor, // Dynamic background color
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.book,
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            },
                          ),
                  ),
                );
              },
            ),
    );
  }
}
