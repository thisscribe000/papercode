import 'dart:async';
import 'package:flutter/material.dart';
import '../services/lan_scanner_service.dart';

class LANScannerProvider extends ChangeNotifier {
  final _service = LANScannerService();

  bool _isScanning = false;
  List<DiscoveredHost> _discovered = [];
  double _progress = 0.0;
  String? _localIP;
  String? _error;

  StreamSubscription<DiscoveredHost>? _discoverySub;
  StreamSubscription<double>? _progressSub;

  bool get isScanning => _isScanning;
  List<DiscoveredHost> get discovered => _discovered;
  double get progress => _progress;
  String? get localIP => _localIP;
  String? get error => _error;

  Future<void> startScan() async {
    _discovered = [];
    _progress = 0.0;
    _error = null;
    _isScanning = true;
    notifyListeners();

    _discoverySub?.cancel();
    _progressSub?.cancel();

    _discoverySub = _service.discoveries.listen((host) {
      if (!_discovered.any((h) => h.ip == host.ip)) {
        _discovered.add(host);
      }
      notifyListeners();
    });

    _progressSub = _service.progress.listen((p) {
      _progress = p;
      notifyListeners();
    });

    try {
      await _service.startScan();
      _localIP = _service.localIP;
    } catch (e) {
      _error = e.toString();
    }

    _isScanning = false;
    notifyListeners();
  }

  void stopScan() {
    _service.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  void reset() {
    stopScan();
    _discovered = [];
    _progress = 0.0;
    _error = null;
    _localIP = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _discoverySub?.cancel();
    _progressSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
