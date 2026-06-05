import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/connection_provider.dart';
import '../providers/auth_provider.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _showSshForm = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ConnectionProvider>();
    _hostController.text = provider.host;
    _usernameController.text = provider.username;
    _passwordController.text = provider.password;
    _apiKeyController.text = provider.apiKey;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _connect() {
    final provider = context.read<ConnectionProvider>();
    provider.setCredentials(
      host: _hostController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      apiKey: _apiKeyController.text.trim(),
    );
    provider.connect();
  }

  void _goLocal() {
    context.read<ConnectionProvider>().enableLocalMode();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PaperCode',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmMono(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'your code editor, anywhere.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmMono(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 36),
                _buildLocalButton(theme),
                const SizedBox(height: 12),
                _buildGoogleButton(theme),
                const SizedBox(height: 12),
                _buildSshToggle(theme, isDark),
                if (_showSshForm) ...[
                  const SizedBox(height: 20),
                  _buildField('Host', _hostController, theme, hint: '163.245.210.70'),
                  const SizedBox(height: 20),
                  _buildField('Username', _usernameController, theme, hint: 'root'),
                  const SizedBox(height: 20),
                  _buildField('Password', _passwordController, theme, obscure: true),
                  const SizedBox(height: 20),
                  _buildField('DeepSeek API Key', _apiKeyController, theme, hint: 'sk-...'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: provider.isConnecting ? null : _connect,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: const Color(0xFF0A0A0A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: provider.isConnecting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0A0A0A),
                              ),
                            )
                          : Text(
                              'Connect',
                              style: GoogleFonts.dmMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalButton(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: _goLocal,
        icon: const Icon(Icons.phone_android, size: 18),
        label: Text(
          'Start Coding Locally',
          style: GoogleFonts.dmMono(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(ThemeData theme) {
    final auth = context.watch<AuthProvider>();
    if (auth.isSignedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2A2A2A)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
              child: auth.photoUrl == null ? const Icon(Icons.person, size: 16) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.displayName ?? 'User',
                    style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                  ),
                  Text(
                    auth.email ?? '',
                    style: GoogleFonts.dmMono(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => auth.signOut(),
              child: Icon(Icons.logout, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => auth.signIn(),
        icon: const Icon(Icons.login, size: 18),
        label: Text(
          'Sign in with Google',
          style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: const Color(0xFF2A2A2A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildSshToggle(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _showSshForm = !_showSshForm),
        icon: Icon(_showSshForm ? Icons.expand_less : Icons.dns_outlined, size: 18),
        label: Text(
          _showSshForm ? 'Hide SSH Connection' : 'Connect via SSH',
          style: GoogleFonts.dmMono(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, ThemeData theme, {String? hint, bool obscure = false}) {
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
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }
}
