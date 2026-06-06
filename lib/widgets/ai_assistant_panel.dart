import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../providers/project_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/ollama_provider.dart';
import '../services/ai_service.dart';
import '../exceptions/ai_service_exception.dart';
import 'confirm_command_sheet.dart';

class _ChatMessage {
  final String role;
  String content;
  final DateTime timestamp;
  bool streaming;

  _ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.streaming = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIAssistantPanel extends StatefulWidget {
  const AIAssistantPanel({super.key});

  @override
  State<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel> {
  final List<_ChatMessage> _messages = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isWaiting = false;
  String? _errorMessage;
  StreamSubscription<String>? _streamSub;

  @override
  void dispose() {
    _streamSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _buildSystemPrompt(ProjectProvider project) {
    final activeTab = project.activeTab;
    var prompt =
        'You are PaperCode AI, a coding assistant embedded in a mobile code editor. '
        'Help the user write, debug, and refactor code. '
        'When providing code changes, output the complete file content inside a code block '
        'with the language specified (e.g. ```dart ... ```). '
        'When providing a terminal command, output it inside a shell code block '
        '(e.g. ```sh ... ```) so the user can review and run it. '
        'The user can apply your code changes directly to their open file. '
        'Be concise and technical.';

    if (activeTab != null) {
      prompt +=
          '\n\nCurrently open file: ${activeTab.path}\n'
          'Language: ${_languageFromPath(activeTab.path)}\n'
          'File contents:\n```\n${activeTab.content}\n```\n'
          'When the user asks you to change this file, output the COMPLETE new file contents '
          'in a single code block so it can be applied.';
    }

    return prompt;
  }

  String _languageFromPath(String path) {
    return path.split('.').last.toLowerCase();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isWaiting) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text.trim()));
      _isWaiting = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    final conn = context.read<ConnectionProvider>();
    if (!conn.activeProviderHasKey) {
      final err = conn.providerValidationError ?? 'No API key configured';
      setState(() {
        _errorMessage = '⚠ $err';
        _isWaiting = false;
      });
      return;
    }

    try {
      final ollamaProvider = context.read<OllamaProvider>();
      final aiService = AIService.fromProvider(conn, ollama: ollamaProvider);
      final project = context.read<ProjectProvider>();

      final history = _messages
          .where((m) => !m.streaming)
          .map(
            (m) => {
              'role': m.role == 'user' ? 'user' : 'assistant',
              'content': m.content,
            },
          )
          .toList();

      final systemPrompt = _buildSystemPrompt(project);
      final stream = await aiService.sendMessage(
        history: history,
        systemPrompt: systemPrompt,
      );

      final msgIndex = _messages.length;
      _messages.add(
        _ChatMessage(role: 'assistant', content: '', streaming: true),
      );

      _streamSub = stream.listen(
        (chunk) {
          if (!mounted) return;
          setState(() {
            _messages[msgIndex].content += chunk;
          });
          _scrollToBottom();
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _messages[msgIndex].streaming = false;
            _isWaiting = false;
          });
        },
        onError: (e) {
          if (!mounted) return;
          if (_messages.length > msgIndex &&
              _messages[msgIndex].content.isEmpty) {
            _messages.removeAt(msgIndex);
          } else if (_messages.length > msgIndex) {
            _messages[msgIndex].streaming = false;
          }
          setState(() {
            _errorMessage = e is AIServiceException
                ? e.toString()
                : 'Error: $e';
            _isWaiting = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e is AIServiceException ? e.toString() : 'Error: $e';
        _isWaiting = false;
      });
    }

    _scrollToBottom();
  }

