import 'dart:convert';
import 'package:http/http.dart' as http;
import 'code_source.dart';

class GitHubSource extends CodeSource {
  String? _token;
  String _owner = '';
  String _repo = '';
  String _branch = 'main';

  @override
  SourceType get type => SourceType.github;

  @override
  String get label => '$_owner/$_repo';

  @override
  bool get isConnected => _owner.isNotEmpty && _repo.isNotEmpty;

  String get owner => _owner;
  String get repo => _repo;
  String get branch => _branch;

  void configure({
    required String owner,
    required String repo,
    String branch = 'main',
    String? token,
  }) {
    _owner = owner;
    _repo = repo;
    _branch = branch;
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'PaperCode',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  @override
  Future<List<FileNode>> listFiles(String path) async {
    final apiPath = path.isEmpty ? '' : '/$path';
    final url = 'https://api.github.com/repos/$_owner/$_repo/contents$apiPath?ref=$_branch';

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('GitHub API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final nodes = <FileNode>[];

    if (data is List) {
      for (final item in data) {
        nodes.add(FileNode(
          name: item['name'] ?? '',
          path: item['path'] ?? '',
          isDirectory: item['type'] == 'dir',
          size: item['size'],
        ));
      }
    }

    nodes.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return nodes;
  }

  @override
  Future<String> readFile(String path) async {
    final url = 'https://api.github.com/repos/$_owner/$_repo/contents/$path?ref=$_branch';

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('GitHub API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['content'] == null) {
      throw Exception('Not a file');
    }

    final base64Content = data['content'] as String;
    final cleaned = base64Content.replaceAll(RegExp(r'\s'), '');
    return utf8.decode(base64Decode(cleaned));
  }

  @override
  Future<void> writeFile(String path, String content) async {
    if (_token == null || _token!.isEmpty) {
      throw Exception('Authentication token required to write to GitHub');
    }

    final url = 'https://api.github.com/repos/$_owner/$_repo/contents/$path';
    final encoded = base64Encode(utf8.encode(content));

    String? sha;
    try {
      sha = await _getFileSha(path);
    } catch (_) {
      // File doesn't exist yet — creating new
    }

    final body = {
      'message': 'Update $path via PaperCode',
      'content': encoded,
      'branch': _branch,
    };
    if (sha != null) {
      body['sha'] = sha;
    }

    final response = await http.put(
      Uri.parse(url),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('GitHub write error: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    if (_token == null || _token!.isEmpty) {
      throw Exception('Authentication token required to delete from GitHub');
    }

    final sha = await _getFileSha(path);
    final url = 'https://api.github.com/repos/$_owner/$_repo/contents/$path';

    final body = {
      'message': 'Delete $path via PaperCode',
      'sha': sha,
      'branch': _branch,
    };

    final response = await http.delete(
      Uri.parse(url),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('GitHub delete error: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<void> createDirectory(String path) async {
    // GitHub doesn't have empty directories in its content model.
    // Directories are implicitly created when a file is added at a path.
  }

  Future<String> _getFileSha(String path) async {
    final url = 'https://api.github.com/repos/$_owner/$_repo/contents/$path?ref=$_branch';
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('File not found: $path');
    }
    final data = jsonDecode(response.body);
    return data['sha'] as String;
  }

  @override
  Future<bool> exists(String path) async {
    try {
      await listFiles(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
