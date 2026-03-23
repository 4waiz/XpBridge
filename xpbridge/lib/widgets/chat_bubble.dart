import 'package:flutter/material.dart';

import '../models/ai_chat_message.dart';
import 'xp_ai.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    return XPAiTextBubble(
      text: message.content,
      isUser: message.isUser,
      isLoading: message.isLoading,
      timestamp: message.timestamp,
    );
  }
}
