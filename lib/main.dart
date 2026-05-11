import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'presentation/screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Web release builds can receive Firebase config through --dart-define,
    // so the .env asset is optional at runtime.
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: PwMgrApp()));
}

class PwMgrApp extends StatelessWidget {
  const PwMgrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trình quản lý mật khẩu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}
