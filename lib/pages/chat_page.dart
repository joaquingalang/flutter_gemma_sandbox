import 'package:flutter/material.dart';
import 'package:flutter_gemma_sandbox/components/chat_bubble.dart';
import 'package:flutter_gemma_sandbox/enums/sender.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final TextEditingController _messageController = TextEditingController();
  List<ChatBubble> _logs = [];

  void _sendUserMessage() {
    final content = _messageController.text;
    if (content.isNotEmpty) {
      _messageController.clear();
      List<ChatBubble> newLogs = _logs;
      newLogs.insert(0, ChatBubble(content: content, sender: Sender.user));
      setState(() {
        _logs = newLogs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Flutter w/ Gemma 4',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF9CD5FF),
        elevation: 10,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat body
            Expanded(
              child: Container(
                color: Color(0xFFF3F4F6),
                child: ListView(
                  reverse: true,
                  children: _logs,
                ),
              ),
            ),

            Container(
              width: double.infinity,
              height: 80,
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, -1),
                    color: Colors.black12,
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(fontWeight: FontWeight.w500),
                      cursorColor: Color(0xFF9CD5FF),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF3F4F6),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _sendUserMessage,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Color(0xFF7AAACE),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      child: Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
