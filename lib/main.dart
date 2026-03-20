import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Added Riverpod
import 'firebase_options.dart';
import 'core/router.dart'; // 2. Added your router file

void main() async {
  // Ensure the Flutter environment is ready before doing anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the auto-generated config from FlutterFire CLI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Wrap the app in ProviderScope to turn on Riverpod's state management
  runApp(const ProviderScope(child: OdoGoApp()));
}

// 4. Changed from StatelessWidget to ConsumerWidget so it can listen to Riverpod
class OdoGoApp extends ConsumerWidget {
  const OdoGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 5. Watch the router provider so the app knows where to navigate
    final router = ref.watch(routerProvider);

    // 6. Changed to MaterialApp.router (Removed the 'home:' property)
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'OdoGo',
      routerConfig: router,
    );
  }
}
