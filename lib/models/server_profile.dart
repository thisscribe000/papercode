import 'dart:convert';

enum ServerType { remote, local }

class ServerProfile {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final ServerType type;
  final DateTime lastConnected;

  ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.password = '',
    this.type = ServerType.remote,
    DateTime? lastConnected,
  }) : lastConnected = lastConnected ?? DateTime.now();

  ServerProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    ServerType? type,
    DateTime? lastConnected,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      type: type ?? this.type,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'type': type.name,
        'lastConnected': lastConnected.toIso8601String(),
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) => ServerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        host: json['host'] as String,
        port: json['port'] as int,
        username: json['username'] as String,
        password: json['password'] as String? ?? '',
        type: ServerType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ServerType.remote,
        ),
        lastConnected: json['lastConnected'] != null
            ? DateTime.parse(json['lastConnected'] as String)
            : null,
      );

  static String generateId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  static String profilesToJson(List<ServerProfile> profiles) =>
      jsonEncode(profiles.map((p) => p.toJson()).toList());

  static List<ServerProfile> profilesFromJson(String json) {
    final list = jsonDecode(json);
    if (list is List) {
      return list.map((e) => ServerProfile.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
