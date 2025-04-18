class Module {
  final String title;
  final String lessons;
  final String duration;
  final String image;

  Module({
    required this.title,
    required this.lessons,
    required this.duration,
    required this.image,
  });

  factory Module.fromMap(Map<String, dynamic> map) {
    return Module(
      title: map['title'] ?? '',
      lessons: map['lessons'] ?? '',
      duration: map['duration'] ?? '',
      image: map['image'] ?? '',
    );
  }
}
