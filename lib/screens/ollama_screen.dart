import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ollama_provider.dart';
import '../services/ollama_service.dart';

class OllamaScreen extends StatefulWidget {
  const OllamaScreen({super.key});

  @override
  State<OllamaScreen> createState() => _OllamaScreenState();
}

class _OllamaScreenState extends State<OllamaScreen> {
  final _hostController = TextEditingController();
  final _pullController = TextEditingController();
  bool _testing = false;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    final provider = context.read<OllamaProvider>();
    _hostController.text = provider.ollamaHost;
    provider.loadModels();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _pullController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    final provider = context.read<OllamaProvider>();
    await provider.setHost(host);
    final reachable = await provider.testConnection();

    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = reachable;
      });
      if (reachable) {
        provider.loadModels();
      }
    }
  }

  Future<void> _pullModel() async {
    final name = _pullController.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<OllamaProvider>();
    await provider.pullModel(name);
    _pullController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final provider = context.watch<OllamaProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Ollama',
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
        child: RefreshIndicator(
          onRefresh: () => provider.loadModels(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionHeader('Connection', isDark),
                _buildHostField(theme, isDark, accent, provider),
                const SizedBox(height: 8),
                _buildTestButton(theme, isDark, accent),
                if (_testResult != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _testResult! ? 'Connected' : 'Not reachable',
                    style: GoogleFonts.dmMono(
                      fontSize: 11,
                      color: _testResult! ? const Color(0xFF44FF88) : Colors.redAccent,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Run Ollama on your phone or a machine on your local network.',
                  style: GoogleFonts.dmMono(
                    fontSize: 9,
                    color: isDark ? const Color(0xFF444444) : const Color(0xFFBBBBBB),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader('Installed Models', isDark),
                if (provider.models.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No models installed. Pull one below.',
                      style: GoogleFonts.dmMono(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...provider.models.map((model) => _modelRow(model, theme, isDark, accent, provider)),
                const SizedBox(height: 24),
                _sectionHeader('Pull New Model', isDark),
                _buildPullField(theme, isDark, accent, provider),
                if (provider.isPulling && provider.pullProgress != null) ...[
                  const SizedBox(height: 12),
                  _buildPullProgress(provider, theme, isDark, accent),
                ],
                if (!provider.isPulling && provider.pullProgress?.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      provider.pullProgress!.error!,
                      style: GoogleFonts.dmMono(fontSize: 11, color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildHostField(ThemeData theme, bool isDark, Color accent, OllamaProvider provider) {
    return TextField(
      controller: _hostController,
      style: GoogleFonts.dmMono(fontSize: 14, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'http://localhost:11434',
        hintStyle: GoogleFonts.dmMono(
          fontSize: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildTestButton(ThemeData theme, bool isDark, Color accent) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: _testing ? null : _testConnection,
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: _testing
            ? SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            : Text('Test Connection', style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _modelRow(OllamaModel model, ThemeData theme, bool isDark, Color accent, OllamaProvider provider) {
    final isActive = model.name == provider.activeModelName;

    return Dismissible(
      key: ValueKey(model.name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.redAccent,
        child: Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
            title: Text('Delete "${model.name}"?', style: GoogleFonts.dmMono(fontSize: 13, color: theme.colorScheme.onSurface)),
            content: Text('This cannot be undone.', style: GoogleFonts.dmMono(fontSize: 11, color: isDark ? const Color(0xFF666666) : const Color(0xFF999999))),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: GoogleFonts.dmMono(fontSize: 11))),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Delete', style: GoogleFonts.dmMono(fontSize: 11, color: Colors.redAccent))),
            ],
          ),
        );
      },
      onDismissed: (_) => provider.deleteModel(model.name),
      child: GestureDetector(
        onTap: () => provider.setActiveModel(model),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isActive ? accent : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: GoogleFonts.dmMono(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.size,
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  model.paramCount,
                  style: GoogleFonts.dmMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPullField(ThemeData theme, bool isDark, Color accent, OllamaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _pullController,
          enabled: !provider.isPulling,
          style: GoogleFonts.dmMono(fontSize: 14, color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'e.g. llama3, mistral, phi3',
            hintStyle: GoogleFonts.dmMono(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find models at ollama.com/library',
          style: GoogleFonts.dmMono(
            fontSize: 9,
            color: isDark ? const Color(0xFF444444) : const Color(0xFFBBBBBB),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: provider.isPulling ? null : _pullModel,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: const Color(0xFF0A0A0A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(
              'Pull Model',
              style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPullProgress(OllamaProvider provider, ThemeData theme, bool isDark, Color accent) {
    final progress = provider.pullProgress!;
    final statusText = progress.status == 'pulling'
        ? 'Pulling${progress.percent != null ? ' ${(progress.percent! * 100).toInt()}%' : ''}…'
        : progress.status == 'verifying'
            ? 'Verifying…'
            : progress.status == 'success'
                ? 'Done'
                : progress.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              progress.status == 'success' ? _pullController.text.isNotEmpty ? _pullController.text : 'Model' : statusText,
              style: GoogleFonts.dmMono(fontSize: 11, color: theme.colorScheme.onSurface),
            ),
            const Spacer(),
            if (progress.status == 'pulling')
              GestureDetector(
                onTap: () {}, // Cancel would need stream cancellation
                child: Text(
                  'Cancel',
                  style: GoogleFonts.dmMono(fontSize: 10, color: Colors.redAccent.withValues(alpha: 0.7)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (progress.percent != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: LinearProgressIndicator(
              value: progress.percent,
              minHeight: 2,
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
      ],
    );
  }
}