  void _applyCodeChanges(String code, String path) {
    final project = context.read<ProjectProvider>();
    final idx = project.activeTabIndex;
    if (idx < 0) return;

    project.updateTabContent(idx, code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied to ${path.split('/').last}',
          style: const TextStyle(fontFamily: 'DM Mono', fontSize: 12),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Future<void> _runCommandFromBlock(String command) async {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          role: 'user',
          content: 'Run command\n```sh\n$trimmed\n```',
        ),
      );
      _errorMessage = null;
    });
    _scrollToBottom();

    try {
      final provider = context.read<ConnectionProvider>();
      final output = await provider.runCommand(
        trimmed,
        onConfirm: (cmd) => showConfirmCommandSheet(context, cmd),
      );

      setState(() {
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            content:
                'Command output\n```text\n${output.isEmpty ? '(no output)' : output}\n```',
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            content: 'Command failed\n```text\n$e\n```',
          ),
        );
      });
    }

    _scrollToBottom();
  }

  List<_CodeBlock> _parseCodeBlocks(String text) {
    final blocks = <_CodeBlock>[];
    final regex = RegExp(r'```(\w*)\n(.*?)```', dotAll: true);
    for (final match in regex.allMatches(text)) {
      blocks.add(
        _CodeBlock(
          language: match.group(1) ?? '',
          code: match.group(2)?.trim() ?? '',
        ),
      );
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F0),
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
                Icons.auto_awesome,
                size: 13,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'AI Assistant',
                style: GoogleFonts.dmMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFF333333),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _messages.clear();
                    _errorMessage = null;
                  });
                },
                child: Icon(
                  Icons.add_circle_outline,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF666666)
                      : const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty && !_isWaiting
              ? _EmptyState(isDark: isDark)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _MessageBubble(
                      message: msg,
                      isDark: isDark,
                      theme: theme,
                      onApply: msg.role == 'assistant' && !msg.streaming
                          ? (code) {
                              final project = context.read<ProjectProvider>();
                              final tab = project.activeTab;
                              if (tab != null) {
                                _applyCodeChanges(code, tab.path);
                              }
                            }
                          : null,
                      onRunCommand: msg.role == 'assistant' && !msg.streaming
                          ? _runCommandFromBlock
                          : null,
                      codeBlocks: msg.role == 'assistant' && !msg.streaming
                          ? _parseCodeBlocks(msg.content)
                          : [],
                    );
                  },
                ),
        ),
        if (_errorMessage != null)
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(
            8,
            4,
            4,
            MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE0E0E0),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  enabled: !_isWaiting,
                  style: GoogleFonts.dmMono(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Ask AI to edit code...',
                    hintStyle: GoogleFonts.dmMono(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF555555)
                          : const Color(0xFFAAAAAA),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                  ),
                  onSubmitted: (_) => sendMessage(_inputController.text),
                ),
              ),
              GestureDetector(
                onTap: _isWaiting
                    ? null
                    : () => sendMessage(_inputController.text),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _isWaiting
                        ? (isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE0E0E0))
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    size: 14,
                    color: _isWaiting
                        ? (isDark
                              ? const Color(0xFF666666)
                              : const Color(0xFF999999))
                        : const Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CodeBlock {
  final String language;
  final String code;
  _CodeBlock({required this.language, required this.code});
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 28,
              color: isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask AI to help with your code',
              style: GoogleFonts.dmMono(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF555555)
                    : const Color(0xFFAAAAAA),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"Add error handling" or "Refactor this function"',
              style: GoogleFonts.dmMono(
                fontSize: 10,
                color: isDark
                    ? const Color(0xFF444444)
                    : const Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;
  final ThemeData theme;
  final void Function(String code)? onApply;
  final void Function(String command)? onRunCommand;
  final List<_CodeBlock> codeBlocks;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.theme,
    this.onApply,
    this.onRunCommand,
    required this.codeBlocks,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isUser && message.content.isNotEmpty) _buildContent(context),
          if (isUser)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                message.content,
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
            ),
          if (message.streaming)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '▌',
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          if (!message.streaming)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                timeStr,
                style: GoogleFonts.dmMono(
                  fontSize: 8,
                  color: isDark
                      ? const Color(0xFF444444)
                      : const Color(0xFFCCCCCC),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final parts = <Widget>[];
    int blockIdx = 0;
    final textSegments = message.content.split(RegExp(r'(?=```)'));

    for (final seg in textSegments) {
      if (seg.startsWith('```')) {
        if (blockIdx < codeBlocks.length) {
          final block = codeBlocks[blockIdx];
          parts.add(
            _CodeBlockWidget(
              code: block.code,
              language: block.language,
              isDark: isDark,
              onApply: onApply != null && _isApplicableCode(block)
                  ? () => onApply!(block.code)
                  : null,
              onRun: onRunCommand != null && _isRunnableCommand(block)
                  ? () => onRunCommand!(block.code)
                  : null,
            ),
          );
          blockIdx++;
        }
      } else if (seg.trim().isNotEmpty) {
        parts.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF141414)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                seg.trim(),
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  height: 1.3,
                  color: isDark
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  bool _isRunnableCommand(_CodeBlock block) {
    final lang = block.language.toLowerCase();
    const commandLanguages = {
      'bash',
      'sh',
      'shell',
      'zsh',
      'terminal',
      'console',
    };
    return commandLanguages.contains(lang);
  }

  bool _isApplicableCode(_CodeBlock block) {
    final lang = block.language.toLowerCase();
    const nonFileLanguages = {
      'bash',
      'console',
      'diff',
      'log',
      'output',
      'patch',
      'sh',
      'shell',
      'terminal',
      'text',
      'txt',
      'zsh',
    };
    return !nonFileLanguages.contains(lang);
  }
}

class _CodeBlockWidget extends StatefulWidget {
  final String code;
  final String language;
  final bool isDark;
  final VoidCallback? onApply;
  final VoidCallback? onRun;

  const _CodeBlockWidget({
    required this.code,
    required this.language,
    required this.isDark,
    this.onApply,
    this.onRun,
  });

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF050505)
              : const Color(0xFFE8E8E0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
              child: Row(
                children: [
                  if (widget.language.isNotEmpty)
                    Text(
                      widget.language,
                      style: GoogleFonts.dmMono(
                        fontSize: 9,
                        color: widget.isDark
                            ? const Color(0xFF555555)
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
              child: Text(
                widget.code,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  height: 1.3,
                  color: widget.isDark
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  if (widget.onApply != null)
                    _CodeActionButton(
                      icon: Icons.file_download_done_outlined,
                      label: 'Apply',
                      isPrimary: true,
                      isDark: widget.isDark,
                      onTap: widget.onApply!,
                    ),
                  if (widget.onRun != null)
                    _CodeActionButton(
                      icon: Icons.play_arrow_outlined,
                      label: 'Run',
                      isPrimary: true,
                      isDark: widget.isDark,
                      onTap: widget.onRun!,
                    ),
                  _CodeActionButton(
                    icon: _copied ? Icons.check : Icons.copy_outlined,
                    label: _copied ? 'Copied' : 'Copy',
                    isPrimary: false,
                    isDark: widget.isDark,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.code));
                      setState(() => _copied = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _copied = false);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isDark;
  final VoidCallback onTap;

  const _CodeActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isPrimary ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isPrimary
                ? accent
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFCFCFC7)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isPrimary
                  ? const Color(0xFF0A0A0A)
                  : (isDark
                        ? const Color(0xFF888888)
                        : const Color(0xFF666666)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmMono(
                fontSize: 10,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                color: isPrimary
                    ? const Color(0xFF0A0A0A)
                    : (isDark
                          ? const Color(0xFF888888)
                          : const Color(0xFF666666)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
