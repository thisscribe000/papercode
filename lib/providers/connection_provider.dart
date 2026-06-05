import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import '../models/ai_provider.dart';
import '../models/server_profile.dart';
import '../services/server_profile_service.dart';

enum PermissionLevel { readOnly, askMe, fullAccess }

enum ConnState { disconnected, connecting, connected, error }

class ConnectionProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final ServerProfileService _profileService;

  ConnState _state = ConnState.disconnected;
  String? _errorMessage;
  SSHClient? _client;
  SSHSession? _terminalSession;
  Terminal? _terminal;
  String? _activeFilePath;
  String? _activeFileContents;
  PermissionLevel _permissionLevel = PermissionLevel.askMe;
  bool _terminalActive = false;
  bool _localMode = false;

  AIProviderType _activeProviderType = AIProviderType.deepseek;
  final Map<AIProviderType, String> _apiKeys = {};
  String _customBaseUrl = '';
  String _customModel = '';

  List<ServerProfile> _profiles = [];
  ServerProfile? _activeProfile;
  String? _lastActiveProfileId;
  bool _autoConnect = true;

  ConnState get state => _state;
  bool get isConnected => _state == ConnState.connected;
  bool get isConnecting => _state == ConnState.connecting;
  String? get errorMessage => _errorMessage;

  ServerProfile? get activeProfile => _activeProfile;
  List<ServerProfile> get profiles => _profiles;
  bool get autoConnect => _autoConnect;

  String get host => _activeProfile?.host ?? '';
  String get username => _activeProfile?.username ?? '';
  String get password => _activeProfile?.password ?? '';

  SSHClient? get client => _client;
  SSHSession? get terminalSession => _terminalSession;
  Terminal? get terminal => _terminal;
  bool get terminalActive => _terminalActive;
  bool get localMode => _localMode;
  String? get activeFilePath => _activeFilePath;
  String? get activeFileContents => _activeFileContents;
  PermissionLevel get permissionLevel => _permissionLevel;

  AIProvider get activeProvider => AIProvider.byType(_activeProviderType);
  AIProviderType get activeProviderType => _activeProviderType;
  String get apiKey => _apiKeys[_activeProviderType] ?? '';
  String get customBaseUrl => _customBaseUrl;
  String get customModel => _customModel;
  bool get hasSavedCredentials => _activeProfile != null;

  bool hasApiKey(AIProviderType type) {
    if (AIProvider.byType(type).requiresApiKey == false) return true;
    final key = _apiKeys[type];
    return key != null && key.isNotEmpty;
  }

  bool get activeProviderHasKey {
    if (!activeProvider.requiresApiKey) return true;
    return apiKey.isNotEmpty;
  }

  String? get providerValidationError {
    if (_activeProviderType == AIProviderType.custom) {
      if (_customBaseUrl.isEmpty) return 'No base URL set for Custom provider';
    }
    if (activeProvider.requiresApiKey && !hasApiKey(_activeProviderType)) {
      return 'No API key set for ${activeProvider.name}';
    }
    return null;
  }

  ConnectionProvider() {
    _profileService = ServerProfileService(_storage);
    _loadAll();
  }

  Future<void> _loadAll() async {
    for (final type in AIProviderType.values) {
      final keyName = 'apikey_${type.name}';
      final val = await _storage.read(key: keyName);
      if (val != null && val.isNotEmpty) {
        _apiKeys[type] = val;
      }
    }

    final savedProvider = await _storage.read(key: 'active_provider');
    if (savedProvider != null) {
      _activeProviderType = AIProviderType.values.firstWhere(
        (e) => e.name == savedProvider,
        orElse: () => AIProviderType.deepseek,
      );
    }

    _customBaseUrl = await _storage.read(key: 'custom_base_url') ?? '';
    _customModel = await _storage.read(key: 'custom_model') ?? '';

    final perm = await _storage.read(key: 'permission_level');
    if (perm != null) {
      _permissionLevel = PermissionLevel.values.firstWhere(
        (e) => e.name == perm,
        orElse: () => PermissionLevel.askMe,
      );
    }

    final auto = await _storage.read(key: 'auto_connect');
    _autoConnect = auto != 'false';

    _lastActiveProfileId = await _storage.read(key: 'last_active_profile');
    _profiles = await _profileService.loadAll();

    notifyListeners();

    if (_autoConnect && _lastActiveProfileId != null) {
      final profile = _profiles.firstWhere(
        (p) => p.id == _lastActiveProfileId,
        orElse: () => _profiles.isNotEmpty ? _profiles.first : ServerProfile(id: '', name: '', host: '', username: ''),
      );
      if (profile.host.isNotEmpty && profile.username.isNotEmpty) {
        _activeProfile = profile;
        connect();
      }
    }
  }

  Future<void> loadProfiles() async {
    _profiles = await _profileService.loadAll();
    notifyListeners();
  }

  Future<void> addProfile(ServerProfile profile) async {
    await _profileService.save(profile);
    _profiles = await _profileService.loadAll();
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    await _profileService.delete(id);
    _profiles = await _profileService.loadAll();
    if (_activeProfile?.id == id) {
      _activeProfile = null;
      _lastActiveProfileId = null;
      await _storage.delete(key: 'last_active_profile');
    }
    notifyListeners();
  }

  Future<void> setAutoConnect(bool value) async {
    _autoConnect = value;
    await _storage.write(key: 'auto_connect', value: value ? 'true' : 'false');
    notifyListeners();
  }

  Future<void> connectToProfile(ServerProfile profile) async {
    _activeProfile = profile;
    _lastActiveProfileId = profile.id;
    await _storage.write(key: 'last_active_profile', value: profile.id);
    await _profileService.setLastConnected(profile.id);
    connect();
  }

  void setCredentials({
    required String host,
    required String username,
    required String password,
    String apiKey = '',
  }) {
    if (_activeProfile == null) {
      _activeProfile = ServerProfile(
        id: ServerProfile.generateId(),
        name: host,
        host: host,
        username: username,
        password: password,
      );
      _lastActiveProfileId = _activeProfile!.id;
    } else {
      _activeProfile = _activeProfile!.copyWith(
        host: host,
        username: username,
        password: password,
      );
    }
    if (apiKey.isNotEmpty) {
      _apiKeys[_activeProviderType] = apiKey;
    }
  }

  Future<void> setActiveProvider(AIProviderType type) async {
    _activeProviderType = type;
    if (type == AIProviderType.custom) {
      if (_customBaseUrl.isEmpty) _customBaseUrl = 'http://localhost:11434/v1';
      if (_customModel.isEmpty) _customModel = 'llama3';
    }
    await _storage.write(key: 'active_provider', value: type.name);
    notifyListeners();
  }

  Future<void> setApiKey(AIProviderType type, String key) async {
    _apiKeys[type] = key;
    await _storage.write(key: 'apikey_${type.name}', value: key);
    notifyListeners();
  }

  String getApiKey(AIProviderType type) => _apiKeys[type] ?? '';

  Future<void> setCustomBaseUrl(String url) async {
    _customBaseUrl = url;
    await _storage.write(key: 'custom_base_url', value: url);
    notifyListeners();
  }

  Future<void> setCustomModel(String model) async {
    _customModel = model;
    await _storage.write(key: 'custom_model', value: model);
    notifyListeners();
  }

  Future<void> setPermissionLevel(PermissionLevel level) async {
    _permissionLevel = level;
    await _storage.write(key: 'permission_level', value: level.name);
    notifyListeners();
  }

  Future<void> clearApiKey(AIProviderType type) async {
    _apiKeys.remove(type);
    await _storage.delete(key: 'apikey_${type.name}');
    notifyListeners();
  }

  Future<void> connect() async {
    if (_activeProfile == null) return;
    _state = ConnState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final socket = await SSHSocket.connect(
        _activeProfile!.host,
        _activeProfile!.port,
        timeout: const Duration(seconds: 10),
      );
      final client = SSHClient(
        socket,
        username: _activeProfile!.username,
        onPasswordRequest: () => _activeProfile!.password,
      );

      await client.authenticated;

      _client = client;
      _state = ConnState.connected;
      _errorMessage = null;
      if (_activeProfile != null) {
        await addProfile(_activeProfile!);
      }
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

  void enableLocalMode() {
    _localMode = true;
    _state = ConnState.connected;
    _errorMessage = null;
    notifyListeners();
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
