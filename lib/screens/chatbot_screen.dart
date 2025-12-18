import 'package:flutter/material.dart';

/// Placeholder chatbot screen.
/// In future iterations, this will use the CSV service data and
/// talk to a FastAPI backend for intelligent matching.
class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Chatbot coming soon.\nThis will help you find services using your CSV data.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


