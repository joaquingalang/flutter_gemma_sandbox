import 'package:flutter/material.dart';
import 'package:flutter_gemma_sandbox/pages/chat_page.dart';
import 'package:sizer/sizer.dart';

void main() {
  runApp(
    FlutterGemmaSandbox()
  );
}

class FlutterGemmaSandbox extends StatelessWidget {
  const FlutterGemmaSandbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          home: ChatPage(),
          debugShowCheckedModeBanner: false,
        );
      }
    );
  }
}
