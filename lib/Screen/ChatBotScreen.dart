import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChatBotScreen extends StatefulWidget {
  final String userEmail; // Pass the user's email to the chat screen

  ChatBotScreen({required this.userEmail});

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = []; // Chat messages
  bool isLoading = false;

  final String apiKey =
      'sk-svcacct-ySd9tYFFIP7XRYvT8brzJ6ZluXYIhyX9DR768XaSJS5HwREPXdwXKK6nd-yPdmqPrT3BlbkFJn2dTVO5KhP2LnzvB5Shrnu_KZrwoqzb0e0K5fbgSSOTtZDwxXi_goP-rCMvLsSb7AA'; // Replace with your OpenAI API Key

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // Function to load chat history for the specific user from SharedPreferences
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('chat_history_${widget.userEmail}');

    if (savedMessages != null) {
      List<dynamic> decodedMessages = json.decode(savedMessages);
      setState(() {
        messages = List<Map<String, dynamic>>.from(decodedMessages);
      });
    }

    // Show welcome message only if the last message is not the welcome message
    if (messages.isEmpty || messages.last["content"] != _getWelcomeMessage()) {
      _sendWelcomeMessage();
    }
  }

  // Function to save chat history for the specific user to SharedPreferences
  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'chat_history_${widget.userEmail}', json.encode(messages));
  }

  // Function to get the welcome message
  String _getWelcomeMessage() {
    return "Welcome to Hajzi Bot! How can I assist you today? Here are some options you can ask:\n\n"
        "1. Book an appointment\n"
        "2. How to transfer to a Customer\n"
        "3. Get assistance with using the app\n"
        "4. Contact admin";
  }

  // Function to handle sending a welcome message
  Future<void> _sendWelcomeMessage() async {
    final String welcomeMessage = _getWelcomeMessage();

    // Add the assistant message to the messages list
    setState(() {
      messages.add({"role": "assistant", "content": welcomeMessage});
    });

    // Save chat history after showing the welcome message
    await _saveChatHistory();
  }

  // Function to handle API calls to GPT or predefined responses
  Future<void> sendMessage(String userMessage) async {
    setState(() {
      isLoading = true;
      messages.add({"role": "user", "content": userMessage});
    });

    // Save the message history after user sends a message
    await _saveChatHistory();

    // Check if the user selects option 1
    if (userMessage.trim() == "1") {
      setState(() {
        messages.add({
          "role": "assistant",
          "content":
              "You can book an appointment by pressing on a specific shop from Home page and press Book Appointment then choose the available times, if u need any further help, let me know 😊 "
        });
        isLoading = false; // Stop the loading state
      });
      await _saveChatHistory();
      return;
    }

    // Check if the user selects option 1
    if (userMessage.trim() == "2") {
      setState(() {
        messages.add({
          "role": "assistant",
          "content":
          "You can transfer to Customer by clicking on Customer from the App's menu then it will ask for payment method, if u need any further help, let me know 😊"
        });
        isLoading = false; // Stop the loading state
      });
      await _saveChatHistory();
      return;
    }

    // Check if the user selects option 4
    if (userMessage.trim() == "4") {
      setState(() {
        messages.add({
          "role": "assistant",
          "content": "You can contact the admin at: 0597754602"
        });
        isLoading = false; // Stop the loading state
      });
      await _saveChatHistory();
      return;
    }

    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "model": "gpt-3.5-turbo",
          "messages": messages, // Send entire chat history
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String botMessage = data['choices'][0]['message']['content'];

        setState(() {
          messages.add({"role": "assistant", "content": botMessage});
        });
        await _saveChatHistory();
      } else {
        debugPrint('Failed to fetch response: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error sending message: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history_${widget.userEmail}');
    setState(() {
      messages.clear();
    });
    _sendWelcomeMessage(); // Add welcome message again
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          'Hajzi Bot',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: _confirmDeleteHistory, // Open confirmation dialog
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
                        isUser ? "Me" : "Hajzi Bot",
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
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
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
