import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma_sandbox/pages/chat_page.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:sizer/sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/.env');
  final hfToken = dotenv.env['HF_TOKEN'];
  print('[main] HF_TOKEN present: ${hfToken != null && hfToken.isNotEmpty}');

  print('[main] Initializing FlutterGemma...');
  await FlutterGemma.initialize(huggingFaceToken: hfToken);
  print('[main] FlutterGemma initialized.');

  runApp(FlutterGemmaSandbox());
}

class FlutterGemmaSandbox extends StatelessWidget {
  const FlutterGemmaSandbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          home: ChatPage(systemInstruction: 'You are a helpful assistant. Be concise and clear.'),
          debugShowCheckedModeBanner: false,
        );
      }
    );
  }
}
