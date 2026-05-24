import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/connection_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final connectionProvider = context.watch<ConnectionProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(label: 'Server', isDark: isDark),
              _SettingsRow(
                label: 'Host',
                value: connectionProvider.host,
                isDark: isDark,
                onTap: () => _editField(context, 'Host', connectionProvider.host, (v) {
                  connectionProvider.setCredentials(
                    host: v,
                    username: connectionProvider.username,
                    password: connectionProvider.password,
                    apiKey: connectionProvider.apiKey,
                  );
                }),
              ),
              _SettingsRow(
                label: 'Username',
                value: connectionProvider.username,
                isDark: isDark,
                onTap: () => _editField(context, 'Username', connectionProvider.username,
                    (v) {
                  connectionProvider.setCredentials(
                    host: connectionProvider.host,
                    username: v,
                    password: connectionProvider.password,
                    apiKey: connectionProvider.apiKey,
                  );
                }),
              ),
              _SettingsRow(
                label: 'Password',
                value: connectionProvider.password.isEmpty
                    ? ''
                    : '•' * connectionProvider.password.length,
                isDark: isDark,
                onTap: () => _editField(context, 'Password', connectionProvider.password,
                    (v) {
                  connectionProvider.setCredentials(
                    host: connectionProvider.host,
                    username: connectionProvider.username,
                    password: v,
                    apiKey: connectionProvider.apiKey,
                  );
                }, obscure: true),
              ),
              const SizedBox(height: 8),
              _SectionHeader(label: 'AI', isDark: isDark),
              _SettingsRow(
                label: 'API Key',
                value: connectionProvider.apiKey.isEmpty
                    ? 'Not set'
                    : '${connectionProvider.apiKey.substring(0, 4)}...',
                isDark: isDark,
                onTap: () => _editField(
                    context, 'DeepSeek API Key', connectionProvider.apiKey, (v) {
                  connectionProvider.setCredentials(
                    host: connectionProvider.host,
                    username: connectionProvider.username,
                    password: connectionProvider.password,
                    apiKey: v,
                  );
                }, obscure: true),
              ),
              _SettingsRow(
                label: 'Permission',
                value: _permissionLabel(connectionProvider.permissionLevel),
                isDark: isDark,
                onTap: () => _pickPermission(context, connectionProvider),
              ),
              const SizedBox(height: 8),
              _SectionHeader(label: 'Appearance', isDark: isDark),
              _SettingsRow(
                label: 'Dark Mode',
                isDark: isDark,
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeThumbColor: theme.colorScheme.primary,
                ),
              ),
              _SettingsRow(
                label: 'Font Size',
                value: _fontSizeLabel(themeProvider.fontSize),
                isDark: isDark,
                onTap: () => _pickFontSize(context, themeProvider),
              ),
              _AccentColorRow(
                isDark: isDark,
                accent: themeProvider.accentColor,
                onSelect: (c) => themeProvider.setAccentColor(c),
              ),
              const SizedBox(height: 8),
              _SectionHeader(label: 'Session', isDark: isDark),
              _SettingsRow(
                label: 'Disconnect',
                labelColor: const Color(0xFFFF4444),
                isDark: isDark,
                onTap: () => connectionProvider.disconnect(),
              ),
              const SizedBox(height: 8),
              _SectionHeader(label: 'About', isDark: isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version 1.0.0',
                      style: GoogleFonts.dmMono(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF555550)
                            : const Color(0xFF999990),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Built with PaperCode',
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        color: isDark
                            ? const Color(0xFF555550)
                            : const Color(0xFF999990),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _permissionLabel(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.readOnly:
        return 'Read Only';
      case PermissionLevel.askMe:
        return 'Ask Me';
      case PermissionLevel.fullAccess:
        return 'Full Access';
    }
  }

  String _fontSizeLabel(FontSize size) {
    switch (size) {
      case FontSize.small:
        return 'Small';
      case FontSize.medium:
        return 'Medium';
      case FontSize.large:
        return 'Large';
    }
  }

  void _editField(BuildContext context, String label, String current,
      void Function(String) onSave,
      {bool obscure = false}) {
    final controller = TextEditingController(text: current);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: obscure,
                autofocus: true,
                style: GoogleFonts.dmMono(
                  fontSize: 14,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: () {
                    onSave(controller.text.trim());
                    Navigator.of(ctx).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF0A0A0A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickPermission(BuildContext context, ConnectionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final current = provider.permissionLevel;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Permission Level',
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...PermissionLevel.values.map((level) {
                final isSelected = level == current;
                return GestureDetector(
                  onTap: () {
                    provider.setPermissionLevel(level);
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.1)
                          : (isDark
                              ? const Color(0xFF0A0A0A)
                              : const Color(0xFFF5F5F0)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? accent : const Color(0xFF2A2A2A),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isSelected ? accent : const Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _permissionLabel(level),
                          style: GoogleFonts.dmMono(
                            fontSize: 13,
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFFE8E8E0)
                                    : const Color(0xFF1A1A1A))
                                : const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _pickFontSize(BuildContext context, ThemeProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final current = provider.fontSize;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Font Size',
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...FontSize.values.map((size) {
                final isSelected = size == current;
                return GestureDetector(
                  onTap: () {
                    provider.setFontSize(size);
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.1)
                          : (isDark
                              ? const Color(0xFF0A0A0A)
                              : const Color(0xFFF5F5F0)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? accent : const Color(0xFF2A2A2A),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isSelected ? accent : const Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _fontSizeLabel(size),
                          style: GoogleFonts.dmMono(
                            fontSize: 13,
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFFE8E8E0)
                                    : const Color(0xFF1A1A1A))
                                : const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmMono(
          fontSize: 10,
          letterSpacing: 0.2,
          color: isDark ? const Color(0xFF555550) : const Color(0xFF999990),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isDark;
  final VoidCallback? onTap;
  final Color? labelColor;
  final Widget? trailing;

  const _SettingsRow({
    required this.label,
    this.value,
    required this.isDark,
    this.onTap,
    this.labelColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: labelColor ??
                      (isDark ? const Color(0xFFE8E8E0) : const Color(0xFF1A1A1A)),
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (value != null)
              Text(
                value!,
                style: GoogleFonts.dmMono(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentColorRow extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final void Function(Color) onSelect;

  const _AccentColorRow({
    required this.isDark,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Accent Color',
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFE8E8E0) : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentAccent =
        context.read<ThemeProvider>().accentColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Accent Color',
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: ThemeProvider.availableAccents.map((c) {
                  final isActive = c.toARGB32() == currentAccent.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      onSelect(c);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(6),
                        border: isActive
                            ? Border.all(
                                color: isDark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF0A0A0A),
                                width: 2,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
