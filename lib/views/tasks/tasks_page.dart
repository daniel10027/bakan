import 'package:flutter/material.dart';
import 'package:bakan/database/db_helper.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> tasks = [];
  final taskController = TextEditingController();
  DateTime? dueDate;
  TimeOfDay? dueTime;
  String priority = 'Moyenne';

  late TabController _tabController;

  Future<void> loadTasks() async {
    tasks = await DBHelper.getTasks();
    setState(() {});
  }

  Future<void> addTask() async {
    if (taskController.text.isEmpty) return;
    final fullDateTime = DateTime(
      dueDate?.year ?? DateTime.now().year,
      dueDate?.month ?? DateTime.now().month,
      dueDate?.day ?? DateTime.now().day,
      dueTime?.hour ?? 0,
      dueTime?.minute ?? 0,
    );
    await DBHelper.insertTask({
      'title': taskController.text,
      'isDone': 0,
      'priority': priority,
      'dueDate': fullDateTime.toIso8601String(),
    });
    taskController.clear();
    dueDate = null;
    dueTime = null;
    priority = 'Moyenne';
    loadTasks();
  }

  Future<void> toggleTask(int id, int isDone) async {
    await DBHelper.updateTaskStatus(id, isDone == 1 ? 0 : 1);
    loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await DBHelper.deleteTask(id);
    loadTasks();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadTasks();
  }

  List<Map<String, dynamic>> getFilteredTasks(String filter) {
    final now = DateTime.now();
    return tasks.where((task) {
      final due =
          task['dueDate'] != null ? DateTime.parse(task['dueDate']) : null;
      if (filter == 'Terminé') return task['isDone'] == 1;
      if (filter == 'Échu')
        return due != null && due.isBefore(now) && task['isDone'] == 0;
      if (filter == 'À faire')
        return task['isDone'] == 0 && (due == null || due.isAfter(now));
      return true;
    }).toList();
  }

  Color getPriorityColor(String p) {
    switch (p) {
      case 'Haute':
        return Colors.red;
      case 'Moyenne':
        return Colors.orange;
      case 'Basse':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tâches'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Terminé'),
            Tab(text: 'Échu'),
            Tab(text: 'À faire'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: taskController,
                  decoration:
                      const InputDecoration(labelText: 'Nouvelle tâche'),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Priorité :'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: priority,
                        items: const [
                          DropdownMenuItem(
                              value: 'Basse', child: Text('Basse')),
                          DropdownMenuItem(
                              value: 'Moyenne', child: Text('Moyenne')),
                          DropdownMenuItem(
                              value: 'Haute', child: Text('Haute')),
                        ],
                        onChanged: (val) => setState(() => priority = val!),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          dueDate == null
                              ? 'Date'
                              : DateFormat('dd/MM/yyyy').format(dueDate!),
                        ),
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 5)),
                          );
                          if (selected != null) {
                            setState(() => dueDate = selected);
                          }
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          dueTime == null
                              ? 'Heure'
                              : '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}',
                        ),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => dueTime = time);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ['Toutes', 'Terminé', 'Échu', 'À faire'].map((filter) {
                final displayTasks = getFilteredTasks(filter);
                return ListView.builder(
                  itemCount: displayTasks.length,
                  itemBuilder: (context, index) {
                    final task = displayTasks[index];
                    final due = task['dueDate'] != null
                        ? DateFormat('dd/MM/yyyy HH:mm')
                            .format(DateTime.parse(task['dueDate']))
                        : 'Pas de date';
                    return ListTile(
                      tileColor:
                          getPriorityColor(task['priority']).withOpacity(0.1),
                      leading: Checkbox(
                        value: task['isDone'] == 1,
                        onChanged: (_) =>
                            toggleTask(task['id'], task['isDone']),
                      ),
                      title: Text(
                        task['title'],
                        style: TextStyle(
                          decoration: task['isDone'] == 1
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(
                          "Priorité : ${task['priority']} • Échéance : $due"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteTask(task['id']),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
