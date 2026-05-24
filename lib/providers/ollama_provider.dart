import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/ollama_service.dart';

class OllamaProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _ollamaHost = 'http://localhost:11434';
  bool? _isReachable;
  List<OllamaModel> _models = [];
  String? _activeModelName;
  bool _isPulling = false;
  OllamaDownloadProgress? _pullProgress;

  String get ollamaHost => _ollamaHost;
  bool? get isReachable => _isReachable;
  List<OllamaModel> get models => _models;
  String? get activeModelName => _activeModelName;
  bool get isPulling => _isPulling;
  OllamaDownloadProgress? get pullProgress => _pullProgress;

  OllamaService get _service => OllamaService(baseUrl: _ollamaHost);

  OllamaProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final host = await _storage.read(key: 'ollama_host');
    if (host != null && host.isNotEmpty) {
      _ollamaHost = host;
    }
    _activeModelName = await _storage.read(key: 'ollama_active_model');
    notifyListeners();
  }

  Future<void> setHost(String host) async {
    _ollamaHost = host;
    await _storage.write(key: 'ollama_host', value: host);
    _isReachable = null;
    notifyListeners();
  }

  Future<bool> testConnection() async {
    final reachable = await _service.isReachable();
    _isReachable = reachable;
    notifyListeners();
    return reachable;
  }

  Future<void> loadModels() async {
    try {
      _models = await _service.getModels();
    } catch (_) {
      _models = [];
    }
    notifyListeners();
  }

  Future<void> setActiveModel(OllamaModel model) async {
    _activeModelName = model.name;
    await _storage.write(key: 'ollama_active_model', value: model.name);
    notifyListeners();
  }

  Future<void> setActiveModelByName(String name) async {
    _activeModelName = name;
    await _storage.write(key: 'ollama_active_model', value: name);
    notifyListeners();
  }

  Future<void> pullModel(String name) async {
    _isPulling = true;
    _pullProgress = null;
    notifyListeners();

    try {
      await for (final progress in _service.pullModel(name)) {
        _pullProgress = progress;
        notifyListeners();

        if (progress.status == 'success') {
          // Refresh the model list
          await loadModels();
          break;
        } else if (progress.status == 'error') {
          break;
        }
      }
    } catch (e) {
      _pullProgress = OllamaDownloadProgress(status: 'error', error: e.toString());
    }

    _isPulling = false;
    notifyListeners();
  }

  Future<void> deleteModel(String name) async {
    try {
      await _service.deleteModel(name);
      _models.removeWhere((m) => m.name == name);
      if (_activeModelName == name) {
        _activeModelName = null;
        await _storage.delete(key: 'ollama_active_model');
      }
      notifyListeners();
    } catch (_) {}
  }
}
