import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/connection_provider.dart';
import '../models/server_profile.dart';
import 'lan_scan_screen.dart';

class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  ServerType _serverType = ServerType.remote;
  String? _testResult;
  bool _testing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openScan() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const LANScanScreen()),
    );
    if (result != null && mounted) {
      _hostController.text = result['ip'] ?? '';
      if (_nameController.text.isEmpty) {
        _nameController.text = result['hostname'] ?? '';
      }
    }
  }

  Future<void> _testConnection() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 22;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (host.isEmpty || username.isEmpty) {
      setState(() => _testResult = 'Fill in Host, Username, and Password first');
      return;
    }

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final profile = ServerProfile(
        id: 'test',
        name: 'test',
        host: host,
        port: port,
        username: username,
        password: password,
        type: _serverType,
      );
      final provider = context.read<ConnectionProvider>();
      await provider.connectToProfile(profile);
      await provider.disconnect();
      setState(() => _testResult = 'Connection successful');
    } catch (e) {
      setState(() => _testResult = 'Connection failed: $e');
    }

    setState(() => _testing = false);
  }

  void _save() {
    final name = _nameController.text.trim();
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 22;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || host.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fill in Name, Host, and Username', style: GoogleFonts.dmMono(fontSize: 12)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
      return;
    }

    final profile = ServerProfile(
      id: ServerProfile.generateId(),
      name: name,
      host: host,
      port: port,
      username: username,
      password: password,
      type: _serverType,
    );

    context.read<ConnectionProvider>().addProfile(profile);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Add Server',
          style: GoogleFonts.dmMono(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.close, size: 20, color: isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            height: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField('Server Name', _nameController, theme, hint: 'My VPS, MacBook, etc.'),
              const SizedBox(height: 20),
              _buildTypeToggle(theme, isDark),
              const SizedBox(height: 20),
              _buildField(
                'Host',
                _hostController, theme,
                hint: _serverType == ServerType.local
                    ? 'e.g. 192.168.1.10 or localhost'
                    : 'e.g. 163.245.210.70',
              ),
              if (_serverType == ServerType.local) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: _openScan,
                    icon: const Icon(Icons.wifi_find, size: 16),
                    label: Text(
                      'Scan Network',
                      style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00F5FF),
                      side: const BorderSide(color: Color(0xFF00F5FF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildField('Port', _portController, theme, hint: '22'),
              const SizedBox(height: 20),
              _buildField('Username', _usernameController, theme, hint: 'root'),
              const SizedBox(height: 20),
              _buildField('Password', _passwordController, theme, obscure: true),
              const SizedBox(height: 24),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: _testing ? null : _testConnection,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: _testing
                      ? SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                        )
                      : Text(
                          'Test Connection',
                          style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  _testResult!,
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: _testResult!.startsWith('Connection successful')
                        ? const Color(0xFF44FF88)
                        : Colors.redAccent,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF0A0A0A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    'Save Server',
                    style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Server Type',
          style: GoogleFonts.dmMono(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _serverType = ServerType.remote),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _serverType == ServerType.remote
                          ? theme.colorScheme.primary
                          : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
                    ),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                  ),
                  child: Text(
                    'Remote',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _serverType == ServerType.remote
                          ? theme.colorScheme.primary
                          : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 0),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _serverType = ServerType.local),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _serverType == ServerType.local
                          ? theme.colorScheme.primary
                          : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
                    ),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                  child: Text(
                    'Local',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _serverType == ServerType.local
                          ? theme.colorScheme.primary
                          : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, ThemeData theme,
      {String? hint, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmMono(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: label == 'Port' ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.dmMono(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.dmMono(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }
}
