import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class Task {
  String title;
  String description;
  bool completed;

  Task({
    required this.title,
    this.description = 'welcome to the todo list',
    this.completed = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'],
      completed: json['completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'completed': completed,
    };
  }

  static List<Map<String, dynamic>> tasksToJson(List<Task> tasks) {
    return tasks.map((task) => task.toJson()).toList();
  }
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.blue,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.greenAccent), // Change the color of elevated buttons
          ),
        ),
      ),
      home: StartPage(),
    );
  }
}

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List App'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaskListPage()),
            );
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.orange),
          ),
          child: Text('Start'),
        ),
      )
    );
  }
}
class TaskListPage extends StatefulWidget {
  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  late TextEditingController _taskTitleController;
  late TextEditingController _taskDescriptionController;

  @override
  void initState() {
    super.initState();
    _taskTitleController = TextEditingController();
    _taskDescriptionController = TextEditingController();
    loadTasks();
  }

  Future<void> loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      setState(() {
        tasks = (tasksJson as List)
            .map((taskMap) => Task.fromJson(taskMap))
            .toList();
        filteredTasks = List.from(tasks);
      });
    }
  }

  Future<void> saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tasksJson = Task.tasksToJson(tasks).toString();
    prefs.setString('tasks', tasksJson);
  }

  void addTask() {
    String title = _taskTitleController.text.trim();
    String description = _taskDescriptionController.text.trim();

    if (title.isEmpty) {
      return;
    }

    Task task = Task(title: title, description: description);
    setState(() {
      tasks.add(task);
      filteredTasks = List.from(tasks);
    });
    saveTasks();
    clearInputFields();
  }

  void editTask(int index) {
    Task task = tasks[index];
    _taskTitleController.text = task.title;
    _taskDescriptionController.text = task.description;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            children: [
              TextField(
                controller: _taskTitleController,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: _taskDescriptionController,
                decoration: InputDecoration(labelText: 'Task Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                clearInputFields();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                tasks[index].title = _taskTitleController.text.trim();
                tasks[index].description = _taskDescriptionController.text.trim();
                saveTasks();
                Navigator.pop(context);
                clearInputFields();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void toggleTaskCompletion(int index) {
    setState(() {
      tasks[index].completed = !tasks[index].completed;
    });
    saveTasks();
  }

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
      filteredTasks = List.from(tasks);
    });
    saveTasks();
  }

  void clearInputFields() {
    _taskTitleController.clear();
    _taskDescriptionController.clear();
  }

  void filterTasks(String query) {
    setState(() {
      filteredTasks = tasks.where((task) {
        final titleLower = task.title.toLowerCase();
        final queryLower = query.toLowerCase();
        return titleLower.contains(queryLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(tasks),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _taskTitleController,
              onChanged: (value) {
                filterTasks(value);
              },
              decoration: InputDecoration(
                labelText: 'Task Title',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _taskDescriptionController,
              decoration: InputDecoration(
                labelText: 'Task Description',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: addTask,
            child: Text('Add Task'),
          ),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
              child: Text(
                'No tasks yet.',
                style: TextStyle(fontSize: 18),
              ),
            )
                : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                Task task = filteredTasks[index];
                return ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  subtitle: task.description.isNotEmpty
                      ? Text(task.description)
                      : null,
                  leading: Checkbox(
                    value: task.completed,
                    onChanged: (_) => toggleTaskCompletion(index),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => editTask(index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteTask(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TaskSearchDelegate extends SearchDelegate<Task> {
  final List<Task> tasks;

  TaskSearchDelegate(this.tasks);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, Task(title: '', description: '', completed: false));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = tasks.where((task) {
      final titleLower = task.title.toLowerCase();
      final queryLower = query.toLowerCase();
      return titleLower.contains(queryLower);
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        Task task = suggestions[index];
        return ListTile(
          title: Text(task.title),
          subtitle: task.description.isNotEmpty ? Text(task.description) : null,
          onTap: () {
            close(context, task);
          },
        );
      },
    );
  }
}
