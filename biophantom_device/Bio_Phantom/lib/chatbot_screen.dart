import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'bot',
      'text':
          'Hello! I\'m your Neurotoxin Detection assistant. How can I help you with neurotoxin exposure concerns today?',
      'timestamp': DateTime.now(),
    },
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  // Groq API configuration - using a currently supported model
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model =
      'llama-3.1-8b-instant'; // Updated to a currently supported model

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isSending) return;

    // Add user message
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': _controller.text,
        'timestamp': DateTime.now(),
      });
      _isSending = true;
    });

    // Clear input
    String userMessage = _controller.text;
    _controller.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    try {
      // Prepare messages for API call (filter out timestamp and format correctly)
      final List<Map<String, dynamic>> formattedMessages = _messages
          .where((msg) => msg['sender'] == 'user' || msg['sender'] == 'bot')
          .map((msg) {
            return {
              'role': msg['sender'] == 'user' ? 'user' : 'assistant',
              'content': msg['text'],
            };
          })
          .toList();

      // Call Groq API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a specialized assistant for neurotoxin detection and exposure concerns. '
                  'Provide accurate information about neurotoxin symptoms, detection methods, and safety protocols. '
                  'Focus specifically on nerve agents, organophosphates, and other neurotoxic substances. '
                  'If asked about topics unrelated to neurotoxins, politely redirect the conversation. '
                  'Always emphasize the importance of professional medical evaluation for suspected exposure.',
            },
            ...formattedMessages,
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': botResponse,
            'timestamp': DateTime.now(),
          });
        });
      } else {
        // Handle specific error codes
        String errorMessage =
            'Sorry, I encountered an error processing your request. Please try again.';
        if (response.statusCode == 401) {
          errorMessage = 'Authentication error. Please check the API key.';
        } else if (response.statusCode == 429) {
          errorMessage =
              'Rate limit exceeded. Please wait a moment and try again.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Server error. Please try again later.';
        } else if (response.statusCode == 400) {
          // Try to parse the error message from the response
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['error']['message'] ?? errorMessage;
          } catch (e) {
            // If we can't parse the error, use the generic message
          }
        }

        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': errorMessage,
            'timestamp': DateTime.now(),
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text':
              'Sorry, I\'m having trouble connecting right now. Please check your internet connection and try again.',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() {
        _isSending = false;
      });

      // Scroll to bottom after response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neurotoxin Detection Assistant'),
        backgroundColor: isDarkMode
            ? const Color(0xFF0D47A1)
            : const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        centerTitle: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/biophantom_logo.png',
            width: 32,
            height: 32,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDarkMode ? Colors.grey.shade900 : Colors.white,
              isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              isDarkMode ? Colors.grey.shade900 : Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDarkMode
                        ? [
                            const Color(0xFF0D47A1).withOpacity(0.1),
                            Colors.transparent,
                            const Color(0xFF0D47A1).withOpacity(0.05),
                          ]
                        : [
                            const Color(0xFFE3F2FD).withOpacity(0.8),
                            Colors.white.withOpacity(0.9),
                            const Color(0xFFE3F2FD).withOpacity(0.6),
                          ],
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['sender'] == 'user';

                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: _buildMessageBubble(
                        message['text'],
                        isUser,
                        message['timestamp'],
                        isDarkMode,
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [Colors.grey.shade800, Colors.grey.shade900]
                      : [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [Colors.grey[700]!, Colors.grey[800]!]
                              : [Colors.grey[100]!, Colors.grey[200]!],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask about neurotoxin detection...',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          suffixIcon: _isSending
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDarkMode
                                            ? Colors.white
                                            : const Color(0xFF1976D2),
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isSending,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    String text,
    bool isUser,
    DateTime timestamp,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode
                    ? const Color(0xFF1976D2)
                    : const Color(0xFF1976D2),
              ),
              child: const Center(
                child: Icon(Icons.science, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUser
                      ? [const Color(0xFF1976D2), const Color(0xFF1565C0)]
                      : isDarkMode
                      ? [Colors.grey[700]!, Colors.grey[800]!]
                      : [Colors.grey[200]!, Colors.grey[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? Colors.blue : Colors.grey).withOpacity(
                      0.2,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDarkMode ? Colors.white : Colors.black87),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isUser
                          ? Colors.white70
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode
                    ? const Color(0xFF0D47A1)
                    : const Color(0xFF0D47A1),
              ),
              child: const Center(
                child: Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
