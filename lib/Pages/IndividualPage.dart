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

        if (response != null) {
          try {
            // ✅ Log the entire server response for debugging
            print("📡 Full response from server: ${response.body}");

            // ✅ Decode the response body to JSON
            final Map<String, dynamic> responseData = json.decode(response.body);
            print("📦 Decoded response data: $responseData");

            // ✅ Check for _id in the response
            final chatIdFromResponse = responseData['_id'] ?? responseData['data']?['_id'];

            if (chatIdFromResponse != null) {
              setState(() {
                chatId = chatIdFromResponse; // ✅ Update chatId with the newly created chat
                print("✅ Chat created successfully with ID: $chatId");
              });

              // 🔥 **Send the message after the chat is created**
              await sendActualMessage(messageContent); // ✅ Await to ensure message is sent after chat creation
            } else {
              print("❌ Chat creation failed. No '_id' in response. Full response: ${response.body}");
            }
          } catch (e) {
            print("❌ Error parsing chat creation response: $e");
          }
        } else {
          print("❌ Failed to create chat. Server did not return a response.");
        }
      } else {
        // 🔥 **Send the message directly if chatId already exists**
        print("💬 Chat ID already exists: $chatId. Sending message directly...");
        await sendActualMessage(messageContent); // ✅ Use await to ensure message is sent
      }
    } catch (e) {
      print("❌ Error in sendMessage: $e");
    }
  }




  Future<void> sendActualMessage(String messageContent) async {
    if (messageContent.isEmpty) return; // 🔥 Prevent empty message from being sent

    try {
      final response = await NetworkHandler().post('/chat/send-message', {
        'chatId': chatId, // ✅ Pass the chat ID
        'content': messageContent, // ✅ Pass the message content
        'receiverEmail': widget.chatPartnerEmail, // ✅ Pass receiver's email
      });

      if (response != null) {
        _messageController.clear(); // ✅ Clear the input field after sending
        final Map<String, dynamic> responseData = json.decode(response.body); // ✅ Decode JSON response

        setState(() {
          sendButton = false; // 🔥 Reset the send button state
          messages.add({
            'content': messageContent, // ✅ The actual message content
            'senderEmail': loggedInUserEmail, // ✅ Sender's email
            'receiverEmail': widget.chatPartnerEmail, // ✅ Receiver's email
            'timestamp': DateTime.now().toIso8601String(), // ✅ Timestamp of when the message was sent
          });

          // ✅ Emit the message to **socket.io** to notify other users in real-time
          NetworkHandler().socket!.emit('send_message', {
            'chatId': chatId,
            'content': messageContent,
            'senderEmail': loggedInUserEmail,
            'receiverEmail': widget.chatPartnerEmail,
            'timestamp': DateTime.now().toIso8601String(),
          });

          print("✅ Message sent successfully. Response: $responseData");
        });
      } else {
        print("❌ Error sending message: Response was null");
      }
    } catch (e) {
      print("❌ Error in sendActualMessage: $e");
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
  @override
  void initState() {
    super.initState();
    chatId = widget.initialChatId; // ✅ Initialize chatId from widget property
    getUserEmail();
    NetworkHandler().initSocketConnection(); // ✅ Use existing connection from NetworkHandler

    // 🔥 **Fetch previous messages** from the backend for this chat
    if (chatId.isNotEmpty) {
      fetchMessages(); // ✅ Call this to load previous messages for the chat
    }

    // 🔥 **Join the chat room** using socket.io for real-time updates
    Future.delayed(Duration(milliseconds: 500), () {
      if (chatId.isNotEmpty) {
        NetworkHandler().socket!.emit('join_chat', chatId); // ✅ Join room with chatId
      }
    });

    // 🔥 **Listen for incoming messages** (this listener runs globally)
    NetworkHandler().socket!.on('receive_message', (data) {
      print('🔥 New message received: $data');
      setState(() {
        messages.add({
          'content': data['content'], // ✅ Store message content
          'sender': data['sender'],   // ✅ Store sender email
          'receiver': data['receiver'], // ✅ Store receiver email
          'timestamp': data['timestamp'], // ✅ Store message timestamp
        });
      });
    });
  }

  Future<void> fetchMessages() async {
    try {
      // 🔥 Get previous messages for this chat
      final response = await NetworkHandler().get('/chat/messages/$chatId'); // ✅ Call API to get messages
      if (response != null && response is List) {
        setState(() {
          messages = response.map((message) => {
            'content': message['content'], // ✅ Message content
            'sender': message['sender'],   // ✅ Sender's email
            'receiver': message['receiver'], // ✅ Receiver's email
            'timestamp': message['timestamp'], // ✅ Timestamp
          }).toList(); // ✅ Store in the messages array
        });
        print('✅ Previous messages loaded successfully.');
      } else {
        print('❌ Failed to load messages. Response was null.');
      }
    } catch (e) {
      print('❌ Error in fetchMessages: $e');
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
          key: ValueKey(chatId), // ✅ Forces the list to rebuild when chatId changes
          itemCount: messages.length,
          reverse: true, // ✅ Makes the ListView scroll from bottom to top
          itemBuilder: (context, index) {
            final message = messages[index];
            final bool isOwnMessage = message['senderEmail'] == loggedInUserEmail; // ✅ Check if message is from the current user

            if (message['content'] == null || message['content'].isEmpty) {
              return const SizedBox.shrink(); // 🔥 Skip rendering for empty messages
            }

            if (isOwnMessage) {
              // 🔥 Show OwnMessageCard if the senderEmail matches the logged-in user's email
              return OwnMessageCard(
                message: message['content'],
                time: formatTime(message['timestamp']),
                messageColor: Colors.greenAccent, // Example of color customization
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
