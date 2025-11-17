import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
  final Map<int, Animation<double>> _fadeAnimations = {};
  final Map<int, AnimationController> _deleteControllers = {};
  final Map<int, Animation<double>> _deleteAnimations = {};

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
        _fadeAnimations[i] = Tween<double>(begin: 1.0, end: 0.5).animate(
          CurvedAnimation(
            parent: _bounceControllers[i]!,
            curve: Curves.easeInOut,
          ),
        );
        _deleteControllers[i] = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        );
        _deleteAnimations[i] = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _deleteControllers[i]!,
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
    HapticFeedback.mediumImpact();
    setState(() {
      _todos.insert(0, TodoItem(text: '', isDone: false));

      // Shift all existing controllers and focus nodes
      final newControllers = <int, TextEditingController>{};
      final newFocusNodes = <int, FocusNode>{};
      final newAnimationControllers = <int, AnimationController>{};
      final newSlideAnimations = <int, Animation<double>>{};
      final newBounceControllers = <int, AnimationController>{};
      final newBounceAnimations = <int, Animation<double>>{};
      final newDeleteControllers = <int, AnimationController>{};
      final newDeleteAnimations = <int, Animation<double>>{};

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
      final newFadeAnimations = <int, Animation<double>>{};
      newFadeAnimations[0] = Tween<double>(begin: 1.0, end: 0.5).animate(
        CurvedAnimation(
          parent: newBounceControllers[0]!,
          curve: Curves.easeInOut,
        ),
      );
      newDeleteControllers[0] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      newDeleteAnimations[0] = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: newDeleteControllers[0]!,
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
        newFadeAnimations[i + 1] = _fadeAnimations[i]!;
        newDeleteControllers[i + 1] = _deleteControllers[i]!;
        newDeleteAnimations[i + 1] = _deleteAnimations[i]!;
      }

      _controllers.clear();
      _focusNodes.clear();
      _animationControllers.clear();
      _slideAnimations.clear();
      _bounceControllers.clear();
      _bounceAnimations.clear();
      _fadeAnimations.clear();
      _deleteControllers.clear();
      _deleteAnimations.clear();
      _controllers.addAll(newControllers);
      _focusNodes.addAll(newFocusNodes);
      _animationControllers.addAll(newAnimationControllers);
      _slideAnimations.addAll(newSlideAnimations);
      _bounceControllers.addAll(newBounceControllers);
      _bounceAnimations.addAll(newBounceAnimations);
      _fadeAnimations.addAll(newFadeAnimations);
      _deleteControllers.addAll(newDeleteControllers);
      _deleteAnimations.addAll(newDeleteAnimations);

      _editingIndex = 0;
    });

    // Focus on the new text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0]?.requestFocus();
    });
  }

  void _updateTodoText(int index, String text) {
    _todos[index].text = text;
    if (text.isNotEmpty) {
      _saveTodos();
    }
  }

  void _onTodoSubmitted(int index) async {
    if (_todos[index].text.trim().isEmpty) {
      await _deleteControllers[index]?.forward();
      _removeTodo(index);
    }
  }

  void _onTodoUnfocused(int index) async {
    if (_todos[index].text.trim().isEmpty) {
      await _deleteControllers[index]?.forward();
      _removeTodo(index);
    }
  }

  void _removeTodo(int index) {
    setState(() {
      _controllers[index]?.dispose();
      _focusNodes[index]?.dispose();
      _animationControllers[index]?.dispose();
      _bounceControllers[index]?.dispose();
      _deleteControllers[index]?.dispose();
      _todos.removeAt(index);

      // Rebuild controller and focus node maps
      final newControllers = <int, TextEditingController>{};
      final newFocusNodes = <int, FocusNode>{};
      final newAnimationControllers = <int, AnimationController>{};
      final newSlideAnimations = <int, Animation<double>>{};
      final newBounceControllers = <int, AnimationController>{};
      final newBounceAnimations = <int, Animation<double>>{};
      final newFadeAnimations = <int, Animation<double>>{};
      final newDeleteControllers = <int, AnimationController>{};
      final newDeleteAnimations = <int, Animation<double>>{};

      for (var i = 0; i < _todos.length; i++) {
        if (i < index) {
          newControllers[i] = _controllers[i]!;
          newFocusNodes[i] = _focusNodes[i]!;
          newAnimationControllers[i] = _animationControllers[i]!;
          newSlideAnimations[i] = _slideAnimations[i]!;
          newBounceControllers[i] = _bounceControllers[i]!;
          newBounceAnimations[i] = _bounceAnimations[i]!;
          newFadeAnimations[i] = _fadeAnimations[i]!;
          newDeleteControllers[i] = _deleteControllers[i]!;
          newDeleteAnimations[i] = _deleteAnimations[i]!;
        } else {
          newControllers[i] = _controllers[i + 1]!;
          newFocusNodes[i] = _focusNodes[i + 1]!;
          newAnimationControllers[i] = _animationControllers[i + 1]!;
          newSlideAnimations[i] = _slideAnimations[i + 1]!;
          newBounceControllers[i] = _bounceControllers[i + 1]!;
          newBounceAnimations[i] = _bounceAnimations[i + 1]!;
          newFadeAnimations[i] = _fadeAnimations[i + 1]!;
          newDeleteControllers[i] = _deleteControllers[i + 1]!;
          newDeleteAnimations[i] = _deleteAnimations[i + 1]!;
        }
      }

      _controllers.clear();
      _focusNodes.clear();
      _animationControllers.clear();
      _slideAnimations.clear();
      _bounceControllers.clear();
      _bounceAnimations.clear();
      _fadeAnimations.clear();
      _deleteControllers.clear();
      _deleteAnimations.clear();
      _controllers.addAll(newControllers);
      _focusNodes.addAll(newFocusNodes);
      _animationControllers.addAll(newAnimationControllers);
      _slideAnimations.addAll(newSlideAnimations);
      _bounceControllers.addAll(newBounceControllers);
      _bounceAnimations.addAll(newBounceAnimations);
      _fadeAnimations.addAll(newFadeAnimations);
      _deleteControllers.addAll(newDeleteControllers);
      _deleteAnimations.addAll(newDeleteAnimations);
    });
    _saveTodos();
  }

  void _moveToTrash(int index) async {
    final todo = _todos[index];
    _trash.add(todo);

    // Animate shrink to zero
    await _deleteControllers[index]?.forward();

    _removeTodo(index);
  }

  void _handleTap(int index) {
    _toggleTodo(index);
  }

  void _toggleTodo(int index) async {
    HapticFeedback.lightImpact();
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
    await _bounceControllers[index]?.forward(from: 0);
    await _bounceControllers[index]?.reverse();
    _saveTodos();
  }

  void _handleDoubleTap(int index) async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.mediumImpact();
    // Immediately stop and reset all animations
    _bounceControllers[index]?.stop();
    _bounceControllers[index]?.value = 1.0;

    // Revert the isDone state if it was just toggled
    if (_todos[index].isDone != _todos[index].isDone) {
      setState(() {
        _todos[index].isDone = !_todos[index].isDone;
      });
    }

    _moveToTrash(index);
  }

  void _showTrashSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return TrashBottomSheet(
          trashItems: _trash,
          onRestore: (int index) {
            HapticFeedback.mediumImpact();
            setState(() {
              _todos.insert(0, _trash[index]);
              _trash.removeAt(index);
              _initializeControllers();
            });
            _saveTodos();
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    // Only allow refresh when scrolled to the top
    if (_scrollController.hasClients && _scrollController.offset <= 0) {
      HapticFeedback.mediumImpact();
      _addTodo();
    }
  }

  void _startEditing(int index) {
    HapticFeedback.selectionClick();
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
    return CupertinoScaffold(
      body: Builder(
        builder: (scaffoldContext) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: GestureDetector(
                onTap: () {
                  if (_editingIndex != null) {
                    _onTodoUnfocused(_editingIndex!);
                    _stopEditing();
                  }
                },
                child: Stack(
                  children: [
                    RefreshIndicator(
              onRefresh: _onRefresh,
              displacement: 0,
              edgeOffset: 0,
              strokeWidth: 0,
              elevation: 0,
              color: Colors.white.withValues(alpha: 0),
              backgroundColor: Colors.white.withValues(alpha: 0),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 20),
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
                  _handleTap(index);
                },
                onDoubleTap: isEditing ? null : () {
                  _handleDoubleTap(index);
                },
                child: AnimatedBuilder(
                  animation: _slideAnimations[index]!,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_slideAnimations[index]!.value, 0),
                      child: AnimatedBuilder(
                        animation: _deleteAnimations[index]!,
                        builder: (context, child) {
                          return ClipRect(
                            child: Align(
                              alignment: Alignment.topLeft,
                              heightFactor: _deleteAnimations[index]!.value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 4.0,
                                ),
                                child: AnimatedBuilder(
                          animation: Listenable.merge([_bounceAnimations[index]!, _deleteAnimations[index]!]),
                          builder: (context, child) {
                            return Opacity(
                              opacity: todo.isDone ? _fadeAnimations[index]!.value : 1.0,
                              child: Transform.scale(
                                scale: _bounceAnimations[index]!.value * _deleteAnimations[index]!.value,
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
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              letterSpacing: 0,
                              textBaseline: TextBaseline.alphabetic,
                            ),
                            strutStyle: const StrutStyle(
                              fontSize: 26,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              forceStrutHeight: true,
                            ),
                            onChanged: (text) => _updateTodoText(index, text),
                            onSubmitted: (_) {
                              HapticFeedback.mediumImpact();
                              _onTodoSubmitted(index);
                              _stopEditing();
                            },
                            onEditingComplete: () {
                              // Do nothing - let onSubmitted handle it
                            },
                          )
                        : Text(
                            todo.text.isEmpty ? 'Empty todo' : todo.text,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              letterSpacing: 0,
                              textBaseline: TextBaseline.alphabetic,
                              decoration: todo.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: Colors.grey,
                              decorationThickness: 2.0,
                              color: todo.isDone ? Colors.grey : (todo.text.isEmpty ? Colors.grey : Colors.black),
                            ),
                            strutStyle: const StrutStyle(
                              fontSize: 26,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              forceStrutHeight: true,
                            ),
                          ),
                              ),
                            );
                          },
                        ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
            // Bottom right corner swipe up gesture detector for trash
            Positioned(
              bottom: 0,
              right: 0,
              width: MediaQuery.of(context).size.width / 3,
              height: MediaQuery.of(context).size.height / 4,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  // Detect upward swipe (negative delta)
                  if (details.delta.dy < -10) {
                    _showTrashSheet(scaffoldContext);
                  }
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
              ),
            ),
          );
        },
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
    for (var deleteController in _deleteControllers.values) {
      deleteController.dispose();
    }
    super.dispose();
  }
}

class TrashBottomSheet extends StatelessWidget {
  final List<TodoItem> trashItems;
  final Function(int) onRestore;

  const TrashBottomSheet({
    Key? key,
    required this.trashItems,
    required this.onRestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    const Text(
                      'Trash',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              if (trashItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Text(
                    'Trash is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: trashItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(
                              trashItems[index].text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () => onRestore(index),
                              tooltip: 'Restore',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
