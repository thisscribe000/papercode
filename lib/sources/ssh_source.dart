import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'code_source.dart';

class SSHSource extends CodeSource {
  SSHClient? _client;
  final String _host;

  SSHSource(this._client, {String host = ''}) : _host = host;

  void setClient(SSHClient client) {
    _client = client;
  }

  @override
  SourceType get type => SourceType.ssh;

  @override
  String get label => _host;

  @override
  bool get isConnected => _client != null;

  @override
  Future<List<FileNode>> listFiles(String path) async {
    if (_client == null) throw Exception('SSH not connected');

    final result = await _client!.run('ls -la "$path"');
    final output = utf8.decode(result);
    return _parseLsOutput(output, path);
  }

  @override
  Future<String> readFile(String path) async {
    if (_client == null) throw Exception('SSH not connected');
    final result = await _client!.run('cat "$path"', runInPty: false);
    return utf8.decode(result);
  }

  @override
  Future<void> writeFile(String path, String content) async {
    if (_client == null) throw Exception('SSH not connected');
    await _client!.run(
      "cat > '$path' << 'ENDOFFILE'\n$content\nENDOFFILE",
      runInPty: false,
    );
  }

  @override
  Future<void> deleteFile(String path) async {
    if (_client == null) throw Exception('SSH not connected');
    await _client!.run('rm -rf "$path"', runInPty: false);
  }

  @override
  Future<void> createDirectory(String path) async {
    if (_client == null) throw Exception('SSH not connected');
    await _client!.run('mkdir -p "$path"', runInPty: false);
  }

  @override
  Future<bool> exists(String path) async {
    if (_client == null) return false;
    final result = await _client!.run('test -e "$path" && echo "yes" || echo "no"', runInPty: false);
    return utf8.decode(result).trim() == 'yes';
  }

  List<FileNode> _parseLsOutput(String output, String basePath) {
    final entries = <FileNode>[];
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.isEmpty || line.startsWith('total ')) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 8) continue;

      final permissions = parts[0];
      if (permissions.length < 10) continue;

      final isDir = permissions[0] == 'd';
      final isLink = permissions[0] == 'l';
      final size = int.tryParse(parts[4]);
      final name = parts.sublist(8).join(' ');

      if (name == '.' || name == '..') continue;

      entries.add(FileNode(
        name: name,
        path: '$basePath/$name',
        isDirectory: isDir || isLink,
        size: isDir ? null : size,
      ));
    }

    entries.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }
}
