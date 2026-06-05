enum SourceType { local, ssh, github }

class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final String? language;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.language,
  });

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

abstract class CodeSource {
  SourceType get type;
  String get label;
  bool get isConnected;

  Future<List<FileNode>> listFiles(String path);
  Future<String> readFile(String path);
  Future<void> writeFile(String path, String content);
  Future<void> deleteFile(String path);
  Future<void> createDirectory(String path);
  Future<bool> exists(String path);
}
