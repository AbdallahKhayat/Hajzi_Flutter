import 'dart:convert';

import 'package:blogapp/CustomWidget/OwnMessageCard.dart';
import 'package:blogapp/CustomWidget/ReplyCard.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../NetworkHandler.dart';
import '../constants.dart'; // Import the constants file
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🔥 Add this to get the user's email
import 'package:intl/intl.dart'; // 🔥 Make sure you import this at the top of the file
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class IndividualPage extends StatefulWidget {

  final String initialChatId; // ✅ Rename from chatId to initialChatId
  final String chatPartnerEmail; // 🔥 New parameter to receive partner email
  final String chatPartnerName; // ⭐️ NEW parameter for partner's username


  const IndividualPage({super.key, required this.initialChatId, required this.chatPartnerEmail,required this.chatPartnerName}); // 🔥 Replace chatModel with chatId and chatPartnerEmail



  @override
  State<IndividualPage> createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {
  late String chatId;

  late IO.Socket socket;
  bool sendButton = false;
  TextEditingController _messageController = TextEditingController(); // 🔥 Add this to track input
  List messages = []; // 🔥 Create a list to store messages
  final FlutterSecureStorage storage = const FlutterSecureStorage(); // 🔥 Add for user email storage
  String? loggedInUserEmail; // 🔥 Store logged-in user's email


  String formatTime(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      String formattedTime = DateFormat('h:mm a').format(dateTime);
      return formattedTime;
    } catch (e) {
      print('❌ Error formatting time: $e');
      return '';
    }
  }



  Future<void> sendMessage(String messageContent) async {
    if (messageContent.isEmpty) return; // 🔥 Prevent empty message from being sent

    try {
      // ✅ **Check if chatId exists**
      if (chatId.isEmpty) {
        print("🛠️ Creating new chat since chatId is empty...");

        final response = await NetworkHandler().post('/chat/create', {
          'shopOwnerEmail': widget.chatPartnerEmail, // ✅ Create chat with the recipient email
        });

        if (response != null && response.statusCode == 201) {
          try {
            // ✅ Log the entire server response for debugging
            print("📡 Full response from server: ${response.body}");

            // ✅ Decode the response body to JSON
            final Map<String, dynamic> responseData = json.decode(response.body);
            print("📦 Decoded response data: $responseData");

            // ✅ Check for _id in the response
            final chatIdFromResponse = responseData['_id'] ?? responseData['enrichedChat']?['_id'] ?? responseData['chat']?['_id'];

            if (chatIdFromResponse != null) {
              setState(() {
                chatId = chatIdFromResponse; // ✅ Update chatId with the newly created chat
                print("✅ Chat created successfully with ID: $chatId");
              });

              // 🔥 **Send the message after the chat is created**
              await sendActualMessage(messageContent); // ✅ Await to ensure message is sent after chat creation
            } else {
              print("❌ Chat creation failed. No '_id' in response. Full response: ${response.body}");
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to create chat. Please try again.'),
              ));
            }
          } catch (e) {
            print("❌ Error parsing chat creation response: $e");
          }
        } else {
          print("❌ Failed to create chat. Response: ${response.body}, Status Code: ${response.statusCode}");
        }
      } else {
        // 🔥 **Send the message directly if chatId already exists**
        print("💬 Chat ID already exists: $chatId. Sending message directly...");
        await sendActualMessage(messageContent); // ✅ Use await to ensure message is sent
      }
    } catch (e) {
      print("❌ Error in sendMessage: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send message. Please try again.'),
      ));
    }
  }

  Future<void> sendActualMessage(String messageContent) async {
    if (messageContent.isEmpty) return; // 🔥 Prevent empty message from being sent

    try {
      // ✅ Optimistic UI update (display message before server response)
      final timestamp = DateTime.now().toIso8601String();
      final newMessage = {
        'content': messageContent,
        'senderEmail': loggedInUserEmail,
        'receiverEmail': widget.chatPartnerEmail,
        'timestamp': timestamp,
      };

      setState(() {
        messages.add(newMessage);
      });

      // ✅ Emit message to **Socket.io** instantly for real-time updates
      print("📡 Emitting message to socket...");
      NetworkHandler().socket!.emit('send_message', {
        'chatId': chatId,
        'content': messageContent,
        'senderEmail': loggedInUserEmail,
        'receiverEmail': widget.chatPartnerEmail,
        'timestamp': timestamp,
      });

      // 🔥 **Send message to the server**
      final response = await NetworkHandler().post('/chat/send-message', {
        'chatId': chatId,
        'content': messageContent,
        'receiverEmail': widget.chatPartnerEmail,
      });

      if (response != null) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        setState(() {
          sendButton = false; // 🔥 Reset the send button state
          print("✅ Message sent successfully. Response: $responseData");
        });
      } else {
        print("❌ Error sending message: Response was null");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send message. Please try again.'),
        ));
      }
    } catch (e) {
      print("❌ Error in sendActualMessage: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send message. Please try again.'),
      ));
    }
  }










  /// Function to create a lighter version of a color
  Color lightenColor(Color color, [double amount = 0.2]) {
    if (color == Colors.black) {
      return Colors.grey[850]!; // Special case for black
    }
    final hsl = HSLColor.fromColor(color);
    final lighterHSL = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lighterHSL.toColor();
  }

  @override
  void initState() {
    super.initState();
    chatId = widget.initialChatId; // ✅ Initialize chatId from widget property
    getUserEmail();
    NetworkHandler().initSocketConnection(); // ✅ Connect to socket

    // 🔥 **Fetch previous messages** if chatId exists
    if (chatId.isNotEmpty) {
      fetchMessages();
      joinChatRoom(); // ✅ Join the chat room once we have a chatId
      setupMessageListener(); // ✅ Listen for incoming messages only after joining the chat room
    } else {
      print("🕒 Waiting for chatId to be created...");
    }

    // 🔥 **Listen for socket 'connect' event**
    NetworkHandler().socket!.on('connect', (_) {
      print("✅ Socket connected successfully.");
      if (chatId.isNotEmpty) {
        joinChatRoom(); // ✅ Join the room only if chatId exists
        setupMessageListener(); // 🔥 Set up the listener when the socket connects
      }
    });
  }


  /// 🔥 **Join the chat room once chatId is set**
  /// 🔥 **Join the chat room once chatId is set**
  void joinChatRoom() {
    if (chatId.isNotEmpty) {
      if (NetworkHandler().socket != null && NetworkHandler().socket!.connected) {
        print("🔗 Joining chat room with chatId: $chatId");
        NetworkHandler().socket!.emit('join_chat', chatId);
        setupMessageListener(); // ✅ Set up message listener once user joins the room
      } else {
        print("⚠️ Socket not connected yet. Cannot join chat room.");
      }
    } else {
      print("⚠️ Chat ID is empty. Cannot join chat room.");
    }
  }


  /// 🔥 **Set up the listener for incoming messages**
  /// 🔥 **Set up the listener for incoming messages**
  void setupMessageListener() {
    if (NetworkHandler().socket != null && !NetworkHandler().socket!.hasListeners('receive_message')) {
      print("🛠️ Setting up 'receive_message' listener...");
      NetworkHandler().socket!.on('receive_message', (data) {
        print("🔥 New message received: $data");

        // ✅ Check if the message already exists (avoid duplicates)
        final bool messageAlreadyExists = messages.any((msg) => msg['_id'] == data['_id']); // Check by `_id`

        if (!messageAlreadyExists) {
          setState(() {
            messages.add({
              '_id': data['_id'], // ✅ Add `_id` to uniquely identify message
              'content': data['content'],
              'senderEmail': data['senderEmail'],
              'receiverEmail': data['receiverEmail'],
              'timestamp': data['timestamp'],
            });
          });
        }
      });
    }
  }

  Future<void> fetchMessages() async {
    try {
      if (chatId.isEmpty) {
        print("⚠️ Chat ID is empty. Skipping fetch messages.");
        return;
      }

      print("📡 Fetching messages for chatId: $chatId");
      final response = await NetworkHandler().get('/chat/messages/$chatId');

      if (response != null && response is List) {
        setState(() {
          response.forEach((message) {
            // Check if message already exists to avoid duplicates
            final bool messageAlreadyExists = messages.any((msg) => msg['_id'] == message['_id']);
            if (!messageAlreadyExists) {
              messages.add({
                '_id': message['_id'], // ✅ Use _id for uniqueness
                'content': message['content'],
                'senderEmail': message['senderEmail'],
                'receiverEmail': message['receiverEmail'],
                'timestamp': message['timestamp'],
              });
            }
          });
        });
        print('✅ Previous messages loaded successfully.');
      } else {
        print('❌ Failed to load messages. Response was null.');
      }
    } catch (e) {
      print('❌ Error in fetchMessages: $e');
    }
  }


  void updateChatId(String newChatId) {
    if (chatId != newChatId) {
      setState(() {
        chatId = newChatId;
      });
      fetchMessages();
    }
  }



  Future<void> getUserEmail() async {
    try {
      loggedInUserEmail = await storage.read(key: "email");
      print('Logged-in user email: $loggedInUserEmail');
    } catch (e) {
      print("Error getting user email: $e");
    }
  }





  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ValueListenableBuilder<Color>(
      valueListenable: appColorNotifier, // Listen to appColorNotifier
      builder: (context, mainColor, child) {
        final messageBubbleColor = lightenColor(mainColor, 0.2); // Slightly lighter than mainColor
        final backgroundColor = lightenColor(mainColor, 0.4); // Much lighter than mainColor

        return Scaffold(
          backgroundColor: backgroundColor, // Lighter shade of mainColor
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: mainColor, // Main color used for AppBar

              titleSpacing: 0,
              leadingWidth: screenWidth * 0.25,
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: screenWidth * 0.02),
                    Icon(
                      Icons.arrow_back,
                      size: screenWidth * 0.06,
                      color: Colors.white,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    CircleAvatar(
                      radius: screenWidth * 0.05,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.chatPartnerName[0].toUpperCase(), // ⭐️ Use the first letter of chatPartnerName
                        style: TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: InkWell( // 🔥 Keep only this title, as it's interactive and supports tap actions
                onTap: () {}, // Optional: You can add functionality when tapping the title
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.002),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatPartnerName, // ✅ Use partner's name instead of email
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                IconButton(
                  onPressed: () {}, // 🚀 To be implemented later
                  icon: Icon(
                    Icons.videocam,
                    size: screenWidth * 0.06,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {}, // 🚀 To be implemented later
                  icon: Icon(
                    Icons.call,
                    size: screenWidth * 0.06,
                    color: Colors.white,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: screenWidth * 0.06,
                  ),
                  onSelected: (value) {}, // 🚀 To be implemented later
                  itemBuilder: (BuildContext context) {
                    return const [
                      PopupMenuItem(value: "View Contact", child: Text("View Contact")),
                      PopupMenuItem(value: "Media, links, and docs", child: Text("Media, links, and docs")),
                      PopupMenuItem(value: "Hajzi web", child: Text("Hajzi web")),
                      PopupMenuItem(value: "Search", child: Text("Search")),
                      PopupMenuItem(value: "Mute Notifications", child: Text("Mute Notifications")),
                      PopupMenuItem(value: "Wall Paper", child: Text("Wall Paper")),
                    ];
                  },
                ),
              ],
            ),
          ),
          body: Column(
            children: [

          Expanded(
          child: ListView.builder(
          key: ValueKey(chatId),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            bool isOwnMessage = message['senderEmail'] == loggedInUserEmail; // ✅ Check if message is from the current user

            if (isOwnMessage) {
              // 🔥 Show OwnMessageCard if the senderEmail is the same as the logged-in user email
              return OwnMessageCard(
                message: message['content'],
                time: formatTime(message['timestamp']),
                messageColor: Colors.greenAccent,
                textColor: Colors.black,
              );
            } else {
              // 🔥 Show ReplyCard if the message is from the other participant
              return ReplyCard(
                message: message['content'],
                time: formatTime(message['timestamp']),
                messageColor: Colors.white,
                textColor: Colors.black,
              );
            }
          },
        ),
        ),


              Row(
                children: [
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextFormField(
                        controller: _messageController,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: TextInputType.multiline,
                        maxLines: 5,
                        minLines: 1,
                        onChanged: (value) {
                          setState(() {
                            sendButton = value.isNotEmpty;
                          });
                        },
                        onFieldSubmitted: sendMessage, // 🔥 Use the sendMessage method here
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type a message",
                          contentPadding: const EdgeInsets.only(
                            left: 20,
                            top: 10,
                            bottom: 10,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    backgroundColor: Colors.transparent,
                                    context: context,
                                    builder: (builder) => CustomBottomSheet(),
                                  );
                                },
                                icon: Icon(Icons.attach_file),
                                padding: const EdgeInsets.only(right: 0, left: 30),
                              ),
                              IconButton(
                                onPressed: () {
                                  // TODO: Implement camera logic
                                },
                                icon: Icon(Icons.camera_alt),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 10, left: 5),
                    child: CircleAvatar(
                      backgroundColor: mainColor,
                      radius: 25,
                      child: IconButton(
                        onPressed: () {
                          if (sendButton) sendMessage(_messageController.text.trim());
                        },
                        icon: AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: sendButton
                              ? Icon(Icons.send, key: ValueKey('send'))
                              : Icon(Icons.mic, key: ValueKey('mic')),
                        ),
                      ),
                    ),
                  ),
                ],
              )

            ],
          ),
        );
      },
    );
  }

  Widget CustomBottomSheet() {
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: EdgeInsets.all(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconCreation(
                      Icons.insert_drive_file,
                      Colors.indigo,
                      "Document",
                      onTap: () => handleFileSelection("Document")
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  IconCreation(
                      Icons.camera_alt,
                      Colors.pink,
                      "Camera",
                      onTap: () => handleFileSelection("Camera")
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  IconCreation(
                      Icons.insert_photo,
                      Colors.purple,
                      "Gallery",
                      onTap: () => handleFileSelection("Gallery")
                  ),
                ],
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconCreation(
                      Icons.headset,
                      Colors.orange,
                      "Audio",
                      onTap: () => handleFileSelection("Audio")
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  IconCreation(
                      Icons.location_pin,
                      Colors.teal,
                      "Location",
                      onTap: () => handleFileSelection("Location")
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  IconCreation(
                      Icons.person,
                      Colors.blue,
                      "Contact",
                      onTap: () => handleFileSelection("Contact")
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget IconCreation(IconData icon, Color color, String text, {required Function() onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: MediaQuery.of(context).size.width * 0.08,
            backgroundColor: color,
            child: Icon(icon, size: 29, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(text, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }



  void handleFileSelection(String type) async {
    if (type == "Document") {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null) {
        String filePath = result.files.single.path!;
        print("Document selected: $filePath");
        // TODO: Send document to server
      }
    } else if (type == "Camera") {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        print("Image captured: ${pickedFile.path}");
        // TODO: Send image to server
      }
    } else if (type == "Gallery") {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        print("Image selected: ${pickedFile.path}");
        // TODO: Send image to server
      }
    } else if (type == "Audio") {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null) {
        String filePath = result.files.single.path!;
        print("Audio selected: $filePath");
        // TODO: Send audio to server
      }
    } else if (type == "Location") {
      print("Location button pressed");
      // TODO: Get location using geolocator
    } else if (type == "Contact") {
      print("Contact button pressed");
      // TODO: Get contacts using contacts_service
    }
  }


}
