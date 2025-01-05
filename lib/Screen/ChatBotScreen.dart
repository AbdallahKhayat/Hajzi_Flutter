import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../constants.dart';

class ChatBotScreen extends StatefulWidget {
  final String userEmail; // User's email
  final bool isAIModeInitial; // Initial mode selection

  ChatBotScreen({required this.userEmail, this.isAIModeInitial = false});

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = []; // Chat messages
  bool isLoading = false;

  late String apiKey; // Initialize securely
  late bool isAIMode; // Current mode

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // TODO: Secure your API key appropriately
    apiKey = 'sk-svcacct-ySd9tYFFIP7XRYvT8brzJ6ZluXYIhyX9DR768XaSJS5HwREPXdwXKK6nd-yPdmqPrT3BlbkFJn2dTVO5KhP2LnzvB5Shrnu_KZrwoqzb0e0K5fbgSSOTtZDwxXi_goP-rCMvLsSb7AA'; // Replace with secure method
    isAIMode = widget.isAIModeInitial;
    _loadChatHistory();
  }

  // Load chat history based on mode
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages =
    prefs.getString('chat_history_${widget.userEmail}');

    if (savedMessages != null) {
      List<dynamic> decodedMessages = json.decode(savedMessages);
      setState(() {
        messages = List<Map<String, dynamic>>.from(decodedMessages);
      });
    }

    // Show welcome message if necessary
    String currentWelcome =
    isAIMode ? _getWelcomeMessageAI() : _getWelcomeMessageHajzi();

    if (messages.isEmpty || messages.last["content"] != currentWelcome) {
      _sendWelcomeMessage();
    } else {
      _scrollToBottom();
    }
  }

  // Save chat history
  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'chat_history_${widget.userEmail}', json.encode(messages));
  }

  // Welcome messages
  String _getWelcomeMessageAI() {
    return AppLocalizations.of(context)!.welcomeToHajziBot;
  }

  String _getWelcomeMessageHajzi() {
    return "${AppLocalizations.of(context)!.welcomeToHajziBot}\n\n"
        "1. ${AppLocalizations.of(context)!.bookAnAppointment}\n"
        "2. ${AppLocalizations.of(context)!.transferToCustomer}\n"
        "3. ${AppLocalizations.of(context)!.getAppAssistance}\n"
        "4. ${AppLocalizations.of(context)!.contactAdmin}";
  }

  // Send welcome message
  Future<void> _sendWelcomeMessage() async {
    final String welcomeMessage = isAIMode
        ? _getWelcomeMessageAI()
        : _getWelcomeMessageHajzi();

    setState(() {
      messages.add({"role": "assistant", "content": welcomeMessage});
    });

    await _saveChatHistory();
    _scrollToBottom();
  }

  // Handle sending messages
  Future<void> sendMessage(String userMessage) async {
    setState(() {
      isLoading = true;
      messages.add({"role": "user", "content": userMessage});
    });

    await _saveChatHistory();
    _scrollToBottom();

    if (!isAIMode) {
      // Handle predefined Hajzi questions
      switch (userMessage.trim()) {
        case "1":
          _addAssistantMessage(AppLocalizations.of(context)!.bookAppointmentHelp);
          break;
        case "2":
          _addAssistantMessage(AppLocalizations.of(context)!.transferToCustomerHelp);
          break;
        case "3":
          _addAssistantMessage(AppLocalizations.of(context)!.appAssistanceHelp);
          break;
        case "4":
          _addAssistantMessage(AppLocalizations.of(context)!.contactAdminHelp);
          break;
        default:
          _addAssistantMessage(AppLocalizations.of(context)!.invalidOption);
      }

      setState(() {
        isLoading = false;
      });
      await _saveChatHistory();
      return;
    }

    // AI Mode: OpenAI API call
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          "model": "gpt-3.5-turbo", // Specify GPT-4 here
          "messages": messages, // Include your conversation history
          "temperature": 0.7,   // Optional: Adjust creativity level
        }),
      );

      debugPrint('Raw Response: ${response.body}'); // Log the raw response


      if (response.statusCode == 200) {
        final data = json.decode(response.body);


        // Decode the Arabic content
        String botMessage = utf8.decode(data['choices'][0]['message']['content']
            .toString()
            .runes
            .toList());

        setState(() {
          messages.add({"role": "assistant", "content": botMessage});
        });
        await _saveChatHistory();
      } else {
        debugPrint('Failed to fetch response: ${response.body}');
        _addAssistantMessage(
            "Sorry, I couldn't process your request at the moment.");
      }
    } catch (error) {
      debugPrint('Error sending message: $error');
      _addAssistantMessage(
          "An error occurred while trying to process your request.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  // Add assistant message
  void _addAssistantMessage(String message) {
    setState(() {
      messages.add({"role": "assistant", "content": message});
    });
    _scrollToBottom();
  }

  // Delete chat history
  Future<void> _deleteChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history_${widget.userEmail}');
    setState(() {
      messages.clear();
    });
    _sendWelcomeMessage(); // Reload welcome message
  }

  // Confirm deletion dialog
  void _confirmDeleteHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Delete Chat History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content:
        const Text("Are you sure you want to delete the chat history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteChatHistory(); // Delete history
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Auto-scroll to bottom
  Future<void> _scrollToBottom() async {
    await Future.delayed(Duration(milliseconds: 300));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Handle mode switching
  Future<void> _switchMode(bool newMode) async {
    if (newMode != isAIMode) {
      setState(() {
        isAIMode = newMode;
        isLoading = true;
        messages.clear(); // Clear current messages
      });

      // Remove existing chat history
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history_${widget.userEmail}');

      // Send the new welcome message based on the selected mode
      await _sendWelcomeMessage();

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: Text(
          isAIMode
              ? AppLocalizations.of(context)!.hajziBotAIMode
              : AppLocalizations.of(context)!.hajziBotHelpMode,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        actions: [
          Row(
            children: [
              Icon(
                isAIMode ? Icons.chat : Icons.question_answer,
                color: Colors.white,
              ),
              Switch(
                value: isAIMode,
                onChanged: (value) {
                  _switchMode(value);
                },
                activeColor: Colors.white,
              ),
              Icon(
                isAIMode ? Icons.question_answer : Icons.chat,
                color: Colors.white,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.black),
                onPressed: _confirmDeleteHistory, // Open confirmation dialog
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message["role"] == "user";

                return Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        isUser
                            ? AppLocalizations.of(context)!.me
                            : AppLocalizations.of(context)!.hajziBot,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUser ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    Container(
                      alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.green[200] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message["content"] ?? ""),
                    ),
                  ],
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.typeYourMessage,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
