import 'dart:convert';
import 'dart:io';

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
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // For Clipboard

class IndividualPage extends StatefulWidget {
  final String initialChatId; // ✅ Rename from chatId to initialChatId
  final String chatPartnerEmail; // 🔥 New parameter to receive partner email
  final String chatPartnerName; // ⭐️ NEW parameter for partner's username

  const IndividualPage(
      {super.key,
      required this.initialChatId,
      required this.chatPartnerEmail,
      required this.chatPartnerName}); // 🔥 Replace chatModel with chatId and chatPartnerEmail

  @override
  State<IndividualPage> createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {
  late String chatId;
  late ScrollController _scrollController; // 🔥 Add ScrollController here
  late IO.Socket socket;
  bool sendButton = false;
  TextEditingController _messageController =
      TextEditingController(); // 🔥 Add this to track input
  List messages = []; // 🔥 Create a list to store messages
  final FlutterSecureStorage storage =
      const FlutterSecureStorage(); // 🔥 Add for user email storage
  String? loggedInUserEmail; // 🔥 Store logged-in user's email
  String? chatPartnerImageUrl; // Add this line
  NetworkHandler networkHandler = NetworkHandler();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

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
      final response = await networkHandler
          .get('/profile/getDataByEmail?email=$chatPartnerEmail');

      if (response != null && response.containsKey('data')) {
        String? imgPath = response['data']['img'];
        if (imgPath != null && imgPath.isNotEmpty) {
          setState(() {
            chatPartnerImageUrl =
                'https://hajzi-6883b1f029cf.herokuapp.com/' + imgPath;
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
    if (messageContent.isEmpty)
      return; // 🔥 Prevent empty message from being sent

    try {
      // ✅ **Check if chatId exists**
      if (chatId.isEmpty) {
        print("🛠️ Creating new chat since chatId is empty...");

        final response = await NetworkHandler().post('/chat/create', {
          'shopOwnerEmail': widget.chatPartnerEmail,
          // ✅ Create chat with the recipient email
        });

        if (response != null && response.statusCode == 201) {
          try {
            // ✅ Log the entire server response for debugging
            print("📡 Full response from server: ${response.body}");

            // ✅ Decode the response body to JSON
            final Map<String, dynamic> responseData =
                json.decode(response.body);
            print("📦 Decoded response data: $responseData");

            // ✅ Check for _id in the response
            final chatIdFromResponse = responseData['_id'] ??
                responseData['enrichedChat']?['_id'] ??
                responseData['chat']?['_id'];

            if (chatIdFromResponse != null) {
              setState(() {
                chatId =
                    chatIdFromResponse; // ✅ Update chatId with the newly created chat
                print("✅ Chat created successfully with ID: $chatId");
              });

              // Now that we have chatId, fetch old messages, join room and set up listener
              await fetchMessages();
              joinChatRoom();
              setupMessageListener();

              // 🔥 **Send the message after the chat is created**
              await sendActualMessage(
                  messageContent); // ✅ Await to ensure message is sent after chat creation
            } else {
              print(
                  "❌ Chat creation failed. No '_id' in response. Full response: ${response.body}");
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to create chat. Please try again.'),
              ));
            }
          } catch (e) {
            print("❌ Error parsing chat creation response: $e");
          }
        } else {
          print(
              "❌ Failed to create chat. Response: ${response.body}, Status Code: ${response.statusCode}");
        }
      } else {
        // 🔥 **Send the message directly if chatId already exists**
        print(
            "💬 Chat ID already exists: $chatId. Sending message directly...");
        await sendActualMessage(
            messageContent); // ✅ Use await to ensure message is sent
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
    if (messageContent.isEmpty)
      return; // 🔥 Prevent empty message from being sent

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
    final lighterHSL =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
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

    // Listen for 'update_message' events
    NetworkHandler().socket!.on('update_message', (data) {
      print("🔔 Update message event received: $data");
      if (data['chatId'] == chatId) {
        setState(() {
          int index = messages.indexWhere((msg) => msg['_id'] == data['_id']);
          if (index != -1) {
            messages[index]['content'] = data['content'];
          }
        });
        _scrollToBottom();
      }
    });
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
      if (NetworkHandler().socket != null &&
          NetworkHandler().socket!.connected) {
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

      NetworkHandler()
          .socket!
          .off('receive_message_individual'); // optional if needed once

      NetworkHandler().socket!.on('receive_message_individual', (data) {
        print("🔥 IndividualPage event: $data");

        final bool messageAlreadyExists =
            messages.any((msg) => msg['_id'] == data['_id']);
        if (!messageAlreadyExists) {
          // Convert timestamp to local time before formatting (in formatTime method)
          if (mounted)
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
          print(
              '⚠️ Message with ID ${data['_id']} already exists. Ignoring duplicate.');
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 🔥 Don't forget to dispose
    NetworkHandler().socket?.off('receive_message_individual');
    NetworkHandler().socket?.off('update_message');
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
    final isWeb = screenWidth >
        600; // Check if the screen width indicates a web environment

    return ValueListenableBuilder<Color>(
      valueListenable: appColorNotifier, // Listen to appColorNotifier
      builder: (context, mainColor, child) {
        final messageBubbleColor =
            lightenColor(mainColor, 0.2); // Slightly lighter than mainColor
        final backgroundColor =
            lightenColor(mainColor, 0.4); // Much lighter than mainColor

        return Scaffold(
          backgroundColor: backgroundColor, // Lighter shade of mainColor
          appBar: PreferredSize(
            preferredSize:
                Size.fromHeight(isWeb ? kToolbarHeight * 1.2 : kToolbarHeight),
            child: AppBar(
              backgroundColor: mainColor,
              // Main color used for AppBar

              titleSpacing: isWeb ? screenWidth * 0.01 : 0,
              leadingWidth: isWeb ? screenWidth * 0.15 : screenWidth * 0.25,
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: isWeb ? screenWidth * 0.01 : screenWidth * 0.02),
                    Icon(
                      Icons.arrow_back,
                      size: isWeb ? screenWidth * 0.02 : screenWidth * 0.06,
                      color: Colors.white,
                    ),
                    SizedBox(
                        width: isWeb ? screenWidth * 0.02 : screenWidth * 0.03),
                    chatPartnerImageUrl != null
                        ? CircleAvatar(
                            radius:
                                isWeb ? screenWidth * 0.03 : screenWidth * 0.05,
                            backgroundColor: Colors.transparent,
                            backgroundImage: NetworkImage(chatPartnerImageUrl!),
                          )
                        : CircleAvatar(
                            radius:
                                isWeb ? screenWidth * 0.03 : screenWidth * 0.05,
                            backgroundColor: Colors.white,
                            child: Text(
                              widget.chatPartnerName.isNotEmpty
                                  ? widget.chatPartnerName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: mainColor,
                                fontWeight: FontWeight.bold,
                                fontSize: isWeb
                                    ? screenWidth * 0.03
                                    : screenWidth * 0.05,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              title: InkWell(
                // 🔥 Keep only this title, as it's interactive and supports tap actions
                onTap: () {},
                // Optional: You can add functionality when tapping the title
                child: Container(
                  margin: EdgeInsets.symmetric(
                      horizontal:
                          isWeb ? screenWidth * 0.005 : screenWidth * 0.002),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatPartnerName,
                        // ✅ Use partner's name instead of email
                        style: TextStyle(
                          fontSize: isWeb ? 17 : 19,
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
                    size: isWeb ? screenWidth * 0.02 : screenWidth * 0.06,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {}, // 🚀 To be implemented later
                  icon: Icon(
                    Icons.call,
                    size: isWeb ? screenWidth * 0.02 : screenWidth * 0.06,
                    color: Colors.white,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: isWeb ? screenWidth * 0.02 : screenWidth * 0.06,
                  ),
                  onSelected: (value) {}, // 🚀 To be implemented later
                  itemBuilder: (BuildContext context) {
                    return const [
                      PopupMenuItem(
                          value: "View Contact", child: Text("View Contact")),
                      PopupMenuItem(
                          value: "Media, links, and docs",
                          child: Text("Media, links, and docs")),
                      PopupMenuItem(
                          value: "Hajzi web", child: Text("Hajzi web")),
                      PopupMenuItem(value: "Search", child: Text("Search")),
                      PopupMenuItem(
                          value: "Mute Notifications",
                          child: Text("Mute Notifications")),
                      PopupMenuItem(
                          value: "Wall Paper", child: Text("Wall Paper")),
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
                  controller: _scrollController,
                  // Attach scroll controller to auto-scroll
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isOwnMessage = message['senderEmail'] ==
                        loggedInUserEmail; // Check if message is from the current user
                    // Check if the message has been deleted
                    String displayMessage = message['content'];
                    if (message['content'] == 'Message has been deleted') {
                      displayMessage = 'Message has been deleted';
                    }
                    String formattedTime = formatTime(message['timestamp']);
                    String formattedDate = formatDate(message['timestamp']);

                    bool showDateSeparator = false;
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final previousMessage = messages[index - 1];
                      String previousDate =
                          formatDate(previousMessage['timestamp']);
                      if (previousDate != formattedDate) {
                        showDateSeparator = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateSeparator)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        isOwnMessage
                            ? OwnMessageCard(
                                message: message['content'],
                                time: formattedTime,
                                // Still pass date if needed
                                messageColor: lightenColor(mainColor, 0.2),
                                textColor:
                                    displayMessage == 'Message has been deleted'
                                        ? Colors.grey
                                        : Colors.black,
                                onLongPress: () {
                                  _showOwnMessageOptions(message);
                                },
                              )
                            : ReplyCard(
                                message: message['content'],
                                time: formattedTime,
                                // Still pass date if needed
                                messageColor: Colors.white,
                                textColor:
                                    displayMessage == 'Message has been deleted'
                                        ? Colors.grey
                                        : Colors.black,
                                onLongPress: () {
                                  _showReplyMessageOptions(message);
                                },
                              ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      margin: isWeb
                          ? EdgeInsets.only(left: 10, right: 10, bottom: 15)
                          : const EdgeInsets.only(left: 2, right: 2, bottom: 8),
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
                        onFieldSubmitted: (value) {
                          sendMessage(value);
                          // Clear the selected image after sending the message
                          if (_imageFile != null) {
                            setState(() {
                              _imageFile = null;
                            });
                          }
                        },
                        // 🔥 Use the sendMessage method here
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type a message",
                          contentPadding: isWeb
                              ? EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15)
                              : const EdgeInsets.only(
                                  left: 20, top: 10, bottom: 10),
                          prefix: _imageFile != null
                              ? Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(_imageFile!.path),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: -10,
                                        top: -10,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _imageFile = null;
                                            });
                                          },
                                          child: CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Colors.red,
                                            child: Icon(
                                              Icons.close,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
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
                                padding:
                                    const EdgeInsets.only(right: 0, left: 30),
                              ),
                              IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: ((builder) => buttonSheet()),
                                  );
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
                    padding: isWeb
                        ? EdgeInsets.only(bottom: 15, right: 15, left: 10)
                        : const EdgeInsets.only(bottom: 8, right: 10, left: 5),
                    child: CircleAvatar(
                      backgroundColor: mainColor,
                      radius: isWeb ? 20 : 25,
                      child: IconButton(
                        onPressed: () {
                          if (sendButton)
                            sendMessage(_messageController.text.trim());
                        },
                        icon: AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: sendButton || _imageFile != null
                              ? Icon(Icons.send,
                                  key: ValueKey('send'), color: Colors.black)
                              : Icon(Icons.mic,
                                  key: ValueKey('mic'), color: Colors.black),
                        ),
                        splashColor: mainColor
                            .withOpacity(0.3), // Slight splash on click
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

// Method to show options for OwnMessageCard
  void _showOwnMessageOptions(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.copy),
                title: Text('Copy'),
                onTap: () {
                  Navigator.of(context).pop();
                  _copyToClipboard(message['content']);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteOwnMessage(message['_id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

// Method to show options for ReplyCard
  void _showReplyMessageOptions(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.copy),
                title: Text('Copy'),
                onTap: () {
                  Navigator.of(context).pop();
                  _copyToClipboard(message['content']);
                },
              ),
              // No delete option for ReplyCard
            ],
          ),
        );
      },
    );
  }

// Method to copy text to clipboard
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

// Method to "delete" a message by replacing its content

  Future<void> _deleteOwnMessage(String messageId) async {
    try {
      final token = await storage.read(key: "token");
      if (token == null) {
        print("No token found; cannot delete message");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting message')),
        );
        return;
      }

      final response = await networkHandler.patch('/chat/delete-message', {
        'messageId': messageId,
      });

      if (response != null && response.statusCode == 200) {
        setState(() {
          int index = messages.indexWhere((msg) => msg['_id'] == messageId);
          if (index != -1) {
            messages[index]['content'] = 'Message has been deleted';
          }
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Message deleted')),
        // );
      } else {
        print("❌ Error deleting message: ${response?.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete message')),
        );
      }
    } catch (e) {
      print("Error deleting message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message')),
      );
    }
  }
  Future<void> requestPermissions() async {
    if (await Permission.camera.request().isGranted &&
        await Permission.photos.request().isGranted) {
      print("All permissions granted");
    } else {
      print("Camera or Gallery permission denied");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Camera or Gallery permission is required")),
      );
    }
  }

  Widget buttonSheet() {
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: Column(
        children: [
          const Text(
            "Choose Image From",
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  takePhoto(ImageSource.camera);
                },
                icon: const Icon(
                  Icons.camera,
                  color: Colors.black,
                ),
                // The icon to display
                label: const Text(
                  "Camera",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ), // The label text to display
              ),
              SizedBox(
                width: 20,
              ),
              TextButton.icon(
                onPressed: () {
                  takePhoto(ImageSource.gallery);
                },
                icon: const Icon(
                  Icons.image,
                  color: Colors.black,
                ),
                // The icon to display
                label: const Text(
                  "Gallery",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ), // The label text to display
              ),
            ],
          )
        ],
      ),
    );
  }

  String formatDate(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp).toLocal();
      // You can customize the date format as needed
      String formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
      return formattedDate;
    } catch (e) {
      print('❌ Error formatting date: $e');
      return '';
    }
  }

  void takePhoto(ImageSource source) async {
    await requestPermissions(); // Request permissions

    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    } else {
      print("No image selected.");
    }
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
                      Icons.insert_drive_file, Colors.indigo, "Document",
                      onTap: () => handleFileSelection("Document")),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  IconCreation(Icons.camera_alt, Colors.pink, "Camera",
                      onTap: () => handleFileSelection("Camera")),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  IconCreation(Icons.insert_photo, Colors.purple, "Gallery",
                      onTap: () => handleFileSelection("Gallery")),
                ],
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconCreation(Icons.headset, Colors.orange, "Audio",
                      onTap: () => handleFileSelection("Audio")),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  IconCreation(Icons.location_pin, Colors.teal, "Location",
                      onTap: () => handleFileSelection("Location")),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  IconCreation(Icons.person, Colors.blue, "Contact",
                      onTap: () => handleFileSelection("Contact")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget IconCreation(IconData icon, Color color, String text,
      {required Function() onTap}) {
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
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null) {
        String filePath = result.files.single.path!;
        print("Document selected: $filePath");
        // TODO: Send document to server
      }
    } else if (type == "Camera") {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        print("Image captured: ${pickedFile.path}");
        // TODO: Send image to server
      }
    } else if (type == "Gallery") {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        print("Image selected: ${pickedFile.path}");
        // TODO: Send image to server
      }
    } else if (type == "Audio") {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.audio);
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
