import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Test Groq API
  String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  const String apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  const String model = 'mixtral-8x7b-32768';

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': 'Hello, this is a test message.'},
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final botResponse = data['choices'][0]['message']['content'];
      print('Bot Response: $botResponse');
    } else {
      print('Error: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}