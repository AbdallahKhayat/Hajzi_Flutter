class AppointmentModel {
  final String userId;
  final String userName;
  final DateTime dateTime; // DateTime for appointment
  final String blogOwnerId;
  bool isConfirmed;

  AppointmentModel({
    required this.userId,
    required this.userName,
    required this.dateTime,
    required this.blogOwnerId,
    this.isConfirmed = false,
  });
}
