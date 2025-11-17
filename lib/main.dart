import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimpList',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<TodoItem> _todos = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosJson = prefs.getString('todos');
    if (todosJson != null) {
      final List<dynamic> decoded = json.decode(todosJson);
      setState(() {
        _todos = decoded.map((item) => TodoItem.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_todos.map((item) => item.toJson()).toList());
    await prefs.setString('todos', encoded);
  }

  void _addTodo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Todo'),
        content: TextField(
          controller: _textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter todo text'),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _todos.add(TodoItem(text: value, isDone: false));
              });
              _saveTodos();
              _textController.clear();
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _textController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                setState(() {
                  _todos.add(TodoItem(text: _textController.text, isDone: false));
                });
                _saveTodos();
                _textController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleTodo(int index) {
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
    _saveTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _addTodo,
                child: const Text('Add Todo Item'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _todos.length,
                itemBuilder: (context, index) {
                  final todo = _todos[index];
                  return ListTile(
                    title: Text(
                      todo.text,
                      style: TextStyle(
                        decoration: todo.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    onTap: () => _toggleTodo(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class TodoItem {
  String text;
  bool isDone;

  TodoItem({required this.text, required this.isDone});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isDone': isDone,
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        text: json['text'],
        isDone: json['isDone'],
      );
}
