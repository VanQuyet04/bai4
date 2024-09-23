class Task {
  String id;
  String title;
  bool isCompleted;
  DateTime deadline;

  Task({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'deadline': deadline.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    return Task(
      id: documentId,
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
      deadline: DateTime.parse(map['deadline'])
    );
  }
}