import 'package:flutter/material.dart';
import '../NetworkHandler.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchAvailableSlots();
  }

  // Function to fetch available and booked appointments
  Future<void> _fetchAvailableSlots() async {
    final response = await widget.networkHandler.get("/appointment/getAppointments/${widget.blogId}");
    if (response != null && response['data'] != null) {
      setState(() {
        appointments = List<Map<String, dynamic>>.from(response['data']);
      });
    }
  }

  // Function to book an appointment
  Future<void> _bookAppointment(String time) async {
    try {
      // Send only the "HH:mm" part of the time
      final formattedTime = time.length == 5 ? time : time.substring(0, 5); // e.g., 09:30

      final response = await widget.networkHandler.post("/appointment/book", {
        "time": formattedTime,
        "blogId": widget.blogId,
        "userName": widget.userName,
        "duration": 30 // Default duration
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
        const SnackBar(content: Text('An error occurred while booking the appointment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Slots"),
        backgroundColor: Colors.teal,
      ),
      body: appointments.isEmpty
          ? const Center(child: Text("No available time slots."))
          : ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          final isBooked = appointment['status'] == 'booked';
          final time = appointment['time'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(
                "Time: ${appointment['time']}",
                style: TextStyle(
                  color: isBooked ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: isBooked
                  ? Text("Booked by: ${appointment['userName'] ?? 'N/A'}")
                  : const Text("Available slot"),
              trailing: isBooked
                  ? const Icon(Icons.lock, color: Colors.red)
                  : ElevatedButton(
                onPressed: () => _bookAppointment(time),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: const Text(
                  "Book",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
