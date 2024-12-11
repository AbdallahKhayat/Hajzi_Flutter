import 'package:flutter/material.dart';
import '../NetworkHandler.dart';
import 'package:intl/intl.dart';

class CustomerAppointmentPage extends StatefulWidget {
  final NetworkHandler networkHandler;
  final String blogId;

  const CustomerAppointmentPage({
    Key? key,
    required this.networkHandler,
    required this.blogId,
  }) : super(key: key);

  @override
  _CustomerAppointmentPageState createState() => _CustomerAppointmentPageState();
}

class _CustomerAppointmentPageState extends State<CustomerAppointmentPage> {
  List<Map<String, dynamic>> appointments = [];
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  // Function to fetch booked appointments and available slots
  Future<void> _fetchAppointments() async {
    try {
      final response = await widget.networkHandler.get("/appointment/getAppointments/${widget.blogId}");
      if (response != null && response['data'] != null) {
        setState(() {
          appointments = List<Map<String, dynamic>>.from(response['data']);
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    }
  }

  // Function to add new available time
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

      final response = await widget.networkHandler.post("/appointment/addAvailableTime", {
        "time": formattedTime,
        "blogId": widget.blogId,
      });

      if (response.statusCode == 200) {
        setState(() {
          appointments.add({
            "userName": "Available Slot",
            "time": formattedTime,
            "duration": 30, // Default duration for available slots
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

  // Function to mark a time slot as available
  Future<void> _markAvailable(String time) async {
    try {
      final response = await widget.networkHandler.patch("/appointment/markAvailable/${widget.blogId}", {
        "time": time, // Send time as HH:mm
      });

      if (response.statusCode == 200) {
        setState(() {
          appointments.removeWhere((appointment) => appointment['time'] == time);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Time slot marked as available!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to mark time as available!')));
      }
    } catch (error) {
      debugPrint("Error marking time as available: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred while marking time as available.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Appointments"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Available Time Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Add Available Time (HH:mm)',
                      labelStyle: const TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 2.0,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addAvailableTime,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table of appointments
            appointments.isEmpty
                ? const Center(child: Text("No appointments booked."))
                : Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Duration (min)')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: appointments.map((appointment) {
                    final bool isBooked = appointment['status'] == 'booked';
                    return DataRow(cells: [
                      DataCell(Text(isBooked ? appointment['userName'] : "Available Slot")),
                      DataCell(Text(appointment['time'] ?? 'N/A')),
                      DataCell(Text(appointment['duration'].toString())),
                      DataCell(
                        Text(
                          isBooked ? 'Booked' : 'Available',
                          style: TextStyle(
                              color: isBooked ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _markAvailable((appointment['time'])),
                        ),
                      ),
                    ]);
                  }).toList(),
                )

              ),
            ),
          ],
        ),
      ),
    );
  }
}
