class Task {
  final String title;
  bool done;

  Task(this.title, {this.done = false});

  Task.fromJson(Map<String, dynamic> json)
      : title = json['title'] ?? '',
        done = json['done'] ?? false;

  Map<String, dynamic> toJson() {
    return {"title": title, "done": done};
  }
}
