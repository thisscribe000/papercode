import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

enum PermissionLevel { readOnly, askMe, fullAccess }

enum ConnState { disconnected, connecting, connected, error }

class ConnectionProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ConnState _state = ConnState.disconnected;
  String? _errorMessage;
  String _host = '';
  String _username = '';
  String _password = '';
  String _apiKey = '';
  SSHClient? _client;
  SSHSession? _terminalSession;
  Terminal? _terminal;
  String? _activeFilePath;
  String? _activeFileContents;
  PermissionLevel _permissionLevel = PermissionLevel.askMe;
  bool _terminalActive = false;

  ConnState get state => _state;
  bool get isConnected => _state == ConnState.connected;
  bool get isConnecting => _state == ConnState.connecting;
  String? get errorMessage => _errorMessage;
  String get host => _host;
  String get username => _username;
  String get password => _password;
  String get apiKey => _apiKey;
  SSHClient? get client => _client;
  SSHSession? get terminalSession => _terminalSession;
  Terminal? get terminal => _terminal;
  bool get terminalActive => _terminalActive;
  String? get activeFilePath => _activeFilePath;
  String? get activeFileContents => _activeFileContents;
  PermissionLevel get permissionLevel => _permissionLevel;

  bool get hasSavedCredentials => _host.isNotEmpty && _username.isNotEmpty;

  ConnectionProvider() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    _host = await _storage.read(key: 'ssh_host') ?? '';
    _username = await _storage.read(key: 'ssh_username') ?? '';
    _password = await _storage.read(key: 'ssh_password') ?? '';
    _apiKey = await _storage.read(key: 'deepseek_api_key') ?? '';
    final perm = await _storage.read(key: 'permission_level');
    if (perm != null) {
      _permissionLevel = PermissionLevel.values.firstWhere(
        (e) => e.name == perm,
        orElse: () => PermissionLevel.askMe,
      );
    }
    notifyListeners();

    if (hasSavedCredentials) {
      connect();
    }
  }

  Future<void> _saveCredentials() async {
    await _storage.write(key: 'ssh_host', value: _host);
    await _storage.write(key: 'ssh_username', value: _username);
    await _storage.write(key: 'ssh_password', value: _password);
    await _storage.write(key: 'deepseek_api_key', value: _apiKey);
  }

  void setCredentials({
    required String host,
    required String username,
    required String password,
    String apiKey = '',
  }) {
    _host = host;
    _username = username;
    _password = password;
    _apiKey = apiKey;
  }

  Future<void> setPermissionLevel(PermissionLevel level) async {
    _permissionLevel = level;
    await _storage.write(key: 'permission_level', value: level.name);
    notifyListeners();
  }

  Future<void> connect() async {
    _state = ConnState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final socket = await SSHSocket.connect(_host, 22, timeout: const Duration(seconds: 10));
      final client = SSHClient(
        socket,
        username: _username,
        onPasswordRequest: () => _password,
      );

      await client.authenticated;

      _client = client;
      _state = ConnState.connected;
      _errorMessage = null;
      await _saveCredentials();
      notifyListeners();
    } catch (e) {
      _state = ConnState.error;
      _errorMessage = e.toString();
      _client = null;
      notifyListeners();
    }
  }

  Future<void> initTerminal() async {
    if (_terminal != null && _terminalSession != null) return;

    if (_client == null || _state != ConnState.connected) {
      return;
    }

    _terminal = Terminal(
      maxLines: 10000,
      onOutput: (data) {
        _terminalSession?.stdin.add(utf8.encode(data));
      },
      onResize: (width, height, pw, ph) {
        _terminalSession?.resizeTerminal(width, height, pw, ph);
      },
    );

    notifyListeners();

    try {
      final session = await _client!.shell(
        pty: const SSHPtyConfig(type: 'xterm-256color'),
      );

      _terminalSession = session;
      _terminalActive = true;

      final stdoutSub = session.stdout.listen((data) {
        _terminal?.write(utf8.decode(data));
      });
      stdoutSub.onDone(() {
        _terminalActive = false;
        notifyListeners();
      });
      stdoutSub.onError((_) {
        _terminalActive = false;
        notifyListeners();
      });

      session.stderr.listen((data) {
        _terminal?.write(utf8.decode(data));
      });

      notifyListeners();
    } catch (e) {
      _terminal = null;
      _terminalSession = null;
      _terminalActive = false;
      notifyListeners();
    }
  }

  Future<void> reconnectTerminal() async {
    _terminalSession?.close();
    _terminalSession = null;
    _terminal = null;
    _terminalActive = false;
    notifyListeners();
    await initTerminal();
  }

  void setActiveFile(String path, String contents) {
    _activeFilePath = path;
    _activeFileContents = contents;
    notifyListeners();
  }

  Future<String> runCommand(
    String command, {
    Future<bool> Function(String command)? onConfirm,
  }) async {
    if (_client == null) {
      throw Exception('Not connected to SSH server.');
    }

    switch (_permissionLevel) {
      case PermissionLevel.readOnly:
        throw Exception('Permission denied. AI is in Read Only mode.');
      case PermissionLevel.askMe:
        if (onConfirm == null) {
          throw Exception('Permission denied. Confirmation required.');
        }
        final confirmed = await onConfirm(command);
        if (!confirmed) {
          throw Exception('Command cancelled.');
        }
        return _executeCommand(command);
      case PermissionLevel.fullAccess:
        return _executeCommand(command);
    }
  }

  Future<String> _executeCommand(String command) async {
    final result = await _client!.run(command, runInPty: false);
    return utf8.decode(result).trim();
  }

  Future<void> disconnect() async {
    _terminalSession?.close();
    _terminalSession = null;
    _terminal = null;
    _terminalActive = false;
    _client?.close();
    _client = null;
    _state = ConnState.disconnected;
    _errorMessage = null;
    notifyListeners();
  }
}
