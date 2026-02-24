import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 0)
class TodoItem extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final bool isDone;

  @HiveField(3)
  final DateTime? doneAt;

  TodoItem({
    required this.title,
    required this.createdAt,
    required this.isDone,
    required this.doneAt,
  });

  TodoItem copyWith({
    String? title,
    DateTime? createdAt,
    bool? isDone,
    DateTime? doneAt,
    bool clearDoneAt = false,
  }) {
    return TodoItem(
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      isDone: isDone ?? this.isDone,
      doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
    );
  }
}
