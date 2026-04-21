import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_gemma_sandbox/enums/sender.dart';
import 'package:sizer/sizer.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.content,
    required this.sender,
    this.imageBytes,
    this.hasAudio = false,
  });

  final String content;
  final Sender sender;
  final Uint8List? imageBytes;
  final bool hasAudio;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(imageBytes!, fit: BoxFit.cover),
                ),
              if (imageBytes != null && (content.isNotEmpty || hasAudio))
                SizedBox(height: 6),

              // Audio chip
              if (hasAudio)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, size: 14, color: Colors.white70),
                    SizedBox(width: 4),
                    Text('Audio', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              if (hasAudio && content.isNotEmpty)
                SizedBox(height: 4),

              // Text / Markdown
              if (content.isNotEmpty)
                sender == Sender.gemma
                    ? MarkdownBody(
                        data: content,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: TextStyle(fontSize: 16),
                          code: TextStyle(fontSize: 14, backgroundColor: Colors.black12),
                        ),
                      )
                    : Text(content, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
