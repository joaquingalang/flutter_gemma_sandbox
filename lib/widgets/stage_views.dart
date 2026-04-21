import 'package:flutter/material.dart';

class DownloadingView extends StatelessWidget {
  const DownloadingView({super.key, required this.progress});

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

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

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

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

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
