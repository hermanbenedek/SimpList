import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class _TodoListPageState extends State<TodoListPage> with TickerProviderStateMixin {
  List<TodoItem> _todos = [];
  List<TodoItem> _trash = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final ScrollController _scrollController = ScrollController();
  int? _editingIndex;
  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, Animation<double>> _slideAnimations = {};
  final Map<int, AnimationController> _bounceControllers = {};
  final Map<int, Animation<double>> _bounceAnimations = {};

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
        _initializeControllers();
      });
    }
  }

  void _initializeControllers() {
    for (int i = 0; i < _todos.length; i++) {
      if (!_controllers.containsKey(i)) {
        _controllers[i] = TextEditingController(text: _todos[i].text);
        _focusNodes[i] = FocusNode();
        _animationControllers[i] = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: this,
        );
        _slideAnimations[i] = Tween<double>(begin: 0, end: -20).animate(
          CurvedAnimation(parent: _animationControllers[i]!, curve: Curves.easeOut),
        );
        _bounceControllers[i] = AnimationController(
          duration: const Duration(milliseconds: 200),
          vsync: this,
        );
        _bounceAnimations[i] = Tween<double>(begin: 1.0, end: 0.9).animate(
          CurvedAnimation(
            parent: _bounceControllers[i]!,
            curve: Curves.easeInOut,
          ),
        );
      }
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_todos.map((item) => item.toJson()).toList());
    await prefs.setString('todos', encoded);
    await _updateWidget();
  }

  Future<void> _updateWidget() async {
    try {
      final String encoded = json.encode(_todos.map((item) => item.toJson()).toList());
      await HomeWidget.saveWidgetData<String>('todos', encoded);
      await HomeWidget.updateWidget(
        iOSName: 'SimpListWidget',
        androidName: 'SimpListWidget',
      );
    } catch (e) {
      // Widget update failed, but don't interrupt the app
      debugPrint('Failed to update widget: $e');
    }
  }

  void _addTodo() {
    setState(() {
      _todos.insert(0, TodoItem(text: '', isDone: false));

      // Shift all existing controllers and focus nodes
      final newControllers = <int, TextEditingController>{};
      final newFocusNodes = <int, FocusNode>{};
      final newAnimationControllers = <int, AnimationController>{};
      final newSlideAnimations = <int, Animation<double>>{};
      final newBounceControllers = <int, AnimationController>{};
      final newBounceAnimations = <int, Animation<double>>{};

      newControllers[0] = TextEditingController(text: '');
      newFocusNodes[0] = FocusNode();
      newAnimationControllers[0] = AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: this,
      );
      newSlideAnimations[0] = Tween<double>(begin: 0, end: -20).animate(
        CurvedAnimation(parent: newAnimationControllers[0]!, curve: Curves.easeOut),
      );
      newBounceControllers[0] = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      newBounceAnimations[0] = Tween<double>(begin: 1.0, end: 0.9).animate(
        CurvedAnimation(
          parent: newBounceControllers[0]!,
          curve: Curves.easeInOut,
        ),
      );

      for (var i = 0; i < _controllers.length; i++) {
        newControllers[i + 1] = _controllers[i]!;
        newFocusNodes[i + 1] = _focusNodes[i]!;
        newAnimationControllers[i + 1] = _animationControllers[i]!;
        newSlideAnimations[i + 1] = _slideAnimations[i]!;
        newBounceControllers[i + 1] = _bounceControllers[i]!;
        newBounceAnimations[i + 1] = _bounceAnimations[i]!;
      }

      _controllers.clear();
      _focusNodes.clear();
      _animationControllers.clear();
      _slideAnimations.clear();
      _bounceControllers.clear();
      _bounceAnimations.clear();
      _controllers.addAll(newControllers);
      _focusNodes.addAll(newFocusNodes);
      _animationControllers.addAll(newAnimationControllers);
      _slideAnimations.addAll(newSlideAnimations);
      _bounceControllers.addAll(newBounceControllers);
      _bounceAnimations.addAll(newBounceAnimations);

      _editingIndex = 0;
    });
    _saveTodos();

    // Focus on the new text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0]?.requestFocus();
    });
  }

  void _updateTodoText(int index, String text) {
    setState(() {
      _todos[index].text = text;
    });
    _saveTodos();
  }

  void _onTodoSubmitted(int index) {
    if (_todos[index].text.trim().isEmpty) {
      _removeTodo(index);
    }
  }

  void _onTodoUnfocused(int index) {
    if (_todos[index].text.trim().isEmpty) {
      _removeTodo(index);
    }
  }

  void _removeTodo(int index) {
    setState(() {
      _controllers[index]?.dispose();
      _focusNodes[index]?.dispose();
      _animationControllers[index]?.dispose();
      _bounceControllers[index]?.dispose();
      _todos.removeAt(index);

      // Rebuild controller and focus node maps
      final newControllers = <int, TextEditingController>{};
      final newFocusNodes = <int, FocusNode>{};
      final newAnimationControllers = <int, AnimationController>{};
      final newSlideAnimations = <int, Animation<double>>{};
      final newBounceControllers = <int, AnimationController>{};
      final newBounceAnimations = <int, Animation<double>>{};

      for (var i = 0; i < _todos.length; i++) {
        if (i < index) {
          newControllers[i] = _controllers[i]!;
          newFocusNodes[i] = _focusNodes[i]!;
          newAnimationControllers[i] = _animationControllers[i]!;
          newSlideAnimations[i] = _slideAnimations[i]!;
          newBounceControllers[i] = _bounceControllers[i]!;
          newBounceAnimations[i] = _bounceAnimations[i]!;
        } else {
          newControllers[i] = _controllers[i + 1]!;
          newFocusNodes[i] = _focusNodes[i + 1]!;
          newAnimationControllers[i] = _animationControllers[i + 1]!;
          newSlideAnimations[i] = _slideAnimations[i + 1]!;
          newBounceControllers[i] = _bounceControllers[i + 1]!;
          newBounceAnimations[i] = _bounceAnimations[i + 1]!;
        }
      }

      _controllers.clear();
      _focusNodes.clear();
      _animationControllers.clear();
      _slideAnimations.clear();
      _bounceControllers.clear();
      _bounceAnimations.clear();
      _controllers.addAll(newControllers);
      _focusNodes.addAll(newFocusNodes);
      _animationControllers.addAll(newAnimationControllers);
      _slideAnimations.addAll(newSlideAnimations);
      _bounceControllers.addAll(newBounceControllers);
      _bounceAnimations.addAll(newBounceAnimations);
    });
    _saveTodos();
  }

  void _moveToTrash(int index) {
    final todo = _todos[index];
    _trash.add(todo);
    _removeTodo(index);
  }

  void _toggleTodo(int index) async {
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
    await _bounceControllers[index]?.forward(from: 0);
    await _bounceControllers[index]?.reverse();
    _saveTodos();
  }

  void _showTrashSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Trash', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_trash.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Trash is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _trash.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_trash[index].text),
                        trailing: IconButton(
                          icon: const Icon(Icons.restore),
                          onPressed: () {
                            setState(() {
                              _todos.insert(0, _trash[index]);
                              _trash.removeAt(index);
                              _initializeControllers();
                            });
                            _saveTodos();
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    _addTodo();
  }

  void _startEditing(int index) {
    setState(() {
      // Unfocus all other fields
      for (var focusNode in _focusNodes.values) {
        focusNode.unfocus();
      }
      _editingIndex = index;
      _focusNodes[index]?.requestFocus();
    });
  }

  void _stopEditing() {
    setState(() {
      _editingIndex = null;
      for (var focusNode in _focusNodes.values) {
        focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          displacement: 0,
          edgeOffset: 0,
          strokeWidth: 0,
          color: Colors.white.withValues(alpha: 0),
          backgroundColor: Colors.white.withValues(alpha: 0),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _todos.length,
            itemBuilder: (context, index) {
              final todo = _todos[index];
              final isEditing = _editingIndex == index;

              return GestureDetector(
                key: Key('${todo.text}_$index'),
                onHorizontalDragEnd: isEditing ? null : (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                    _animationControllers[index]?.forward().then((_) {
                      _animationControllers[index]?.reverse();
                      _startEditing(index);
                    });
                  }
                },
                onTap: isEditing ? null : () {
                  _toggleTodo(index);
                },
                onDoubleTap: isEditing ? null : () {
                  _moveToTrash(index);
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                    _showTrashSheet();
                  }
                },
                child: AnimatedBuilder(
                  animation: _slideAnimations[index]!,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_slideAnimations[index]!.value, 0),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: AnimatedBuilder(
                          animation: _bounceAnimations[index]!,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _bounceAnimations[index]!.value,
                              alignment: Alignment.centerLeft,
                              child: isEditing
                        ? TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            autofocus: true,
                            maxLines: 1,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter todo',
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                            onChanged: (text) => _updateTodoText(index, text),
                            onSubmitted: (_) {
                              _onTodoSubmitted(index);
                              _stopEditing();
                            },
                            onTapOutside: (_) {
                              _onTodoUnfocused(index);
                              _stopEditing();
                            },
                          )
                        : Text(
                            todo.text.isEmpty ? 'Empty todo' : todo.text,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                              decoration: todo.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: Colors.grey,
                              decorationThickness: 2.0,
                              color: todo.isDone ? Colors.grey : (todo.text.isEmpty ? Colors.grey : Colors.black),
                            ),
                          ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    for (var animController in _animationControllers.values) {
      animController.dispose();
    }
    for (var bounceController in _bounceControllers.values) {
      bounceController.dispose();
    }
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
