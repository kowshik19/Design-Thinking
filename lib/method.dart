import 'dart:io';

void main() {
  String path = "D:/Flutter_project/dt/videos"; // Change to your folder path
  List<String> folders = getFolders();

  if (folders.isNotEmpty) {
    print("Folders inside '$path':");
    for (var folder in folders) {
      print(folder);
    }
  } else {
    print("No folders found in '$path'");
  }
}

List<String> getFolders() {
  Directory dir = Directory("videos");
  if (dir.existsSync()) {
    return dir
        .listSync()
        .where((entity) => entity is Directory)
        .map((e) => e.path.split(Platform.pathSeparator).last)
        .toList();
  }
  return [];
}
