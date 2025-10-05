import 'dart:async';
import 'package:biophantom_core/biophantom_core.dart';

class NeurotoxinChatbotService {
  final GroqChatService _groqService = GroqChatService();
  final StreamController<String> _responseController = StreamController<String>.broadcast();
  final StreamController<bool> _isLoadingController = StreamController<bool>.broadcast();

  bool _isInitialized = false;

  /// Stream of AI responses
  Stream<String> get responseStream => _responseController.stream;

  /// Stream of loading state
  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  /// Check if service is ready
  bool get isReady => _isInitialized && _groqService.hasApiKey;

  /// Initialize the Groq service
  Future<void> initialize({String? apiKey}) async {
    try {
      await _groqService.initialize(apiKey: apiKey);

      // Listen to responses
      _groqService.responseStream.listen((response) {
        _responseController.add(response);
      });

      // Listen to loading state
      _groqService.isLoadingStream.listen((isLoading) {
        _isLoadingController.add(isLoading);
      });

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Groq service: $e');
    }
  }

  /// Set API key
  Future<void> setApiKey(String apiKey) async {
    await _groqService.initialize(apiKey: apiKey);
  }

  /// Get danger guidance for high-risk detection
  Future<String> getDangerGuidance(double probability, String context) async {
    if (!isReady) {
      throw StateError('Groq service not ready');
    }

    return await _groqService.getDangerGuidance(probability, context);
  }

  /// Get explanation for detection results
  Future<String> explainResults(double motionProb, double? audioProb, String decision) async {
    if (!isReady) {
      throw StateError('Groq service not ready');
    }

    return await _groqService.explainResults(motionProb, audioProb, decision);
  }

  /// Send custom message to chatbot
  Future<String> sendMessage(String message) async {
    if (!isReady) {
      throw StateError('Groq service not ready');
    }

    return await _groqService.sendMessage(message);
  }

  /// Send message with streaming response
  Future<void> sendMessageStream(String message) async {
    if (!isReady) {
      throw StateError('Groq service not ready');
    }

    await _groqService.sendMessageStream(message);
  }

  /// Test API connection
  Future<bool> testConnection() async {
    if (!_isInitialized) return false;
    return await _groqService.testConnection();
  }

  /// Clear API key
  Future<void> clearApiKey() async {
    await _groqService.clearApiKey();
  }

  /// Get current model
  String get currentModel => _groqService.currentModel;

  /// Set AI model
  void setModel(String model) {
    _groqService.setModel(model);
  }

  // Legacy method for backward compatibility
  String answer(String query) {
    // This is a synchronous fallback - in practice, you'd want to make this async
    if (query.toLowerCase().contains('symptom')) {
      return 'Common neurotoxin symptoms include tremors, cough, and unstable grip.';
    }
    return 'I can answer questions about neurotoxins, symptoms, risks, and treatments.';
  }

  /// Dispose resources
  void dispose() {
    _responseController.close();
    _isLoadingController.close();
    _groqService.dispose();
  }
}
