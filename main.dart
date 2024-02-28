import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List',
      home: MyHomePage(prefs: prefs),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final SharedPreferences prefs;

  const MyHomePage({required this.prefs});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _titleController = TextEditingController();
  List<ToDo> _tasks = [];

  get title => null;

  get completed => null;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _loadTasks() async {
    final taskList = widget.prefs.getStringList('tasks') ?? [];
    _tasks = taskList.map((task) => ToDo.fromJson(task)).toList();
    setState(() {});
  }

  void _saveTasks() async {
    final taskList = _tasks.map((task) => jsonEncode(task.toJson())).toList();
    await widget.prefs.setStringList('tasks', taskList.cast<String>());
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'completed': completed,
    };
  }

  void _addTask() {
    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _tasks.add(ToDo(title: title));
        _titleController.text = '';
      });
      _saveTasks();
    }
  }

  void _toggleCompleted(int index) {
    setState(() {
      _tasks[index].completed = !_tasks[index].completed;
    });
    _saveTasks();
  }

  void _deleteTask(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Task'),
          content: Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _tasks.removeAt(index);
      });
      _saveTasks();
    } else {
      setState(() {
        _saveTasks();
      });
    }
  }

  void deleteAllTasks() {
    setState(() {
      _tasks.clear();
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Add new task',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _deleteTaskConfirmationDialog(context),
                  onDismissed: (_) => _deleteTask(index),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete),
                  ),
                  child: ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration:
                            task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: Checkbox(
                      value: task.completed,
                      onChanged: (value) => _toggleCompleted(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: Icon(Icons.add),
      ),
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(                  
                  title: Text("Delete all tasks?"),
                  content: Text("Are you sure that you want to delete all the tasks?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        deleteAllTasks();
                        Navigator.pop(context);
                      },
                      child: Text("Delete"),
                    ),
                  ],
                );
              },
            );
          },
          child: Text('Delete all tasks'),
        ),
      ],
    );
  }

  Future<bool?> _deleteTaskConfirmationDialog(BuildContext context) async {
    return true;
  }
}

class ToDo {
  final String title;
  bool completed;

  ToDo({required this.title, this.completed = false});

  factory ToDo.fromJson(String json) {
    final map = jsonDecode(json);
    return ToDo(
        title: map['title'] as String, completed: map['completed'] as bool);
  }

  Map<String, dynamic> toJson() => {'title': title, 'completed': completed};
}
