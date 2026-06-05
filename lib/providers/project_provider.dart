import 'package:flutter/material.dart';
import '../sources/code_source.dart';
import '../sources/local_source.dart';
import '../sources/ssh_source.dart';
import '../sources/github_source.dart';

class OpenTab {
  final String path;
  final String name;
  String content;
  String savedContent;
  bool isDirty;

  OpenTab({
    required this.path,
    required this.name,
    this.content = '',
    this.savedContent = '',
    this.isDirty = false,
  });

  bool get hasUnsavedChanges => content != savedContent;
}

class ProjectProvider extends ChangeNotifier {
  CodeSource? _source;
  final LocalSource _localSource = LocalSource();
  SSHSource? _sshSource;
  final GitHubSource _gitHubSource = GitHubSource();

  final List<OpenTab> _openTabs = [];
  int _activeTabIndex = -1;
  String _currentDirectory = '';
  List<FileNode> _currentFiles = [];
  bool _loadingFiles = false;
  String? _error;
  bool _initialized = false;

  CodeSource? get source => _source;
  LocalSource get localSource => _localSource;
  SSHSource? get sshSource => _sshSource;
  GitHubSource get gitHubSource => _gitHubSource;
  SourceType? get sourceType => _source?.type;

  List<OpenTab> get openTabs => List.unmodifiable(_openTabs);
  int get activeTabIndex => _activeTabIndex;
  OpenTab? get activeTab =>
      _activeTabIndex >= 0 && _activeTabIndex < _openTabs.length
          ? _openTabs[_activeTabIndex]
          : null;

  String get currentDirectory => _currentDirectory;
  List<FileNode> get currentFiles => _currentFiles;
  bool get loadingFiles => _loadingFiles;
  String? get error => _error;
  bool get initialized => _initialized;

  Future<void> init() async {
    await _localSource.setRootToAppDocuments();
    _source = _localSource;
    _currentDirectory = _localSource.rootPath;
    _initialized = true;
    await refreshFiles();
    notifyListeners();
  }

  void setSource(CodeSource source) {
    _source = source;
    _openTabs.clear();
    _activeTabIndex = -1;
    _currentDirectory = '';
    notifyListeners();
  }

  void setLocalSource() {
    _source = _localSource;
    _currentDirectory = _localSource.rootPath;
    _openTabs.clear();
    _activeTabIndex = -1;
    refreshFiles();
    notifyListeners();
  }

  void setSSHSource(SSHSource source) {
    _sshSource = source;
    _source = _sshSource;
    _currentDirectory = '/root';
    _openTabs.clear();
    _activeTabIndex = -1;
    refreshFiles();
    notifyListeners();
  }

  void setGitHubSource({required String owner, required String repo, String branch = 'main', String? token}) {
    _gitHubSource.configure(owner: owner, repo: repo, branch: branch, token: token);
    _source = _gitHubSource;
    _currentDirectory = '';
    _openTabs.clear();
    _activeTabIndex = -1;
    refreshFiles();
    notifyListeners();
  }

  String get sourceLabel {
    if (_source == null) return 'No source';
    switch (_source!.type) {
      case SourceType.local:
        return 'Local';
      case SourceType.ssh:
        return (_source as SSHSource).label;
      case SourceType.github:
        return (_source as GitHubSource).label;
    }
  }

  Future<void> navigateToDirectory(String path) async {
    _currentDirectory = path;
    await refreshFiles();
    notifyListeners();
  }

  Future<void> refreshFiles() async {
    if (_source == null) return;
    _loadingFiles = true;
    _error = null;
    notifyListeners();

    try {
      _currentFiles = await _source!.listFiles(_currentDirectory);
    } catch (e) {
      _error = e.toString();
      _currentFiles = [];
    }

    _loadingFiles = false;
    notifyListeners();
  }

  Future<void> goUp() async {
    if (_currentDirectory.isEmpty || _currentDirectory == '/') return;
    final parent = _currentDirectory.substring(0, _currentDirectory.lastIndexOf('/'));
    await navigateToDirectory(parent.isEmpty ? '/' : parent);
  }

  Future<void> openFile(String path) async {
    final existingIndex = _openTabs.indexWhere((t) => t.path == path);
    if (existingIndex >= 0) {
      _activeTabIndex = existingIndex;
      notifyListeners();
      return;
    }

    if (_source == null) return;

    try {
      final content = await _source!.readFile(path);
      final name = path.split('/').last;
      _openTabs.add(OpenTab(
        path: path,
        name: name,
        content: content,
        savedContent: content,
      ));
      _activeTabIndex = _openTabs.length - 1;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setActiveTab(int index) {
    if (index >= 0 && index < _openTabs.length) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  void updateTabContent(int index, String content) {
    if (index >= 0 && index < _openTabs.length) {
      _openTabs[index].content = content;
      notifyListeners();
    }
  }

  Future<void> saveTab(int index) async {
    if (index < 0 || index >= _openTabs.length) return;
    final tab = _openTabs[index];
    if (_source == null) return;

    try {
      await _source!.writeFile(tab.path, tab.content);
      tab.savedContent = tab.content;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveCurrentTab() async {
    if (activeTab == null) return;
    await saveTab(_activeTabIndex);
  }

  void closeTab(int index) {
    if (index < 0 || index >= _openTabs.length) return;
    _openTabs.removeAt(index);
    if (_activeTabIndex >= _openTabs.length) {
      _activeTabIndex = _openTabs.length - 1;
    }
    notifyListeners();
  }

  void closeAllTabs() {
    _openTabs.clear();
    _activeTabIndex = -1;
    notifyListeners();
  }


}
