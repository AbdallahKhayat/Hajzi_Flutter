import 'package:flutter/material.dart';
import '../NetworkHandler.dart';
import '../Models/notificationModel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8), // Spacing between icon and text
                  Text(
                    AppLocalizations.of(context)!.notificationDeleted,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Row(
                children: [
                  const Icon(
                    Icons.delete_outline,
                    color: Colors.green,
                    size: 36,
                  ),
                  const SizedBox(width: 10), // Spacing between icon and message
                  Expanded(
                    child: Text(AppLocalizations.of(context)!.notificationDeletedSuccessfully),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToDeleteNotification),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting notification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorDeletingNotification),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.notifications,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
      // Using LayoutBuilder to create a responsive layout
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content;

          // Show a loader while data is loading.
          if (isLoading) {
            content = const Center(child: CircularProgressIndicator());
          }
          // Handle the case when there are no notifications.
          else if (notifications.isEmpty) {
            content = Center(
              child: Text(
                AppLocalizations.of(context)!.noNotificationsAvailable,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          // Build the list of notifications.
          else {
            content = ListView.builder(
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
                        onPressed: () => deleteNotification(notification.id),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          // If the available width is large (e.g., web), center the content in a fixed-width container.
          if (constraints.maxWidth > 600) {
            return Center(
              child: Container(
                width: 600,
                child: content,
              ),
            );
          } else {
            // On smaller screens (mobile), just return the content.
            return content;
          }
        },
      ),
    );
  }

}
