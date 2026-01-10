import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  // parentType: 0 for Project, 1 for Task
  late int parentType;

  late int parentId;

  late String content; // Markdown format

  late DateTime createdAt;

  late DateTime updatedAt;

  // Document capture attachments
  List<String>? attachmentPaths; // File paths to captured images

  // OCR extracted text (separate from manual content)
  String? extractedText;
}
