import 'dart:convert';
import 'package:ejemplo_00/App/model/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskRepository {
  static const _key = 'tasks';

  Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonTasks = prefs.getStringList(_key) ?? [];
    return jsonTasks
        .map((e) => Task.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonTasks =
    tasks.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, jsonTasks);
  }

  Future<void> addTask(Task task) async {
    final tasks = await getTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  Future<void> deleteTask(int index) async {
    final tasks = await getTasks();
    tasks.removeAt(index);
    await saveTasks(tasks);
  }
}
