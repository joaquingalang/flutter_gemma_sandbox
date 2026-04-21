import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_sandbox/components/chat_bubble.dart';
import 'package:flutter_gemma_sandbox/enums/sender.dart';
import 'package:image_picker/image_picker.dart';

const _modelUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

enum _Stage { downloading, loading, ready, error }

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  _Stage _stage = _Stage.downloading;
  int _downloadProgress = 0;
  String? _error;

  InferenceChat? _chat;
  bool _isGenerating = false;
  String _streamingBuffer = '';
  Uint8List? _pendingImageBytes;

  final TextEditingController _messageController = TextEditingController();
  final List<ChatBubble> _logs = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _stage = _Stage.downloading;
      _downloadProgress = 0;
      _error = null;
    });

    try {
      if (!FlutterGemma.hasActiveModel()) {
        print('[bootstrap] No active model found, starting download...');
        print('[bootstrap] URL: $_modelUrl');

        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.litertlm,
        ).fromNetwork(
          _modelUrl,
          token: dotenv.env['HF_TOKEN'],
        ).withProgress((progress) {
          print('[bootstrap] Download progress: $progress%');
          setState(() => _downloadProgress = progress.toInt());
        }).install();

        print('[bootstrap] Model downloaded and installed.');
      } else {
        print('[bootstrap] Model already installed, skipping download.');
        setState(() => _downloadProgress = 100);
      }

      setState(() => _stage = _Stage.loading);
      print('[bootstrap] Loading model into memory...');

      final model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: PreferredBackend.gpu,
        supportImage: true,
      );
      print('[bootstrap] Model loaded. Creating chat session...');

      final chat = await model.createChat(
        supportImage: true,
        systemInstruction: 'You are a helpful assistant. Be concise and clear.',
      );
      print('[bootstrap] Chat session ready.');

      setState(() {
        _chat = chat;
        _stage = _Stage.ready;
      });
    } catch (e, stack) {
      print('[bootstrap] ERROR: $e');
      print('[bootstrap] Stack: $stack');
      setState(() {
        _error = e.toString();
        _stage = _Stage.error;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _pendingImageBytes = bytes);
  }

  Future<void> _sendUserMessage() async {
    if (_chat == null || _isGenerating) return;
    final content = _messageController.text.trim();
    if (content.isEmpty && _pendingImageBytes == null) return;

    final imageBytes = _pendingImageBytes;
    _messageController.clear();
    setState(() {
      _logs.insert(0, ChatBubble(content: content, sender: Sender.user, imageBytes: imageBytes));
      _isGenerating = true;
      _streamingBuffer = '';
      _pendingImageBytes = null;
    });

    try {
      final message = imageBytes != null
          ? Message.withImage(text: content, imageBytes: imageBytes, isUser: true)
          : Message.text(text: content, isUser: true);

      await _chat!.addQueryChunk(message);

      _chat!.generateChatResponseAsync().listen(
        (response) {
          if (response is TextResponse) {
            setState(() => _streamingBuffer += response.token);
          }
        },
        onDone: () => setState(() {
          _logs.insert(0, ChatBubble(content: _streamingBuffer, sender: Sender.gemma));
          _streamingBuffer = '';
          _isGenerating = false;
        }),
        onError: (e) {
          print('[chat] Stream error: $e');
          setState(() {
            _logs.insert(0, ChatBubble(content: 'Error: $e', sender: Sender.gemma));
            _streamingBuffer = '';
            _isGenerating = false;
          });
        },
      );
    } catch (e) {
      print('[chat] Send error: $e');
      setState(() {
        _logs.insert(0, ChatBubble(content: 'Error: $e', sender: Sender.gemma));
        _isGenerating = false;
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
        child: switch (_stage) {
          _Stage.downloading => _DownloadingView(progress: _downloadProgress),
          _Stage.loading    => _LoadingView(),
          _Stage.error      => _ErrorView(error: _error!, onRetry: _bootstrap),
          _Stage.ready      => _ChatView(
              logs: _logs,
              isGenerating: _isGenerating,
              streamingBuffer: _streamingBuffer,
              messageController: _messageController,
              pendingImageBytes: _pendingImageBytes,
              onSend: _sendUserMessage,
              onPickImage: _pickImage,
              onClearImage: () => setState(() => _pendingImageBytes = null),
            ),
        },
      ),
      backgroundColor: Colors.white,
    );
  }
}

// ---------------------------------------------------------------------------
// Stage views
// ---------------------------------------------------------------------------

class _DownloadingView extends StatelessWidget {
  const _DownloadingView({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Downloading model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress > 0 ? progress / 100.0 : null,
              color: Color(0xFF9CD5FF),
              backgroundColor: Color(0xFFD6EEFF),
            ),
            SizedBox(height: 8),
            Text(progress > 0 ? '$progress%' : 'Starting…', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF9CD5FF)),
          SizedBox(height: 16),
          Text('Loading model into memory…', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 12),
            Text('Failed to load model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(error, style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({
    required this.logs,
    required this.isGenerating,
    required this.streamingBuffer,
    required this.messageController,
    required this.pendingImageBytes,
    required this.onSend,
    required this.onPickImage,
    required this.onClearImage,
  });

  final List<ChatBubble> logs;
  final bool isGenerating;
  final String streamingBuffer;
  final TextEditingController messageController;
  final Uint8List? pendingImageBytes;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
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

        // Image preview strip
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
              // Image picker button
              GestureDetector(
                onTap: isGenerating ? null : onPickImage,
                child: Icon(
                  Icons.image_outlined,
                  color: isGenerating ? Colors.grey.shade300 : Color(0xFF7AAACE),
                  size: 28,
                ),
              ),

              Expanded(
                child: TextField(
                  controller: messageController,
                  enabled: !isGenerating,
                  style: TextStyle(fontWeight: FontWeight.w500),
                  cursorColor: Color(0xFF9CD5FF),
                  decoration: InputDecoration(
                    hintText: 'Message',
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
                opacity: isGenerating ? 0.4 : 1.0,
                child: GestureDetector(
                  onTap: isGenerating ? null : onSend,
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
