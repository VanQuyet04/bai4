import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import thư viện intl
import 'task.dart';
import 'main.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final snapshot = await _firestore.collection('tasks').get();
    setState(() {
      tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> createTask(Task task) async {
    await _firestore.collection('tasks').add(task.toMap());
    loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).update(task.toMap());
    loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _firestore.collection('tasks').doc(id).delete();
    loadTasks();
  }

  void checkDeadlines() {
    final now = DateTime.now();
    for (var task in tasks) {
      if (task.deadline.isBefore(now) && task.isCompleted==false) {
        // Gửi thông báo nếu deadline đã đến
        showNotification(task.title);
        task.isCompleted = true; // Hoặc một cách khác để không thông báo lần nữa
        updateTask(task); // Cập nhật task vào Firestore
      }
    }
  }

  void createNewTask() {
    TextEditingController titleController = TextEditingController();
    DateTime? selectedDateTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm công việc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Nhập tiêu đề công việc'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    TimeOfDay? timePicked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (timePicked != null) {
                      selectedDateTime = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        timePicked.hour,
                        timePicked.minute,
                      );
                    }
                  }
                },
                child: const Text('Chọn thời gian'),
              ),
              if (selectedDateTime != null)
                Text('Deadline: ${DateFormat('HH:mm').format(selectedDateTime!)}'), // Chỉ hiển thị giờ và phút
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && selectedDateTime != null) {
                  createTask(Task(
                    id: '',
                    title: titleController.text,
                    isCompleted: false,
                    deadline: selectedDateTime!,
                  ));
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn deadline!')),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void editTask(Task task) {
    TextEditingController titleController = TextEditingController(text: task.title);
    DateTime? selectedDateTime = task.deadline;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa công việc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Nhập tiêu đề công việc'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    TimeOfDay? timePicked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
                    );
                    if (timePicked != null) {
                      selectedDateTime = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        timePicked.hour,
                        timePicked.minute,
                      );
                    }
                  }
                },
                child: const Text('Chọn thời gian'),
              ),
              if (selectedDateTime != null)
                Text('Deadline: ${DateFormat('HH:mm').format(selectedDateTime!)}'), // Chỉ hiển thị giờ và phút
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && selectedDateTime != null) {
                  task.title = titleController.text;
                  task.deadline = selectedDateTime!;
                  updateTask(task);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn deadline!')),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    checkDeadlines(); // Kiểm tra deadline mỗi khi build lại màn hình
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách công việc')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text('Deadline: ${DateFormat('HH:mm').format(task.deadline)}'), // Chỉ hiển thị giờ và phút
            trailing: Checkbox(
              value: task.isCompleted,
              onChanged: (bool? value) {
                task.isCompleted = value ?? false;
                updateTask(task);
              },
            ),
            onTap: () => editTask(task),
            onLongPress: () => deleteTask(task.id),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => createNewTask(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
