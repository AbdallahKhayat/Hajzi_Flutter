import 'package:flutter/material.dart';

class ChatModel {
  String name;
  IconData icon; // Changed from String to IconData
  bool isGroup;
  String time;
  String currentMessage;

  ChatModel({
    required this.name,
    required this.icon,
    required this.isGroup,
    required this.time,
    required this.currentMessage,
  });
}
