import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_sandbox/components/chat_bubble.dart';
import 'package:flutter_gemma_sandbox/enums/sender.dart';
import 'package:flutter_gemma_sandbox/widgets/chat_view.dart';
import 'package:flutter_gemma_sandbox/widgets/stage_views.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

const _modelUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

enum _Stage { downloading, loading, ready, error }

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.systemInstruction});

  final String systemInstruction;

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
  Uint8List? _pendingAudioBytes;
  bool _isRecording = false;
  final AudioRecorder _recorder = AudioRecorder();

  final TextEditingController _messageController = TextEditingController();
  final List<ChatBubble> _logs = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
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
        supportAudio: true,
      );
      print('[bootstrap] Model loaded. Creating chat session...');

      final chat = await model.createChat(
        supportImage: true,
        supportAudio: true,
        systemInstruction: widget.systemInstruction,
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

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/gemma_audio.wav';
    await _recorder.start(
      RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: path,
    );
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    setState(() {
      _isRecording = false;
      _pendingAudioBytes = bytes;
    });
  }

  Future<void> _sendUserMessage() async {
    if (_chat == null || _isGenerating) return;
    final content = _messageController.text.trim();
    if (content.isEmpty && _pendingImageBytes == null && _pendingAudioBytes == null) return;

    final imageBytes = _pendingImageBytes;
    final audioBytes = _pendingAudioBytes;
    _messageController.clear();
    setState(() {
      _logs.insert(0, ChatBubble(
        content: content,
        sender: Sender.user,
        imageBytes: imageBytes,
        hasAudio: audioBytes != null,
      ));
      _isGenerating = true;
      _streamingBuffer = '';
      _pendingImageBytes = null;
      _pendingAudioBytes = null;
    });

    try {
      final Message message;
      if (imageBytes != null) {
        message = Message.withImage(text: content, imageBytes: imageBytes, isUser: true);
      } else if (audioBytes != null && content.isNotEmpty) {
        message = Message.withAudio(text: content, audioBytes: audioBytes, isUser: true);
      } else if (audioBytes != null) {
        message = Message.audioOnly(audioBytes: audioBytes, isUser: true);
      } else {
        message = Message.text(text: content, isUser: true);
      }

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
          _Stage.downloading => DownloadingView(progress: _downloadProgress),
          _Stage.loading    => LoadingView(),
          _Stage.error      => ErrorView(error: _error!, onRetry: _bootstrap),
          _Stage.ready      => ChatView(
              logs: _logs,
              isGenerating: _isGenerating,
              streamingBuffer: _streamingBuffer,
              messageController: _messageController,
              pendingImageBytes: _pendingImageBytes,
              pendingAudioBytes: _pendingAudioBytes,
              isRecording: _isRecording,
              onSend: _sendUserMessage,
              onPickImage: _pickImage,
              onClearImage: () => setState(() => _pendingImageBytes = null),
              onStartRecord: _startRecording,
              onStopRecord: _stopRecording,
              onClearAudio: () => setState(() => _pendingAudioBytes = null),
            ),
        },
      ),
      backgroundColor: Colors.white,
    );
  }
}
