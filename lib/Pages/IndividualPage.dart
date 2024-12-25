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
  late ScrollController _scrollController; // 🔥 Add ScrollController here
  late IO.Socket socket;
  bool sendButton = false;
  TextEditingController _messageController = TextEditingController(); // 🔥 Add this to track input
  List messages = []; // 🔥 Create a list to store messages
  final FlutterSecureStorage storage = const FlutterSecureStorage(); // 🔥 Add for user email storage
  String? loggedInUserEmail; // 🔥 Store logged-in user's email
  String? chatPartnerImageUrl; // Add this line
 NetworkHandler networkHandler=NetworkHandler();
  String formatTime(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp).toLocal();
      String formattedTime = DateFormat('h:mm a').format(dateTime);
      return formattedTime;
    } catch (e) {
      print('❌ Error formatting time: $e');
      return '';
    }
  }

  Future<void> fetchChatPartnerProfileImage() async {
    try {
      String? token = await storage.read(key: "token");
      if (token == null) {
        print('No token found');
        return;
      }

      String chatPartnerEmail = widget.chatPartnerEmail;
      final response = await networkHandler.get('/profile/getDataByEmail?email=$chatPartnerEmail');

      if (response != null && response.containsKey('data')) {
        String? imgPath = response['data']['img'];
        if (imgPath != null && imgPath.isNotEmpty) {
          setState(() {
            chatPartnerImageUrl = 'https://hajzi-6883b1f029cf.herokuapp.com/' + imgPath;
          });
        }
      } else {
        print('Error fetching profile data');
      }
    } catch (e) {
      print('Error in fetchChatPartnerProfileImage: $e');
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

              // Now that we have chatId, fetch old messages, join room and set up listener
              await fetchMessages();
              joinChatRoom();
              setupMessageListener();

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
      // Clear the text field and reset send button after sending
      _messageController.clear();
      setState(() {
        sendButton = false;
      });
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

      // 🔥 Scroll to the bottom after the message is added
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // ✅ Emit message to **Socket.io** instantly for real-time updates
      // Just emit the message to the socket for real-time updates
      final timestamp = DateTime.now().toIso8601String();
      print("📡 Emitting message to socket...");
      // NetworkHandler().socket!.emit('send_message', {
      //   'chatId': chatId,
      //   'content': messageContent,
      //   'senderEmail': loggedInUserEmail,
      //   'receiverEmail': widget.chatPartnerEmail,
      //   'timestamp': timestamp,
      // });


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
    _scrollController = ScrollController();
    chatId = widget.initialChatId;
    getUserEmail();
    NetworkHandler().initSocketConnection();

    // Socket event handlers
    NetworkHandler().socket!.on('connect', (_) {
      print("✅ Socket connected successfully.");
      if (chatId.isNotEmpty) {
        // Re-join room and re-setup listener on reconnect
        joinChatRoom();
        //setupMessageListener();
      }
    });

    NetworkHandler().socket!.on('disconnect', (_) {
      print("⚠️ Socket disconnected.");
    });

    // Fetch profile image
    fetchChatPartnerProfileImage();

    // If we already have a chatId, fetch messages and set up the listener
    if (chatId.isNotEmpty) {
      fetchMessages().then((_) {
        joinChatRoom();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        //setupMessageListener();
      });
    } else {
      print("🕒 Waiting for chatId to be created...");
    }
  }






  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
  /// 🔥 **Set up the listener for incoming messages**
  /// 🔥 **Set up the listener for incoming messages**
  /// 🔥 **Set up the listener for incoming messages**
  void setupMessageListener() {
    if (NetworkHandler().socket != null) {
      print("🛠️ Setting up 'receive_message' listener...");

      NetworkHandler().socket!.off('receive_message_individual'); // optional if needed once

      NetworkHandler().socket!.on('receive_message_individual', (data) {
        print("🔥 IndividualPage event: $data");

        final bool messageAlreadyExists = messages.any((msg) => msg['_id'] == data['_id']);
        if (!messageAlreadyExists) {
          // Convert timestamp to local time before formatting (in formatTime method)
          if(mounted)
          setState(() {
            messages.add({
              '_id': data['_id'],
              'content': data['content'],
              'senderEmail': data['senderEmail'],
              'receiverEmail': data['receiverEmail'],
              'timestamp': data['timestamp'],
            });
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } else {
          print('⚠️ Message with ID ${data['_id']} already exists. Ignoring duplicate.');
        }
      });
    }
  }









  @override
  void dispose() {
    _scrollController.dispose(); // 🔥 Don't forget to dispose
    super.dispose();
  }



  Future<void> fetchMessages() async {
    try {
      if (chatId.isEmpty) {
        print("⚠️ Chat ID is empty. Skipping fetch messages.");
        return;
      }

      print("📡 Fetching messages for chatId: $chatId");
      final response = await NetworkHandler().get('/chat/messages/$chatId');

      // If NetworkHandler().get returns raw JSON string:
      // final decoded = json.decode(response.body);
      // if (decoded is List) {
      //   setState(() {
      //     messages.clear(); // clear before adding
      //     for (var message in decoded) {
      //       messages.add({
      //         '_id': message['_id'],
      //         'content': message['content'],
      //         'senderEmail': message['senderEmail'],
      //         'receiverEmail': message['receiverEmail'],
      //         'timestamp': message['timestamp'],
      //       });
      //     }
      //   });
      // }

      // If NetworkHandler().get already returns a decoded list:
      if (response != null && response is List) {
        setState(() {
          messages.clear();
          for (var message in response) {
            messages.add({
              '_id': message['_id'],
              'content': message['content'],
              'senderEmail': message['senderEmail'],
              'receiverEmail': message['receiverEmail'],
              'timestamp': message['timestamp'],
            });
          }
          _scrollToBottom();
        });
        print('✅ Previous messages loaded successfully.');
      } else {
        print('❌ Failed to load messages. Response: $response');
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
                    chatPartnerImageUrl != null
                        ? CircleAvatar(
                      radius: screenWidth * 0.05,
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(chatPartnerImageUrl!),
                    )
                        : CircleAvatar(
                      radius: screenWidth * 0.05,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.chatPartnerName.isNotEmpty
                            ? widget.chatPartnerName[0].toUpperCase()
                            : 'U',
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
                  controller: _scrollController, // Attach scroll controller to auto-scroll
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isOwnMessage = message['senderEmail'] == loggedInUserEmail; // Check if message is from the current user

                    if (isOwnMessage) {
                      return ValueListenableBuilder<Color>(
                        valueListenable: appColorNotifier,
                        builder: (context, appColor, child) {
                          // Make the color lighter
                          Color lighterColor = appColor.withOpacity(0.5); // Makes it 50% lighter
                          // Alternatively, use HSLColor for more control over lightness
                          HSLColor hsl = HSLColor.fromColor(appColor);
                          Color lighterHSLColor = hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();

                          return OwnMessageCard(
                            message: message['content'],
                            time: formatTime(message['timestamp']),
                            messageColor: lighterHSLColor, // Use the lighter version of appColor
                            textColor: Colors.black,
                          );
                        },
                      );
                    } else {
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
                      backgroundColor: mainColor, // Use transparent or a neutral color
                      radius: 25,
                      child: IconButton(
                        onPressed: () {
                          if (sendButton) sendMessage(_messageController.text.trim());
                        },
                        icon: AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: sendButton
                              ? Icon(Icons.send, key: ValueKey('send'), color: Colors.black)
                              : Icon(Icons.mic, key: ValueKey('mic'), color: Colors.black),
                        ),
                        splashColor: mainColor.withOpacity(0.3), // Slight splash on click
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
