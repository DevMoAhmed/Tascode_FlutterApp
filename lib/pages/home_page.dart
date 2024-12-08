import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tascode/models/task.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  HomePage();

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late double _deviceHeight, _deviceWidth;
  late final AnimationController _animationController;
  bool _showAnimation = false;

  String? _newTaskContent;

  Box? _box;
  _HomePageState();

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        toolbarHeight: _deviceHeight * 0.15,
        title: const Text(
          "TasCode",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 40,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: SweepGradient(
              colors: [
                Colors.blue,
                Color.fromARGB(255, 158, 211, 255),
                Colors.cyan,
                Colors.purple
              ],
              center: Alignment.topCenter,
              startAngle: 0.10, // Starting angle (0 radians)
              endAngle: 3.14, // End angle (π radians)
            ),
          ),
        ),
      ),
      body: _buildUI(),
      floatingActionButton: _addTaskButton(),
    );
  }

  Widget _buildUI() {
    return Stack(
      children: [
        _tasksView(),
        if (_showAnimation)
          Center(
            child: Lottie.asset(
              "assets/done.json",
              controller: _animationController,
              repeat: false,
              width: _deviceHeight,
              height: _deviceWidth,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }

  Widget _tasksView() {
    return FutureBuilder(
      future: Hive.openBox('tasks'),
      builder: (BuildContext _context, AsyncSnapshot _snapshot) {
        if (_snapshot.hasData) {
          _box = _snapshot.data;
          return _tasksList();
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _tasksList() {
    List tasks = _box!.values.toList();
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (BuildContext _context, int _index) {
        var task = Task.fromMap(tasks[_index]);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.white,
          ),
          child: ListTile(
            title: Text(
              task.content,
              style: TextStyle(
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              task.timestamp.toString(),
            ),
            trailing: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                task.done
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank_outlined,
                key: ValueKey<bool>(task.done),
                color: Colors.blue,
              ),
            ),
            onTap: () {
              setState(() {
                _showAnimation = true; // Show the animation widget
              });

              var ticker = _animationController.forward();
              ticker.whenComplete(() {
                _animationController.reset();
                setState(() {
                  _showAnimation =
                      false; // Hide the animation widget after animation ends
                });
              });

              task.done = !task.done;
              _box!.putAt(
                _index,
                task.toMap(),
              );
              setState(() {});
            },
            onLongPress: () {
              _box!.deleteAt(_index);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _addTaskButton() {
    return FloatingActionButton(
      onPressed: _displayTaskPopup,
      child: const Icon(
        Icons.add,
      ),
    );
  }

  void _displayTaskPopup() {
    showDialog(
      context: context,
      builder: (BuildContext _context) {
        return AlertDialog(
          title: const Text("Add New Task!"),
          content: TextField(
            onSubmitted: (_) {
              if (_newTaskContent != null) {
                var _task = Task(
                    content: _newTaskContent!,
                    timestamp: DateTime.now(),
                    done: false);
                _box!.add(_task.toMap());
                setState(() {
                  _newTaskContent = null;
                  Navigator.pop(context);
                });
              }
            },
            onChanged: (_value) {
              setState(() {
                _newTaskContent = _value;
              });
            },
          ),
        );
      },
    );
  }
}
