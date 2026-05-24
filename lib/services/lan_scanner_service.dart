import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class DiscoveredHost {
  final String ip;
  final String? hostname;
  final int port;
  final int responseMs;

  DiscoveredHost({
    required this.ip,
    this.hostname,
    this.port = 22,
    required this.responseMs,
  });
}

class LANScannerService {
  final _discoveryController = StreamController<DiscoveredHost>.broadcast();
  Stream<DiscoveredHost> get discoveries => _discoveryController.stream;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progress => _progressController.stream;

  bool _cancelled = false;
  bool isScanning = false;
  String? localIP;

  Future<String?> _getLocalIP() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      if (ip != null && ip.isNotEmpty && ip != '0.0.0.0' && ip != '127.0.0.1') {
        return ip;
      }
    } catch (_) {}

    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> startScan() async {
    _cancelled = false;
    isScanning = true;

    localIP = await _getLocalIP();
    if (localIP == null || localIP!.isEmpty) {
      isScanning = false;
      throw Exception('Could not determine local IP address.\n'
          'Make sure you are connected to a Wi-Fi network.');
    }

    final parts = localIP!.split('.');
    if (parts.length != 4) {
      isScanning = false;
      throw Exception('Invalid local IP: $localIP');
    }

    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}.';
    int completed = 0;
    const total = 254;
    const batchSize = 20;

    _progressController.add(0.0);

    for (int i = 1; i <= total && !_cancelled; i += batchSize) {
      final end = (i + batchSize - 1).clamp(1, total);
      final batch = List.generate(end - i + 1, (idx) => i + idx);
      final futures = batch
          .where((n) => '$subnet$n' != localIP)
          .map((n) => _scanHost('$subnet$n'))
          .toList();

      await Future.wait(futures);

      completed += batch.length;
      _progressController.add(completed / total);
    }

    isScanning = false;
    _progressController.add(1.0);
  }

  void stopScan() {
    _cancelled = true;
    isScanning = false;
  }

  Future<void> _scanHost(String ip) async {
    if (_cancelled) return;

    final start = DateTime.now();

    try {
      final socket = await Socket.connect(
        ip,
        22,
        timeout: const Duration(milliseconds: 800),
      );
      socket.destroy();

      if (_cancelled) return;

      final elapsed = DateTime.now().difference(start).inMilliseconds;

      String? hostname;
      try {
        final addr = InternetAddress(ip);
        final result = await addr.reverse();
        final reverseHost = result.host;
        if (reverseHost.isNotEmpty && reverseHost != ip) {
          hostname = reverseHost;
        }
      } catch (_) {}

      _discoveryController.add(DiscoveredHost(
        ip: ip,
        hostname: hostname,
        port: 22,
        responseMs: elapsed,
      ));
    } catch (_) {}
  }

  void dispose() {
    _cancelled = true;
    _discoveryController.close();
    _progressController.close();
  }
}
