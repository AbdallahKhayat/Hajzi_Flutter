import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../NetworkHandler.dart';
import '../Notifications/push_notifications.dart';
import '../Pages/HomePage.dart';
import '../Profile/ProfileScreen.dart';
import '../constants.dart';
import '../services/stripe_service.dart';
import 'HomeScreen.dart';

class ChatBotScreen extends StatefulWidget {
  final String userEmail; // User's email
  final bool isAIModeInitial; // Initial mode selection
  final Function(Locale) setLocale;

  ChatBotScreen(
      {required this.userEmail,
      this.isAIModeInitial = false,
      required this.setLocale});

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = []; // Chat messages
  bool isLoading = false;

  late String apiKey; // Initialize securely
  late bool isAIMode; // Current mode
  final storage = const FlutterSecureStorage();
  NetworkHandler networkHandler = NetworkHandler();
  final ScrollController _scrollController = ScrollController();
  late int chatbotFlag;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    // TODO: Secure your API key appropriately
    apiKey =
        'sk-svcacct-ySd9tYFFIP7XRYvT8brzJ6ZluXYIhyX9DR768XaSJS5HwREPXdwXKK6nd-yPdmqPrT3BlbkFJn2dTVO5KhP2LnzvB5Shrnu_KZrwoqzb0e0K5fbgSSOTtZDwxXi_goP-rCMvLsSb7AA'; // Replace with secure method
    isAIMode = widget.isAIModeInitial;
    _loadChatHistory();
  }

  Future<void> _loadUserRole() async {
    final role = await storage.read(key: "role");
    setState(() {
      userRole = role;
    });
  }

  // Load chat history based on mode
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('chat_history_${widget.userEmail}');

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
    final String welcomeMessage =
        isAIMode ? _getWelcomeMessageAI() : _getWelcomeMessageHajzi();

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
        case "1"||"١": // Book an appointment
          _addAssistantMessage(
            AppLocalizations.of(context)!.bookAppointmentHelp,
          );
          // Add a special marker to show a button
          messages.add(
              {"role": "assistant", "content": "__SHOW_ALL_SHOPS_BUTTON__"});
          break;

        case "2"||"٢": // Transfer to customer
          _addAssistantMessage(
               AppLocalizations.of(context)!.transferPaymentHelp); // CHANGED
          messages
              .add({"role": "assistant", "content": "__SHOW_PAYMENT_BUTTON__"});
          break;
        case "3"||"٣":
          _addAssistantMessage(AppLocalizations.of(context)!.appAssistanceHelp);
          break;
        case "4"||"٤":
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
          "temperature": 0.7, // Optional: Adjust creativity level
        }),
      );

      debugPrint('Raw Response: ${response.body}'); // Log the raw response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Decode the Arabic content
        String botMessage = utf8.decode(
            data['choices'][0]['message']['content'].toString().runes.toList());

        setState(() {
          messages.add({"role": "assistant", "content": botMessage});
        });
        await _saveChatHistory();
      } else {
        debugPrint('Failed to fetch response: ${response.body}');
        _addAssistantMessage(AppLocalizations.of(context)!.requestNotProcessed); // CHANGED

    }
    } catch (error) {
      debugPrint('Error sending message: $error');
      _addAssistantMessage(AppLocalizations.of(context)!.requestProcessingError);// CHANGED

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
        title: Text(
          AppLocalizations.of(context)!.deleteChatHistoryTitle, // CHANGED
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(AppLocalizations.of(context)!.deleteChatHistoryContent), // CHANGED
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: Text(
              AppLocalizations.of(context)!.cancel, // CHANGED (if not already localized)
              style: const TextStyle(
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
            child: Text(
              AppLocalizations.of(context)!.delete, // CHANGED
              style: const TextStyle(
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
                icon: const Icon(Icons.delete, color: Colors.white),
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
                final content = message["content"] ?? "";
                // 1) Detect special markers
                if (content == "__SHOW_ALL_SHOPS_BUTTON__") {
                  return Align(
                    alignment: Alignment.centerLeft, // Assistant side
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStatePropertyAll(Colors.grey[300]),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => HomeScreen(chatbotFlag:1,filterState: 0)),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.browseAllShops, // CHANGED
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                } else if (content == "__SHOW_PAYMENT_BUTTON__") {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStatePropertyAll(Colors.grey[300]),
                      ),
                      onPressed: () {
                        if (userRole == "user") {
                          _upgradeToCustomer();
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    // Spacing between icon and text
                                    Text(
                                      AppLocalizations.of(context)!.alreadyCustomer,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      color: Colors.blue,
                                      size: 36,
                                    ),
                                    const SizedBox(width: 10),
                                    // Spacing between icon and message
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.alreadyRegisteredCustomer
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                    child: Text(
                                    AppLocalizations.of(context)!.ok,
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          return; // Exit the else block
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context)!.payAndUpgrade, // CHANGED
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

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
                      width: 500,
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

  /// Helper method to show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.featureNotProvided), // CHANGED
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.close, // CHANGED
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Upgrade to Customer if user
  Future<void> _upgradeToCustomer() async {
    if (kIsWeb) {
      _showErrorDialog(
        AppLocalizations.of(context)!.methodNotAvailableOnWeb,
      );
      return;
    }
    await StripeService.instance.makePayment(
      (bool paymentSuccess) async {
        if (paymentSuccess) {
          Map<String, dynamic> data = {'role': "customer"};
          var response = await networkHandler.patch(
            "/user/updateRole/${widget.userEmail}",
            data,
          );
          if (response.statusCode == 200) {
            await storage.write(key: "role", value: "customer");
            // Send an email notification
            final serviceId = 'service_lap99wb';
            final templateId = 'template_d58o7p1';
            final userId = 'tPJQRVN9PQ2jjZ_6C';
            final url =
                Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

            final emailResponse = await http.post(
              url,
              headers: {
                'origin': "https://hajziapp-98152e888858.herokuapp.com",
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'service_id': serviceId,
                'template_id': templateId,
                'user_id': userId,
                'template_params': {
                  'user_name': widget.userEmail,
                },
              }),
            );

            print("Email Response: ${emailResponse.body}");

            final notificationResponse = await networkHandler.post(
              "/notifications/notifyAdmins/customer/${widget.userEmail}",
              // Note: Ensure proper string interpolation
              {},
            );

            print(
                "Notification Response Code: ${notificationResponse.statusCode}");
            print("Notification Response Body: ${notificationResponse.body}");

            if (notificationResponse.statusCode == 200) {
              print("Admin notification sent successfully");
              PushNotifications.init();
            } else {
              print("Failed to notify admins");
            }
            print("User role updated successfully on server.");
            // Show success
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.congratulations, // CHANGED
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  content: Text(
                    AppLocalizations.of(context)!.upgradeSuccess, // CHANGED
                    style: const TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                          AppLocalizations.of(context)!.close, // CHANGED
                          style: const TextStyle(color: Colors.black)),
                    ),
                  ],
                );
              },
            );

            // Reload with new role
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  setLocale: widget.setLocale,
                  filterState: 0,
                ),
              ),
              (route) => false,
            );
          } else {
            // Handle server error when updating role
            _showProfileCreationDialog();
          }
        } else {
          // Handle payment failure (e.g., user hasn't created a profile)
          _showProfileCreationDialog();
        }
      },
    );
  }

  /// Helper method to prompt user to create a profile
  void _showProfileCreationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.profileRequired), // CHANGED
          content: Text(AppLocalizations.of(context)!.pleaseCreateProfile), // CHANGED

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to profile creation page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(), // Replace with your profile creation page
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.createProfile, // CHANGED
                style: const TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel, // CHANGED
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}
