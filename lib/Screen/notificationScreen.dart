import 'package:flutter/material.dart';
import '../NetworkHandler.dart';
import '../Models/notificationModel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> notifications = [];
  NetworkHandler networkHandler = NetworkHandler();
  bool isLoading = true;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // Fetch notifications for the logged-in user by email
  Future<void> fetchNotifications() async {
    try {
      // Fetch the email from secure storage
      String? email = await storage.read(key: "email");
      if (email == null) {
        debugPrint("Email not found in storage");
        return;
      }

      var response = await networkHandler.get("/notifications/user/$email");

      if (response['data'] != null) {
        setState(() {
          notifications = (response['data'] as List)
              .map((item) => NotificationModel.fromJson(item))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      var response = await networkHandler.patch(
        "/notifications/markAsRead/$notificationId",
        {},
      );
      if (response.statusCode == 200) {
        setState(() {
          notifications
              .removeWhere((notification) => notification.id == notificationId);
        });
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      var response =
          await networkHandler.delete("/notifications/delete/$notificationId");
      if (response['Status'] == true) {
        setState(() {
          notifications
              .removeWhere((notification) => notification.id == notificationId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notification deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete the notification."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting notification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An error occurred while deleting the notification."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications",style: TextStyle(fontWeight: FontWeight.bold),),
        flexibleSpace: ValueListenableBuilder<Color>(
          valueListenable: appColorNotifier,
          builder: (context, appColor, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColor.withOpacity(0.8), appColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    "No notifications available",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      title: Text(notification.title),
                      subtitle: Text(notification.body),
                      leading: Icon(
                        notification.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: notification.isRead ? Colors.grey : Colors.black,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!notification.isRead)
                            IconButton(
                              icon: const Icon(Icons.mark_as_unread),
                              onPressed: () => markAsRead(notification.id),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.black),
                            onPressed: () =>
                                deleteNotification(notification.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
