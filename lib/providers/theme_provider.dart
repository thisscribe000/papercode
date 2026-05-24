import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum FontSize { small, medium, large }

class ThemeProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isDarkMode = true;
  Color _accentColor = const Color(0xFFE8FF00);
  FontSize _fontSize = FontSize.medium;

  bool get isDarkMode => _isDarkMode;
  Color get accentColor => _accentColor;
  FontSize get fontSize => _fontSize;

  static const List<Color> availableAccents = [
    Color(0xFFE8FF00), // Yellow Green
    Color(0xFF00F5FF), // Cyan
    Color(0xFFFF6B00), // Burnt Orange
    Color(0xFFFF2D6B), // Hot Pink
    Color(0xFFA78BFA), // Electric Purple
    Color(0xFFFF4444), // Signal Red
    Color(0xFF44FF88), // Lime Green
  ];

  static const List<String> _accentNames = [
    'Yellow Green',
    'Cyan',
    'Burnt Orange',
    'Hot Pink',
    'Electric Purple',
    'Signal Red',
    'Lime Green',
  ];

  String accentName(Color c) {
    final i = availableAccents.indexOf(c);
    return i >= 0 ? _accentNames[i] : 'Custom';
  }

  double get fontSizeScale {
    switch (_fontSize) {
      case FontSize.small:
        return 0.9;
      case FontSize.medium:
        return 1.0;
      case FontSize.large:
        return 1.15;
    }
  }

  ThemeProvider() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    final mode = await _storage.read(key: 'theme_mode');
    if (mode != null) _isDarkMode = mode == 'dark';

    final accent = await _storage.read(key: 'accent_color');
    if (accent != null) {
      final hex = int.tryParse(accent.replaceFirst('#', '0xFF'));
      if (hex != null) _accentColor = Color(hex);
    }

    final size = await _storage.read(key: 'font_size');
    if (size != null) {
      _fontSize = FontSize.values.firstWhere(
        (e) => e.name == size,
        orElse: () => FontSize.medium,
      );
    }

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storage.write(key: 'theme_mode', value: _isDarkMode ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    await _storage.write(key: 'accent_color', value: hex);
    notifyListeners();
  }

  Future<void> setFontSize(FontSize size) async {
    _fontSize = size;
    await _storage.write(key: 'font_size', value: size.name);
    notifyListeners();
  }
}
