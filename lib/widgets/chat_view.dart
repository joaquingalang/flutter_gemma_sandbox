import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gemma_sandbox/components/chat_bubble.dart';
import 'package:flutter_gemma_sandbox/enums/sender.dart';

class ChatView extends StatelessWidget {
  const ChatView({
    super.key,
    required this.logs,
    required this.isGenerating,
    required this.streamingBuffer,
    required this.messageController,
    required this.pendingImageBytes,
    required this.pendingAudioBytes,
    required this.isRecording,
    required this.onSend,
    required this.onPickImage,
    required this.onClearImage,
    required this.onStartRecord,
    required this.onStopRecord,
    required this.onClearAudio,
  });

  final List<ChatBubble> logs;
  final bool isGenerating;
  final String streamingBuffer;
  final TextEditingController messageController;
  final Uint8List? pendingImageBytes;
  final Uint8List? pendingAudioBytes;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onStartRecord;
  final VoidCallback onStopRecord;
  final VoidCallback onClearAudio;

  @override
  Widget build(BuildContext context) {
    final bool inputBlocked = isGenerating || isRecording;

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Color(0xFFF3F4F6),
            child: ListView(
              reverse: true,
              children: [
                if (isGenerating)
                  ChatBubble(
                    content: streamingBuffer.isEmpty ? '...' : streamingBuffer,
                    sender: Sender.gemma,
                  ),
                ...logs,
              ],
            ),
          ),
        ),

        if (pendingImageBytes != null)
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(pendingImageBytes!, height: 64, width: 64, fit: BoxFit.cover),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: onClearImage,
                  child: Icon(Icons.cancel, color: Colors.grey),
                ),
              ],
            ),
          ),

        if (pendingAudioBytes != null)
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFD6EEFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 18, color: Color(0xFF7AAACE)),
                      SizedBox(width: 6),
                      Text('Audio recorded', style: TextStyle(fontSize: 13, color: Color(0xFF7AAACE))),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: onClearAudio,
                  child: Icon(Icons.cancel, color: Colors.grey),
                ),
              ],
            ),
          ),

        Container(
          width: double.infinity,
          height: 80,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(offset: Offset(0, -1), color: Colors.black12, blurRadius: 2),
            ],
          ),
          child: Row(
            spacing: 8,
            children: [
              GestureDetector(
                onTap: inputBlocked ? null : onPickImage,
                child: Icon(
                  Icons.image_outlined,
                  color: inputBlocked ? Colors.grey.shade300 : Color(0xFF7AAACE),
                  size: 28,
                ),
              ),

              GestureDetector(
                onTap: isGenerating ? null : (isRecording ? onStopRecord : onStartRecord),
                child: Icon(
                  isRecording ? Icons.stop_circle : Icons.mic_outlined,
                  color: isGenerating
                      ? Colors.grey.shade300
                      : isRecording
                          ? Colors.red
                          : Color(0xFF7AAACE),
                  size: 28,
                ),
              ),

              Expanded(
                child: TextField(
                  controller: messageController,
                  enabled: !inputBlocked,
                  style: TextStyle(fontWeight: FontWeight.w500),
                  cursorColor: Color(0xFF9CD5FF),
                  decoration: InputDecoration(
                    hintText: isRecording ? 'Recording…' : 'Message',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: Colors.grey),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: Colors.grey),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF3F4F6),
                  ),
                ),
              ),

              Opacity(
                opacity: inputBlocked ? 0.4 : 1.0,
                child: GestureDetector(
                  onTap: inputBlocked ? null : onSend,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Color(0xFF7AAACE),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
