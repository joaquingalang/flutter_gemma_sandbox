import 'package:flutter/material.dart';
import 'package:flutter_gemma_sandbox/enums/sender.dart';
import 'package:sizer/sizer.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.content, required this.sender});

  final String content;
  final Sender sender;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: (sender == Sender.user)
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: 12, right: 12, bottom: 16),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (sender == Sender.user)
                ? Color(0xFF9CD5FF)
                : Color(0xFFBCC1CB),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: (sender == Sender.gemma) ? Radius.zero : Radius.circular(12),
              bottomRight: (sender == Sender.user) ? Radius.zero : Radius.circular(12),
            ),
          ),
          constraints: BoxConstraints(maxWidth: 60.w),
          child: Text(content, style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
