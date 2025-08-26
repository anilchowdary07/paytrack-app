import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:payment_reminder_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:payment_reminder_app/firebase_options.dart';
import 'package:payment_reminder_app/providers/theme_provider.dart';
import 'package:payment_reminder_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService().init();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}
