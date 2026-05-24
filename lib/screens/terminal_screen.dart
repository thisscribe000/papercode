import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xterm/xterm.dart';
import '../providers/connection_provider.dart';
import '../providers/theme_provider.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ConnectionProvider>();
    if (provider.terminal == null) {
      provider.initTerminal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terminal = provider.terminal;
    final terminalActive = provider.terminalActive;

    final baseFontSize = 13.0;
    final fontSize = baseFontSize * themeProvider.fontSizeScale;

    return Scaffold(
      body: Column(
        children: [
          _TopBar(host: provider.host, isDark: isDark),
          if (terminal != null && !terminalActive)
            _ReconnectBanner(isDark: isDark, onReconnect: () => provider.reconnectTerminal()),
          Expanded(
            child: terminal != null
                ? ClipRect(
                    child: TerminalView(
                      terminal,
                      textStyle: TerminalStyle(fontSize: fontSize),
                      theme: isDark ? _darkTerminalTheme : _lightTerminalTheme,
                      autofocus: true,
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _ReconnectBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onReconnect;

  const _ReconnectBanner({required this.isDark, required this.onReconnect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReconnect,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A0A0A) : const Color(0xFFFFF0F0),
          border: Border(
            bottom: BorderSide(
              color: Colors.redAccent.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              'Session dropped',
              style: GoogleFonts.dmMono(
                fontSize: 11,
                color: Colors.redAccent,
              ),
            ),
            const Spacer(),
            Text(
              'Reconnect',
              style: GoogleFonts.dmMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String host;
  final bool isDark;

  const _TopBar({required this.host, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dns_outlined,
            size: 13,
            color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
          ),
          const SizedBox(width: 6),
          Text(
            host,
            style: GoogleFonts.dmMono(
              fontSize: 12,
              color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              context.read<ConnectionProvider>().disconnect();
            },
            child: Icon(
              Icons.power_settings_new,
              size: 16,
              color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}

final _darkTerminalTheme = TerminalTheme(
  cursor: const Color(0xFFE8FF00),
  selection: const Color(0x55E8FF00),
  foreground: const Color(0xFFE8FF00),
  background: const Color(0xFF0A0A0A),
  black: const Color(0xFF000000),
  red: const Color(0xFFCD3131),
  green: const Color(0xFF0DBC79),
  yellow: const Color(0xFFE5E510),
  blue: const Color(0xFF2472C8),
  magenta: const Color(0xFFBC3FBC),
  cyan: const Color(0xFF11A8CD),
  white: const Color(0xFFE5E5E5),
  brightBlack: const Color(0xFF666666),
  brightRed: const Color(0xFFF14C4C),
  brightGreen: const Color(0xFF23D18B),
  brightYellow: const Color(0xFFF5F543),
  brightBlue: const Color(0xFF3B8EEA),
  brightMagenta: const Color(0xFFD670D6),
  brightCyan: const Color(0xFF29B8DB),
  brightWhite: const Color(0xFFFFFFFF),
  searchHitBackground: Color(0xFFFFFF2B),
  searchHitBackgroundCurrent: Color(0xFF31FF26),
  searchHitForeground: Color(0xFF000000),
);

final _lightTerminalTheme = TerminalTheme(
  cursor: const Color(0xFFE8FF00),
  selection: const Color(0x55E8FF00),
  foreground: const Color(0xFF1A1A1A),
  background: const Color(0xFFF5F5F0),
  black: const Color(0xFF000000),
  red: const Color(0xFFCD3131),
  green: const Color(0xFF0DBC79),
  yellow: const Color(0xFFE5E510),
  blue: const Color(0xFF2472C8),
  magenta: const Color(0xFFBC3FBC),
  cyan: const Color(0xFF11A8CD),
  white: const Color(0xFFE5E5E5),
  brightBlack: const Color(0xFF666666),
  brightRed: const Color(0xFFF14C4C),
  brightGreen: const Color(0xFF23D18B),
  brightYellow: const Color(0xFFF5F543),
  brightBlue: const Color(0xFF3B8EEA),
  brightMagenta: const Color(0xFFD670D6),
  brightCyan: const Color(0xFF29B8DB),
  brightWhite: const Color(0xFFFFFFFF),
  searchHitBackground: Color(0xFFFFFF2B),
  searchHitBackgroundCurrent: Color(0xFF31FF26),
  searchHitForeground: Color(0xFF000000),
);
