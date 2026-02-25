import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'notification_service.dart';
import 'todo_item.dart';
import 'package:praise_todo/praise_words.dart';
import 'package:praise_todo/nightly_words.dart';


class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

enum PraiseLevel { low, mid, high }

class _TodoHomePageState extends State<TodoHomePage> {
  static const String todosBoxName = 'todos_v1';
  static const String metaBoxName = 'meta_v1';
  static const int nightlyId = 2230;

  late final Box<TodoItem> _todos;
  late final Box _meta;

  bool _hideCompleted = false;

  final _rand = Random();
  PraiseLevel _level = PraiseLevel.mid;

  @override
  void initState() {
    super.initState();
    _todos = Hive.box<TodoItem>(todosBoxName);
    _meta = Hive.box(metaBoxName);

    _loadPraiseLevel();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshNightlySchedule();
      setState(() {});
    });
  }

  // ---- Praise Level (persist) ----
  void _loadPraiseLevel() {
    final s = _meta.get('praise_level') as String?;
    if (s == null) {
      _level = PraiseLevel.mid;
      return;
    }

    switch (s) {
      case 'low':
        _level = PraiseLevel.low;
        break;
      case 'mid':
        _level = PraiseLevel.mid;
        break;
      case 'high':
        _level = PraiseLevel.high;
        break;
      default:
        _level = PraiseLevel.mid;
    }
  }

  Future<void> _savePraiseLevel(PraiseLevel v) async {
    _level = v;
    await _meta.put('praise_level', _level.name);
    await _refreshNightlySchedule();
    setState(() {});
  }

  // ---- counts ----
  int get _totalCount => _todos.length;
  int get _doneCount => _todos.values.where((e) => e.isDone).length;
  int get _leftCount => _totalCount - _doneCount;

  int get _doneTodayCount {
    final now = DateTime.now();
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    return _todos.values.where((e) {
      final d = e.doneAt;
      return e.isDone && d != null && sameDay(d, now);
    }).length;
  }

  int get _streakDays => (_meta.get('streak_days') as int?) ?? 0;

  // ---- notification ----
  Future<void> _refreshNightlySchedule() async {
    final title = _nightlyTitle();
    final body = _nightlyBody();

    // ✅ 毎回2230をキャンセルして作り直す
    await NotificationService.instance.cancel(nightlyId);

    await NotificationService.instance.scheduleDaily2230(
      id: nightlyId,
      title: title,
      body: body,
    );
  }

  String _nightlyTitle() {
    switch (_level) {
      case PraiseLevel.low:
        return '今日のまとめ';
      case PraiseLevel.mid:
        return '今日のまとめ、見せて。';
      case PraiseLevel.high:
        return '今日のまとめ';
    }
  }

  String _nightlyBody() {
    final stats =
        '今日の完了：$_doneTodayCount件\n全体：$_doneCount完了（残り：$_leftCount）';

    // ✅ 今日の完了が0件のときだけ、専用メッセージにする
if (_doneTodayCount == 0) {
  final zeroLow = <String>[
    '今日はここまでで大丈夫。生きてるだけでえらい。',
    '今日は休む日だったのかも。ちゃんと守れたね。',
    'できなかった日も、ちゃんと必要な日。',
    '何もしない日があっても、あなたの価値は減らないよ。',
    '今日も一日おつかれさま。明日でOK。',
    '今日を乗り切った。それだけで十分。',
    '今日は「整える日」。それも大事な仕事だよ。',
    'うまくいかない日も、あなたのせいじゃない。',
    '今日のあなたも、ちゃんと味方でいてあげよう。',
    '疲れてたなら、休めたことがいちばん偉い。',
  ];

  final zeroMid = <String>[
    '今日はゼロでも大丈夫。ここまで来たことがすでに偉い。',
    '止まった日も、ちゃんと意味がある。休めたなら勝ち。',
    '今日は回復のターン。ちゃんと整えていこう。',
    'できなかった自分も、ちゃんと味方にしてあげよう。',
    '今日を責めない。明日を軽くするために。',
    '頑張れない日があるのは、頑張ってきた証拠。',
    '今日は「何もしない」を選べた。それは強さだよ。',
    '進めなかった日も、ちゃんと人生の一部。',
    '大丈夫。あなたはちゃんと前に進んでる。',
    '今日を終えられた。それだけで合格。',
    '心がしんどい時は、休むことが一番の前進。',
    '今日は自分を守れた。それが本当に大切。',
    'できない日があるから、続けられる日が来る。',
    '明日、ほんの少しだけでいい。あなたのペースで。',
  ];

  final zeroHigh = <String>[
    '今日はゼロでもOK。\nあなたはちゃんと戦ってる。',
    '休むのも才能。\n今日のあなた、最高に賢い。',
    'ゼロの日があるから、次の一歩が強くなる。',
    '今日は回復。\n明日また勝てばいい。',
    '今日も生き抜いた。\nそれが一番すごい。',
    '今日はできなくていい日。\nあなたは十分頑張ってる。',
    '今日は「守る日」。\n心を守れたなら勝ち。',
    '何もできなかったんじゃない。\n今日を耐えたんだよ。',
    '今日は休んでいい。\nその許可を出せたあなたが偉い。',
    '明日はまた少しだけ。\nあなたのペースでいこう。',
    '今日のあなたも大切。\n置いていかない。',
    'できない日があっても、あなたはちゃんと価値がある。',
    'ここまで来た。\nそれだけで十分すごい。',
    '今日は「何もしない」を選べた。\nそれも立派な選択。',
  ];

  final zeroList = switch (_level) {
    PraiseLevel.low => zeroLow,
    PraiseLevel.mid => zeroMid,
    PraiseLevel.high => zeroHigh,
  };

  final pick = zeroList[_rand.nextInt(zeroList.length)];
  return '$stats\n\n$pick';
}

    // ✅ 1件以上完了したときの通常メッセージ（ランダム）
    final list = switch (_level) {
      PraiseLevel.low => NightlyWords.low,
      PraiseLevel.mid => NightlyWords.mid,
      PraiseLevel.high => NightlyWords.high,
    };

    final pick = list[_rand.nextInt(list.length)];
    return '$stats\n\n$pick';
  }

  // ---- CRUD ----
  Future<void> _addTodo() async {
    final text = await _showTextDialog(
      title: 'Todoを追加',
      initial: '',
      hint: '例：英語 30分 / SQL 1問 / スクワット 20回',
      okText: '追加',
    );
    if (text == null) return;
    final t = text.trim();
    if (t.isEmpty) return;

    await _todos.add(
      TodoItem(
        title: t,
        createdAt: DateTime.now(),
        isDone: false,
        doneAt: null,
      ),
    );

    await _refreshNightlySchedule();
    setState(() {});
  }

  Future<void> _editTodo(dynamic key, TodoItem item) async {
    final text = await _showTextDialog(
      title: 'Todoを編集',
      initial: item.title,
      hint: 'Todo内容',
      okText: '保存',
    );
    if (text == null) return;
    final t = text.trim();
    if (t.isEmpty) return;

    await _todos.put(key, item.copyWith(title: t));
    await _refreshNightlySchedule();
    setState(() {});
  }

  Future<void> _deleteTodo(dynamic key) async {
    await _todos.delete(key);
    await _refreshNightlySchedule();
    setState(() {});
  }

  Future<void> _toggleDone(dynamic key, TodoItem item) async {
    final now = DateTime.now();
    final newIsDone = !item.isDone;

    final updated = item.copyWith(
      isDone: newIsDone,
      doneAt: newIsDone ? now : null,
      clearDoneAt: !newIsDone,
    );

    await _todos.put(key, updated);

    if (newIsDone) {
      _updateStreakIfNeeded(now);
      _praise(item.title);
    }

    await _refreshNightlySchedule();
    setState(() {});
  }

  void _updateStreakIfNeeded(DateTime now) {
    final last = _meta.get('last_done_day') as String?;
    final todayKey = '${now.year}-${now.month}-${now.day}';

    if (last == todayKey) return;

    final yesterday = now.subtract(const Duration(days: 1));
    final yKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    int streak = (_meta.get('streak_days') as int?) ?? 0;
    if (last == yKey) {
      streak += 1;
    } else {
      streak = 1;
    }

    _meta.put('streak_days', streak);
    _meta.put('last_done_day', todayKey);
  }

  // ---- Praise messages ----
  String _praiseTitle() {
    switch (_level) {
      case PraiseLevel.low:
        return '完了';
      case PraiseLevel.mid:
        return 'よくできたね';
      case PraiseLevel.high:
        return 'ほんとに偉い';
    }
  }

  String _praiseBody(String todoTitle) {
    final list = switch (_level) {
      PraiseLevel.low => PraiseWords.low,
      PraiseLevel.mid => PraiseWords.mid,
      PraiseLevel.high => PraiseWords.high,
    };

    final pick = list[_rand.nextInt(list.length)];
    return '$pick\n\n「$todoTitle」完了。';
  }

  void _praise(String todoTitle) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_praiseTitle()),
        content: Text(_praiseBody(todoTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_level == PraiseLevel.high ? 'よし、えらい' : 'うん、大丈夫'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTextDialog({
    required String title,
    required String initial,
    required String hint,
    required String okText,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // キーボードにかぶらないように制御
      backgroundColor: Colors.transparent,
      builder: (_) => _TodoInputDialog(
        title: title,
        initial: initial,
        hint: hint,
        okText: okText,
      ),
    );
  }

  // ---- list helpers（dynamic key）----
  List<MapEntry<dynamic, TodoItem>> _activeItems() {
    final entries = _todos.toMap().entries.toList()
      ..sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));
    return entries.where((e) => !e.value.isDone).toList();
  }

  List<MapEntry<dynamic, TodoItem>> _doneItems() {
    final entries = _todos.toMap().entries.toList()
      ..sort((a, b) {
        final ad = a.value.doneAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.value.doneAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    return entries.where((e) => e.value.isDone).toList();
  }

  String _subtitle(TodoItem item) {
    final created = item.createdAt;
    final c =
        '${created.month}/${created.day} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
    if (!item.isDone) return '作成：$c';

    final d = item.doneAt;
    if (d == null) return '完了';
    final done =
        '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '作成：$c / 完了：$done';
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo（完了したら全力で褒める）'),
        actions: [
          IconButton(
            tooltip: '完了済みを隠す',
            onPressed: () => setState(() => _hideCompleted = !_hideCompleted),
            icon: Icon(_hideCompleted ? Icons.visibility_off : Icons.visibility),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTodo,
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
      body: ValueListenableBuilder(
        valueListenable: _todos.listenable(),
        builder: (context, Box<TodoItem> box, _) {
          final actives = _activeItems();
          final dones = _doneItems();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '全部：$_totalCount / 完了：$_doneCount（今日：$_doneTodayCount） / 残り：$_leftCount',
                      ),
                      const SizedBox(height: 6),
                      Text('連続達成：$_streakDays日'),
                      const SizedBox(height: 12),

                      SegmentedButton<PraiseLevel>(
                        segments: const [
                          ButtonSegment(
                            value: PraiseLevel.low,
                            label: Text('低'),
                          ),
                          ButtonSegment(
                            value: PraiseLevel.mid,
                            label: Text('中'),
                          ),
                          ButtonSegment(
                            value: PraiseLevel.high,
                            label: Text('高'),
                          ),
                        ],
                        selected: {_level},
                        onSelectionChanged: (s) => _savePraiseLevel(s.first),
                      ),

                      const SizedBox(height: 12),

                      FilledButton.icon(
                        onPressed: () async {
                          await NotificationService.instance.showNow(
                            id: 9999,
                            title: _nightlyTitle(),
                            body: _nightlyBody(),
                          );
                        },
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('まとめ（今すぐ）'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                '未完了（${actives.length}）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              if (actives.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Todoを追加しよう。完了したら全力で褒める。'),
                )
              else
                ...actives.map((entry) {
                  final key = entry.key;
                  final item = entry.value;
                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: item.isDone,
                        onChanged: (_) => _toggleDone(key, item),
                      ),
                      title: Text(item.title),
                      subtitle: Text(_subtitle(item)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '編集',
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editTodo(key, item),
                          ),
                          IconButton(
                            tooltip: '削除',
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTodo(key),
                          ),
                        ],
                      ),
                      onTap: () => _toggleDone(key, item),
                    ),
                  );
                }),

              const SizedBox(height: 16),

              if (!_hideCompleted)
                ExpansionTile(
                  initiallyExpanded: false,
                  title: Text('完了済み（${dones.length}）'),
                  children: dones.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('まだ完了はない。ここが増えると気持ちいい。'),
                          )
                        ]
                      : dones.map((entry) {
                          final key = entry.key;
                          final item = entry.value;
                          return ListTile(
                            leading: Checkbox(
                              value: item.isDone,
                              onChanged: (_) => _toggleDone(key, item),
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: Text(_subtitle(item)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: '編集',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editTodo(key, item),
                                ),
                                IconButton(
                                  tooltip: '削除',
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteTodo(key),
                                ),
                              ],
                            ),
                            onTap: () => _toggleDone(key, item),
                          );
                        }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TodoInputDialog extends StatefulWidget {
  final String title;
  final String initial;
  final String hint;
  final String okText;

  const _TodoInputDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.okText,
  });

  @override
  State<_TodoInputDialog> createState() => _TodoInputDialogState();
}

class _TodoInputDialogState extends State<_TodoInputDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    _focusNode = FocusNode();
    
    // Web/Mobileでキーボードを確実に出すため、開始直後にフォーカス要求
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // コンテンツの高さを制限しつつ、キーボード対応のためにSingleChildScrollViewを使用
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // キーボードの高さ分だけ下を浮かせる
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 更新されたことがわかるようにアイコンを追加
                  Row(
                    children: [
                      const Icon(Icons.edit_note, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      fillColor: Colors.grey[100],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) {
                      if (_controller.text.isNotEmpty) {
                        Navigator.pop(context, _controller.text);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        Navigator.pop(context, _controller.text);
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.okText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
