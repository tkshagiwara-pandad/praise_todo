import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'notification_service.dart';
import 'todo_home_page.dart';
import 'todo_item.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TodoItemAdapter());

  await Hive.openBox<TodoItem>('todos_v1');
  await Hive.openBox('meta_v1'); // ✅ streakなどのメタ情報用

  await NotificationService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const TodoHomePage(),
    );
  }
}
