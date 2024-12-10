class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String recipient;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.recipient,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'],
      title: json['title'],
      body: json['body'],
      recipient: json['recipient'],
      isRead: json['isRead'],
      createdAt: DateTime.parse(json['createdAt']),
    );

  }
}
