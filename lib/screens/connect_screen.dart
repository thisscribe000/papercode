import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/connection_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();
    final theme = Theme.of(context);

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
                  'your vps. your ai. your terminal.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmMono(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 48),
                _buildField('Host', _hostController, theme, hint: '163.245.210.70'),
                const SizedBox(height: 20),
                _buildField('Username', _usernameController, theme, hint: 'root'),
                const SizedBox(height: 20),
                _buildField('Password', _passwordController, theme, obscure: true),
                const SizedBox(height: 20),
                _buildField('DeepSeek API Key', _apiKeyController, theme, hint: 'sk-...'),
                const SizedBox(height: 32),
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

  Widget _buildField(
    String label,
    TextEditingController controller,
    ThemeData theme, {
    String? hint,
    bool obscure = false,
  }) {
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
