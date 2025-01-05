// ChatScreen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:blogapp/constants.dart';

// Import your other pages
import 'package:blogapp/Screen/CameraFiles/CameraScreen.dart';
import 'package:blogapp/Pages/SearchPage.dart';
import 'package:blogapp/Pages/ChatPage.dart';

// Import your classes used by the web layout
import 'dart:convert';
import 'package:blogapp/CustomWidget/CustomCard.dart';
import 'package:blogapp/CustomWidget/OwnMessageCard.dart';
import 'package:blogapp/CustomWidget/ReplyCard.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// The SINGLE entry point for ChatScreen.
/// We use `kIsWeb` to decide which layout/class to show.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If on web => show WebChatScreen. Otherwise => show MobileChatScreen.
    return kIsWeb ? const _ChatScreenWeb() : const _ChatScreenMobile();
  }
}

// ---------------------------------------------------------
// MOBILE Layout (the "above code")
// ---------------------------------------------------------
class _ChatScreenMobile extends StatefulWidget {
  const _ChatScreenMobile({Key? key}) : super(key: key);

  @override
  State<_ChatScreenMobile> createState() => _ChatScreenMobileState();
}

class _ChatScreenMobileState extends State<_ChatScreenMobile>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this, initialIndex: 1);

    // Navigate to camera instantly if tab index is 0 (camera tab)
    _controller.addListener(() {
      if (_controller.index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: appColorNotifier,
      builder: (context, appColor, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: appColor,
            title: const Text("Hajzi Chats",
                style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {},
                itemBuilder: (BuildContext context) {
                  return const [
                    PopupMenuItem(value: "New group", child: Text("New group")),
                    PopupMenuItem(
                        value: "New broadcast", child: Text("New broadcast")),
                    PopupMenuItem(value: "Hajzi web", child: Text("Hajzi web")),
                    PopupMenuItem(
                        value: "Starred messages",
                        child: Text("Starred messages")),
                    PopupMenuItem(value: "Settings", child: Text("Settings")),
                  ];
                },
              )
            ],
            bottom: TabBar(
              controller: _controller,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.camera_alt)),
                Tab(text: "CHATS"),
                Tab(text: "STATUS"),
                Tab(text: "CALLS"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _controller,
            children: [
              const SizedBox.shrink(),
              // The old approach: ChatPage handles logic
              const ChatPage(chatId: '', chatPartnerEmail: '', appBarFlag: 0),
              const Center(
                  child: Text("Status", style: TextStyle(fontSize: 18))),
              const Center(
                  child: Text("Calls", style: TextStyle(fontSize: 18))),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// WEB Layout (the "second code" for two columns & real-time)
// ---------------------------------------------------------
class _ChatScreenWeb extends StatefulWidget {
  const _ChatScreenWeb({Key? key}) : super(key: key);

  @override
  State<_ChatScreenWeb> createState() => _ChatScreenWebState();
}

class _ChatScreenWebState extends State<_ChatScreenWeb>
    with SingleTickerProviderStateMixin {
  // ------------------- TAB BAR (Camera, Chats, Status, Calls) -------------------
  late TabController _controller;

  // ------------------- NETWORK & STORAGE -------------------
  final NetworkHandler _networkHandler = NetworkHandler();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ------------------- CHATS LIST -------------------
  List<dynamic> _chats = [];
  bool _isLoadingChats = true;
  String? _loggedInUserEmail;
  String? _loggedInUserToken;

  // ------------------- SELECTED CHAT DETAILS -------------------
  String? _selectedChatId;
  String? _selectedPartnerEmail;
  String? _selectedPartnerName;
  String? _selectedPartnerImg; // profile image path

  // ------------------- MESSAGES & REAL-TIME -------------------
  List _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _sendButton = false;

  @override
  void initState() {
    super.initState();
    // 1) Setup the 4 tabs
    _controller = TabController(length: 4, vsync: this, initialIndex: 1);

    // If user taps on the camera tab (index 0), open camera
    _controller.addListener(() {
      if (_controller.index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );
      }
    });

    // 2) Initialize socket, user info, fetch all chats
    _initAll();
  }

  Future<void> _initAll() async {
    // A) Read email & token
    _loggedInUserEmail = await _storage.read(key: "email");
    _loggedInUserToken = await _storage.read(key: "token");

    // B) Connect socket
    _networkHandler.initSocketConnection();

    // C) Wait for socket connect event to join rooms, etc.
    _networkHandler.socket?.on('connect', (_) {
      debugPrint("✅ Socket connected in _ChatScreenWeb");
      // After we have chats, we'll join them. If we have them already, join now.
      _joinAllChats();
    });
    _networkHandler.socket?.on('disconnect', (_) {
      debugPrint("⚠️ Socket disconnected in _ChatScreenWeb");
    });

    // D) Set up real-time message listener
    _setupSocketListeners();

    // E) Fetch user-chats
    if (_loggedInUserToken == null) {
      debugPrint("No token found, cannot fetch chats");
      setState(() => _isLoadingChats = false);
    } else {
      _fetchChats(_loggedInUserToken!);
    }
  }

  // ------------------- FETCH & JOIN CHATS -------------------
  Future<void> _fetchChats(String token) async {
    try {
      final response =
          await _networkHandler.getWithAuth('/chat/user-chats', token);
      if (response != null && response is List) {
        setState(() {
          _chats = response;
        });
        // Join each chat room
        _joinAllChats();
      } else {
        debugPrint("Error fetching chats or response not a List: $response");
      }
    } catch (e) {
      debugPrint("Error in _fetchChats: $e");
    } finally {
      if(mounted)
      setState(() {
        _isLoadingChats = false;
      });
    }
  }

  void _joinAllChats() {
    if (_networkHandler.socket != null && _networkHandler.socket!.connected) {
      for (var c in _chats) {
        _networkHandler.socket!.emit('join_chat', c['_id']);
      }
    } else {
      debugPrint("Socket not connected yet, skipping join_chat for now.");
    }
  }

  // ------------------- SOCKET LISTENERS (REAL-TIME) -------------------
  void _setupSocketListeners() {
    // Avoid duplicate subscription
    _networkHandler.socket?.off('receive_message_chatpage');

    _networkHandler.socket?.on('receive_message_chatpage', (data) {
      debugPrint("🔔 Real-time message event: $data");

      final updatedChatId = data['chatId'];
      if (updatedChatId == null) {
        debugPrint("No chatId in message data, skipping");
        return;
      }

      // 1) Move that chat to top of _chats
      final index = _chats.indexWhere((chat) => chat['_id'] == updatedChatId);
      if (index != -1) {
        setState(() {
          final updatedChat = _chats.removeAt(index);
          updatedChat['lastMessage'] = data['content'];
          updatedChat['lastMessageTime'] = DateTime.now().toIso8601String();
          _chats.insert(0, updatedChat);
        });
      }

      // 2) If the user is *currently* viewing this chat, add the message
      if (_selectedChatId == updatedChatId) {
        setState(() {
          _messages.add({
            '_id': data['_id'],
            'content': data['content'],
            'senderEmail': data['senderEmail'],
            'receiverEmail': data['receiverEmail'],
            'timestamp': data['timestamp'],
          });
        });
        _scrollToBottom();
      }
    });
  }

  // ------------------- SELECT A CHAT (SET PARTNER INFO) -------------------
  void _onChatSelected(Map<String, dynamic> chat) {
    final partner = (chat['users'] as List).firstWhere(
      (u) => u['email'] != _loggedInUserEmail,
      orElse: () => null,
    );
    if (partner == null) return;

    setState(() {
      _selectedChatId = chat['_id'];
      _selectedPartnerEmail = partner['email'];
      _selectedPartnerName = partner['username'] ?? 'Unknown';
      _messages.clear();
    });

    // 1) We no longer trust partner['img'],
    //    we fetch it from /profile/getDataByEmail to match the logic in IndividualPage
    _fetchPartnerProfileImage(_selectedPartnerEmail!);

    // 2) Then fetch the chat messages
    _fetchMessagesForChat();
  }

  // ------------------- FETCH MESSAGES FOR SELECTED CHAT -------------------
  Future<void> _fetchMessagesForChat() async {
    if (_selectedChatId == null) return;
    try {
      final response =
          await _networkHandler.get('/chat/messages/$_selectedChatId');
      if (response != null && response is List) {
        setState(() {
          _messages = response;
        });
      } else {
        debugPrint("Error fetching messages: $response");
      }
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      debugPrint("Error in _fetchMessagesForChat: $e");
    }
  }

  // ------------------- SEND MESSAGE -------------------
  Future<void> _sendMessage(String content) async {
    if (content.isEmpty) return;
    if (_selectedChatId == null || _selectedChatId!.isEmpty) {
      debugPrint("No _selectedChatId, cannot send message");
      return;
    }

    try {
      final response = await _networkHandler.post('/chat/send-message', {
        'chatId': _selectedChatId,
        'content': content,
        'receiverEmail': _selectedPartnerEmail,
      });

      if (response != null) {
        debugPrint("✅ Message sent. Response: ${response.body}");
      } else {
        debugPrint("❌ Error sending message: response null");
      }

      // Locally add message so user sees it instantly
      final timestamp = DateTime.now().toIso8601String();
      // setState(() {
      //   _messages.add({
      //     '_id': 'temp_$timestamp',
      //     'content': content,
      //     'senderEmail': _loggedInUserEmail,
      //     'receiverEmail': _selectedPartnerEmail,
      //     'timestamp': timestamp,
      //   });
      // });

      _messageController.clear();
      _sendButton = false;
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error in _sendMessage: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Format timestamp for messages
  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  // ------------------- BUILD THE "CHATS" TAB -------------------
  Widget _buildChatsTab(BuildContext context) {
    if (_isLoadingChats) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_chats.isEmpty) {
      return const Center(child: Text("No chats available"));
    }

    // We do a fixed 300 px for the left column, as requested
    return Row(
      children: [
        // Left side: fixed width of 300
        Container(
          width: 300,
          color: Colors.grey.shade200,
          child: FutureBuilder<String?>(
            future: _storage.read(key: "email"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final currentUserEmail = snapshot.data!;
              return ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  final partner = (chat['users'] as List).firstWhere(
                    (u) => u['email'] != currentUserEmail,
                    orElse: () => null,
                  );
                  if (partner == null) return const SizedBox.shrink();

                  return CustomCard(
                    chat: {
                      ...chat,
                      'chatPartnerEmail': partner['email'],
                      'chatPartnerName': partner['username'],
                      'chatPartnerImg': partner['img'],
                    },
                    currentUserEmail: currentUserEmail,
                    onChatSelected: (selectedChat) => _onChatSelected(chat),
                    chatFlag: 0,
                  );
                },
              );
            },
          ),
        ),

        // Right side: chat detail
        Expanded(
          child: _selectedChatId == null
              ? const Center(child: Text("Select a user to start chatting"))
              : _buildChatDetailArea(appColorNotifier.value),
        ),
      ],
    );
  }

  Future<void> _fetchPartnerProfileImage(String email) async {
    try {
      // If you need a token
      final token = await _storage.read(key: "token");
      if (token == null) {
        debugPrint("No token found; cannot fetch partner profile image");
        return;
      }

      // Make a request to /profile/getDataByEmail?email=...
      final response =
          await _networkHandler.get('/profile/getDataByEmail?email=$email');
      if (response != null && response.containsKey('data')) {
        String? imgPath = response['data']['img'];
        if (imgPath != null && imgPath.isNotEmpty) {
          setState(() {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            // Construct the full URL
            _selectedPartnerImg =
                'https://hajzi-6883b1f029cf.herokuapp.com/$imgPath?v=$timestamp';
          });
        } else {
          debugPrint("Profile image is empty for $email");
          // fallback if you want
          setState(() {
            _selectedPartnerImg = '';
          });
        }
      } else {
        debugPrint("Could not fetch partner profile: $response");
      }
    } catch (e) {
      debugPrint("Error in _fetchPartnerProfileImage: $e");
    }
  }

  // ------------------- RIGHT-SIDE CHAT DETAIL (PROFILE PIC, MESSAGES, INPUT) -------------------
  Widget _buildChatDetailArea(Color mainColor) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Build the "profile picture URL" if we have one

    return Column(
      children: [
        Container(
          height: 60,
          color: mainColor,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // EXACT IndividualPage snippet:
              _selectedPartnerImg != null
                  ? CircleAvatar(
                      radius: screenWidth * 0.02,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: Image.network(
                          _selectedPartnerImg!,
                          width: screenWidth * 0.1,
                          // Twice the radius to fill the avatar
                          height: screenWidth * 0.1,
                          fit: BoxFit
                              .cover, // Ensures the image covers the circle without distortion
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: screenWidth * 0.05,
                      backgroundColor: Colors.white,
                      child: Text(
                        (_selectedPartnerName?.isNotEmpty ?? false)
                            ? _selectedPartnerName![0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.05,
                        ),
                      ),
                    ),

              const SizedBox(width: 8),

              // Partner name
              Expanded(
                child: Text(
                  _selectedPartnerName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Optional icons for call, video, etc.
              IconButton(
                onPressed: () => debugPrint("Voice call tapped"),
                icon: const Icon(Icons.call, color: Colors.white),
              ),
              IconButton(
                onPressed: () => debugPrint("Video call tapped"),
                icon: const Icon(Icons.videocam, color: Colors.white),
              ),
            ],
          ),
        ),

        // MESSAGES LIST
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isOwnMessage = msg['senderEmail'] == _loggedInUserEmail;
              final timeString = _formatTime(msg['timestamp']);

              if (isOwnMessage) {
                // OwnMessageCard
                return ValueListenableBuilder<Color>(
                  valueListenable: appColorNotifier,
                  builder: (context, color, child) {
                    return OwnMessageCard(
                      message: msg['content'] ?? '',
                      time: timeString,
                      messageColor: color.withOpacity(0.6),
                      textColor: Colors.black,
                      onLongPress: () => debugPrint("Own message long press"),
                    );
                  },
                );
              } else {
                // ReplyCard
                return ReplyCard(
                  message: msg['content'] ?? '',
                  time: timeString,
                  messageColor: Colors.white,
                  textColor: Colors.black,
                  onLongPress: () => debugPrint("Reply long press"),
                );
              }
            },
          ),
        ),

        // MESSAGE INPUT ROW
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
                    setState(() => _sendButton = value.isNotEmpty);
                  },
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
                              builder: (_) => _buildCustomBottomSheet(),
                            );
                          },
                          icon: const Icon(Icons.attach_file),
                          padding: const EdgeInsets.only(right: 0, left: 30),
                        ),
                        IconButton(
                          onPressed: () => debugPrint("Camera clicked"),
                          icon: const Icon(Icons.camera_alt),
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
                    if (_sendButton) {
                      _sendMessage(_messageController.text.trim());
                    }
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _sendButton
                        ? const Icon(Icons.send,
                            key: ValueKey('send'), color: Colors.black)
                        : const Icon(Icons.mic,
                            key: ValueKey('mic'), color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------- ATTACHMENT BOTTOM SHEET -------------------
  Widget _buildCustomBottomSheet() {
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: const EdgeInsets.all(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAttachmentIcon(
                    icon: Icons.insert_drive_file,
                    color: Colors.indigo,
                    label: "Document",
                    onTap: () => _handleFileSelection("Document"),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  _buildAttachmentIcon(
                    icon: Icons.camera_alt,
                    color: Colors.pink,
                    label: "Camera",
                    onTap: () => _handleFileSelection("Camera"),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  _buildAttachmentIcon(
                    icon: Icons.insert_photo,
                    color: Colors.purple,
                    label: "Gallery",
                    onTap: () => _handleFileSelection("Gallery"),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAttachmentIcon(
                    icon: Icons.headset,
                    color: Colors.orange,
                    label: "Audio",
                    onTap: () => _handleFileSelection("Audio"),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  _buildAttachmentIcon(
                    icon: Icons.location_pin,
                    color: Colors.teal,
                    label: "Location",
                    onTap: () => _handleFileSelection("Location"),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  _buildAttachmentIcon(
                    icon: Icons.person,
                    color: Colors.blue,
                    label: "Contact",
                    onTap: () => _handleFileSelection("Contact"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentIcon({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // Example for file selection
  void _handleFileSelection(String type) async {
    if (type == "Document") {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null) {
        final path = result.files.single.path;
        debugPrint("Document selected: $path");
        // TODO: upload to server
      }
    } else if (type == "Camera") {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        debugPrint("Camera captured: ${pickedFile.path}");
        // TODO: upload to server
      }
    } else if (type == "Gallery") {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        debugPrint("Gallery selected: ${pickedFile.path}");
        // TODO: upload to server
      }
    } else if (type == "Audio") {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null) {
        final path = result.files.single.path;
        debugPrint("Audio selected: $path");
        // TODO: upload to server
      }
    } else if (type == "Location") {
      debugPrint("Location button pressed - implement geolocator if you want");
    } else if (type == "Contact") {
      debugPrint(
          "Contact button pressed - implement contacts plugin if you want");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    // Optionally remove socket listeners
    _networkHandler.socket?.off('receive_message_chatpage');
    super.dispose();
  }

  // ------------------- BUILD MAIN SCREEN -------------------
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
        flexibleSpace: ValueListenableBuilder<Color>(
          valueListenable: appColorNotifier,
          builder: (context, appColor, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColor.withOpacity(1), appColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),
      title: const Text("Hajzi Chats (Web)",
          style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: const Icon(Icons.search,color: Colors.white,),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert,color: Colors.white),
          onSelected: (value) => debugPrint("Action: $value"),
          itemBuilder: (_) => const [
            PopupMenuItem(value: "New group", child: Text("New group")),
            PopupMenuItem(value: "New broadcast", child: Text("New broadcast")),
            PopupMenuItem(value: "Hajzi web", child: Text("Hajzi web")),
            PopupMenuItem(
                value: "Starred messages", child: Text("Starred messages")),
            PopupMenuItem(value: "Settings", child: Text("Settings")),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _controller,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.camera_alt)),
          Tab(text: "CHATS"),
          Tab(text: "STATUS"),
          Tab(text: "CALLS"),
        ],
      ),
    );

    return ValueListenableBuilder<Color>(
      valueListenable: appColorNotifier,
      builder: (_, currentColor, __) {
        return Scaffold(
          appBar: appBar,
          body: TabBarView(
            controller: _controller,
            children: [
              // 0) Camera
              const SizedBox.shrink(), // We navigate to camera instantly

              // 1) Chats tab => Two-column web layout
              _buildChatsTab(context),

              // 2) Status
              const Center(
                  child: Text("Status", style: TextStyle(fontSize: 18))),

              // 3) Calls
              const Center(
                  child: Text("Calls", style: TextStyle(fontSize: 18))),
            ],
          ),
        );
      },
    );
  }
}
