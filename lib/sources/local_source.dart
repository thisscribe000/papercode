import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'code_source.dart';

class LocalSource extends CodeSource {
  String? _rootPath;

  @override
  SourceType get type => SourceType.local;

  @override
  String get label => 'Local';

  @override
  bool get isConnected => true;

  String get rootPath => _rootPath ?? '/';

  Future<void> setRoot(String path) async {
    _rootPath = path;
  }

  Future<void> setRootToAppDocuments() async {
    final dir = await getApplicationDocumentsDirectory();
    _rootPath = dir.path;
  }

  @override
  Future<List<FileNode>> listFiles(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final entities = await dir.list().toList();
    final nodes = <FileNode>[];

    for (final entity in entities) {
      final stat = await entity.stat();
      String? lang;
      if (entity is File) {
        lang = _languageFromExtension(entity.path);
      }
      nodes.add(FileNode(
        name: entity.uri.pathSegments.last,
        path: entity.path,
        isDirectory: entity is Directory,
        size: stat.size,
        language: lang,
      ));
    }

    nodes.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    nodes.sort((a, b) {
      if (a.name.startsWith('.') && !b.name.startsWith('.')) return 1;
      if (!a.name.startsWith('.') && b.name.startsWith('.')) return -1;
      return 0;
    });

    return nodes;
  }

  @override
  Future<String> readFile(String path) async {
    final file = File(path);
    return await file.readAsString();
  }

  @override
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  @override
  Future<void> deleteFile(String path) async {
    final entity = Directory(path);
    if (await entity.exists()) {
      await entity.delete(recursive: true);
    } else {
      await File(path).delete();
    }
  }

  @override
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  @override
  Future<bool> exists(String path) async {
    return await FileSystemEntity.type(path) != FileSystemEntityType.notFound;
  }

  String? _languageFromExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return 'dart';
      case 'py':
        return 'python';
      case 'js':
      case 'jsx':
        return 'javascript';
      case 'ts':
      case 'tsx':
        return 'typescript';
      case 'java':
        return 'java';
      case 'kt':
        return 'kotlin';
      case 'swift':
        return 'swift';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'rb':
        return 'ruby';
      case 'php':
        return 'php';
      case 'c':
      case 'cpp':
      case 'h':
      case 'hpp':
        return 'cpp';
      case 'cs':
        return 'csharp';
      case 'html':
        return 'html';
      case 'css':
        return 'css';
      case 'json':
        return 'json';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'md':
        return 'markdown';
      case 'xml':
        return 'xml';
      case 'sh':
      case 'bash':
        return 'bash';
      case 'sql':
        return 'sql';
      case 'toml':
        return 'toml';
      default:
        return null;
    }
  }
}
