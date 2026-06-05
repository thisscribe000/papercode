import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/ollama_provider.dart';
import '../providers/auth_provider.dart';
import '../models/ai_provider.dart';
import '../widgets/provider_sheet.dart';
import 'ollama_screen.dart';

class _GoogleAccountRow extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _GoogleAccountRow({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isSignedIn) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: GestureDetector(
          onTap: () => auth.signIn(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.login, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(
                  'Sign in with Google to link APIs',
                  style: GoogleFonts.dmMono(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 12,
              backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
              child: auth.photoUrl == null ? const Icon(Icons.person, size: 12) : null),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.displayName ?? 'User',
                    style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  Text(auth.email ?? '',
                    style: GoogleFonts.dmMono(fontSize: 9, color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA))),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => auth.signOut(),
              child: Icon(Icons.logout, size: 14, color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickApiSetupRow extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final ConnectionProvider connectionProvider;

  const _QuickApiSetupRow({required this.isDark, required this.theme, required this.connectionProvider});

  @override
  Widget build(BuildContext context) {
    final provider = connectionProvider.activeProvider;
    if (!provider.requiresApiKey || provider.type == AIProviderType.ollama) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          if (provider.keyHelperUrl != null)
            Expanded(
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse(provider.keyHelperUrl!), mode: LaunchMode.externalApplication),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Get ${provider.name} Key',
                        style: GoogleFonts.dmMono(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (provider.keyHelperUrl != null) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _pasteKey(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.content_paste, size: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      'Paste Key',
                      style: GoogleFonts.dmMono(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pasteKey(BuildContext context) {
    final provider = connectionProvider.activeProvider;
    final keyLabel = provider.apiKeyLabel;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              Text(keyLabel,
                style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                style: GoogleFonts.dmMono(fontSize: 14, color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Paste your key here...',
                  hintStyle: GoogleFonts.dmMono(fontSize: 12, color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: () {
                    final key = controller.text.trim();
                    if (key.isNotEmpty) {
                      connectionProvider.setApiKey(connectionProvider.activeProviderType, key);
                      Navigator.of(ctx).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: const Color(0xFF0A0A0A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text('Save Key', style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final connectionProvider = context.watch<ConnectionProvider>();
    final ollamaProvider = context.watch<OllamaProvider>();

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
                  );
                }, obscure: true),
              ),
              const SizedBox(height: 8),
              _SectionHeader(label: 'AI', isDark: isDark),
              _GoogleAccountRow(isDark: isDark, theme: theme),
              const SizedBox(height: 4),
              _SettingsRow(
                label: 'AI Provider',
                value: connectionProvider.activeProvider.name,
                isDark: isDark,
                onTap: () => showProviderSheet(
                  context,
                  connectionProvider.activeProviderType,
                  (type) => connectionProvider.setActiveProvider(type),
                ),
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connectionProvider.activeProvider.dotColor,
                  ),
                ),
              ),
              _QuickApiSetupRow(isDark: isDark, theme: theme, connectionProvider: connectionProvider),
              if (connectionProvider.activeProvider.requiresApiKey)
                _SettingsRow(
                  label: connectionProvider.activeProvider.apiKeyLabel,
                  value: connectionProvider.apiKey.isEmpty
                      ? 'Not set'
                      : '•••••${connectionProvider.apiKey.substring(connectionProvider.apiKey.length > 6 ? connectionProvider.apiKey.length - 6 : 0)}',
                  isDark: isDark,
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connectionProvider.apiKey.isNotEmpty
                          ? const Color(0xFF44FF88)
                          : const Color(0xFFFF4444),
                    ),
                  ),
                  onTap: () => _manageApiKey(context, connectionProvider),
                ),
              if (connectionProvider.activeProviderType == AIProviderType.custom) ...[
                _SettingsRow(
                  label: 'Base URL',
                  value: connectionProvider.customBaseUrl.isEmpty
                      ? 'Not set'
                      : connectionProvider.customBaseUrl,
                  isDark: isDark,
                  onTap: () => _editField(
                    context,
                    'Base URL',
                    connectionProvider.customBaseUrl,
                    (v) => connectionProvider.setCustomBaseUrl(v),
                  ),
                ),
                _SettingsRow(
                  label: 'Model Name',
                  value: connectionProvider.customModel.isEmpty
                      ? 'Not set'
                      : connectionProvider.customModel,
                  isDark: isDark,
                  onTap: () => _editField(
                    context,
                    'Model Name',
                    connectionProvider.customModel,
                    (v) => connectionProvider.setCustomModel(v),
                  ),
                ),
              ],
              if (connectionProvider.activeProviderType == AIProviderType.ollama)
                _SettingsRow(
                  label: 'Manage Ollama \u2192',
                  value: ollamaProvider.activeModelName != null
                      ? 'Model: ${ollamaProvider.activeModelName}'
                      : null,
                  isDark: isDark,
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ollamaProvider.isReachable == true
                          ? const Color(0xFF44FF88)
                          : const Color(0xFFFF4444),
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OllamaScreen()),
                  ),
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

  String _keyHelperText(AIProvider provider) {
    if (provider.type == AIProviderType.ollama) {
      return 'No key needed — make sure Ollama is running';
    }
    if (provider.type == AIProviderType.custom) {
      return 'Enter your OpenAI-compatible endpoint key';
    }
    return 'Get your key at ${provider.keyHelperUrl ?? provider.baseUrl}';
  }

  void _manageApiKey(BuildContext context, ConnectionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final activeProvider = provider.activeProvider;
    final hasKey = provider.apiKey.isNotEmpty;
    final controller = TextEditingController(text: provider.apiKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                activeProvider.name,
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              if (hasKey) ...[
                const SizedBox(height: 8),
                Text(
                  'Current key: •••••${provider.apiKey.substring(provider.apiKey.length > 6 ? provider.apiKey.length - 6 : 0)}',
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: !hasKey,
                style: GoogleFonts.dmMono(
                  fontSize: 14,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hasKey ? 'Paste new key to replace...' : 'Paste your API key',
                  hintStyle: GoogleFonts.dmMono(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _keyHelperText(activeProvider),
                style: GoogleFonts.dmMono(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF444444) : const Color(0xFFBBBBBB),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: () {
                    final val = controller.text.trim();
                    if (val.isNotEmpty) {
                      provider.setApiKey(activeProvider.type, val);
                    }
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
              if (hasKey) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    provider.clearApiKey(activeProvider.type);
                    Navigator.of(ctx).pop();
                  },
                  child: Center(
                    child: Text(
                      'Clear key',
                      style: GoogleFonts.dmMono(
                        fontSize: 11,
                        color: const Color(0xFFFF4444).withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
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
  final Widget? leading;

  const _SettingsRow({
    required this.label,
    this.value,
    required this.isDark,
    this.onTap,
    this.labelColor,
    this.trailing,
    this.leading,
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
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
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
    final currentAccent = context.read<ThemeProvider>().accentColor;

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
