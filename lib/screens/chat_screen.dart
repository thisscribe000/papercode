import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../providers/connection_provider.dart';
import '../providers/ollama_provider.dart';
import '../services/ai_service.dart';
import '../exceptions/ai_service_exception.dart';
import '../widgets/confirm_command_sheet.dart';

class _ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final bool streaming;

  _ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.streaming = false,
  }) : timestamp = timestamp ?? DateTime.now();

  _ChatMessage copyWith({String? content, bool? streaming}) {
    return _ChatMessage(
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      streaming: streaming ?? this.streaming,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isWaiting = false;
  String? _errorMessage;
  StreamSubscription<String>? _streamSub;
  late AnimationController _dotAnimController;

  @override
  void initState() {
    super.initState();
    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _dotAnimController.dispose();
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

  String _buildSystemPrompt(ConnectionProvider provider) {
    var prompt =
        'You are PaperCode, an AI coding assistant with direct access to the '
        'user\'s VPS. You help create, edit, debug, and manage code and projects. '
        'When the user shares a file, you have its full contents as context. '
        'When asked to run commands, respond with the exact command in a code block '
        'and indicate it should be run in the terminal. '
        'Be concise, technical, and direct. No unnecessary explanations unless asked.';

    if (provider.activeFilePath != null &&
        provider.activeFileContents != null &&
        provider.activeFilePath!.isNotEmpty) {
      prompt +=
          '\n\nCurrent file: ${provider.activeFilePath}\nContents:\n${provider.activeFileContents}';
    }

    return prompt;
  }

  void _sendQuickAction(String text) {
    _inputController.text = text;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isWaiting) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _isWaiting = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    final provider = context.read<ConnectionProvider>();
    if (!provider.activeProviderHasKey) {
      final err = provider.providerValidationError ?? 'No API key configured';
      setState(() {
        _errorMessage = '⚠ $err. Go to Settings → AI to add one.';
        _isWaiting = false;
      });
      return;
    }

    try {
      final ollamaProvider = context.read<OllamaProvider>();
      final aiService = AIService.fromProvider(provider, ollama: ollamaProvider);

      final history = _messages
          .where((m) => !m.streaming)
          .map((m) => {'role': m.role == 'user' ? 'user' : 'assistant', 'content': m.content})
          .toList();

      final systemPrompt = _buildSystemPrompt(provider);
      final stream = await aiService.sendMessage(
        history: history,
        systemPrompt: systemPrompt,
      );

      final msgIndex = _messages.length;

      _messages.add(_ChatMessage(role: 'assistant', content: '', streaming: true));

      _streamSub = stream.listen(
        (chunk) {
          if (!mounted) return;
          setState(() {
            _messages[msgIndex] = _messages[msgIndex].copyWith(
              content: _messages[msgIndex].content + chunk,
            );
          });
          _scrollToBottom();
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _messages[msgIndex] = _messages[msgIndex].copyWith(streaming: false);
            _isWaiting = false;
          });
        },
        onError: (e) {
          if (!mounted) return;
          if (_messages.length > msgIndex) {
            final existing = _messages[msgIndex].content;
            if (existing.isEmpty) {
              _messages.removeAt(msgIndex);
            } else {
              _messages[msgIndex] = _messages[msgIndex].copyWith(streaming: false);
            }
          }
          setState(() {
            _errorMessage = e is AIServiceException ? e.toString() : 'Error: $e';
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

  void _newSession() {
    _streamSub?.cancel();
    setState(() {
      _messages.clear();
      _errorMessage = null;
      _isWaiting = false;
    });
    context.read<ConnectionProvider>().setActiveFile('', '');
  }

  Future<void> _runCommand(String command) async {
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: 'Running: $command'));
      _scrollToBottom();
    });

    try {
      final provider = context.read<ConnectionProvider>();
      final output = await provider.runCommand(
        command,
        onConfirm: (cmd) => showConfirmCommandSheet(context, cmd),
      );

      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content:
              'Terminal Output:\n```\n${output.isEmpty ? '(no output)' : output}\n```',
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: 'Terminal Output:\n```\nError: $e\n```',
        ));
      });
    }

    _scrollToBottom();
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied', style: TextStyle(fontFamily: 'DM Mono', fontSize: 12)),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ConnectionProvider>();
    final hasActiveFile = provider.activeFilePath != null &&
        provider.activeFilePath!.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            isDark: isDark,
            onNewSession: _newSession,
            providerName: provider.activeProvider.name,
            providerColor: provider.activeProvider.dotColor,
          ),
          Expanded(
            child: _messages.isEmpty && !_isWaiting
                ? _WelcomeState(
                    isDark: isDark,
                    host: provider.host,
                    onQuickAction: _sendQuickAction,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: _messages.length + (_isWaiting && _messages.lastOrNull?.streaming != true ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        return _TypingIndicator(
                          animController: _dotAnimController,
                          isDark: isDark,
                        );
                      }
                      final msg = _messages[index];
                      return _MessageBubble(
                        message: msg,
                        isDark: isDark,
                        theme: theme,
                        onRunCommand: msg.role == 'assistant' && !msg.streaming
                            ? (cmd) => _runCommand(cmd)
                            : null,
                        onLongPress: () => _copyMessage(msg.content),
                        isLast: index == _messages.length - 1,
                      );
                    },
                  ),
          ),
          if (_errorMessage != null)
            GestureDetector(
              onTap: () => setState(() => _errorMessage = null),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.dmMono(fontSize: 11, color: Colors.redAccent),
                ),
              ),
            ),
          if (hasActiveFile)
            _ActiveFileChip(
              path: provider.activeFilePath!,
              isDark: isDark,
              onDismiss: () => provider.setActiveFile('', ''),
            ),
          _InputBar(
            controller: _inputController,
            focusNode: _focusNode,
            isDark: isDark,
            isWaiting: _isWaiting,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onNewSession;
  final String providerName;
  final Color providerColor;

  const _TopBar({
    required this.isDark,
    required this.onNewSession,
    required this.providerName,
    required this.providerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'PaperCode',
            style: GoogleFonts.dmMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: providerColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            providerName,
            style: GoogleFonts.dmMono(
              fontSize: 9,
              color: isDark ? const Color(0xFF555555) : const Color(0xFFBBBBBB),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onNewSession,
            child: Icon(
              Icons.add_circle_outline,
              size: 18,
              color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeState extends StatelessWidget {
  final bool isDark;
  final String host;
  final void Function(String) onQuickAction;

  const _WelcomeState({
    required this.isDark,
    required this.host,
    required this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PaperCode',
            style: GoogleFonts.dmMono(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connected to $host.',
            style: GoogleFonts.dmMono(
              fontSize: 12,
              color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 24),
          _QuickActionChip(label: 'List my projects', onTap: () => onQuickAction('List my projects')),
          const SizedBox(height: 8),
          _QuickActionChip(label: "What's running?", onTap: () => onQuickAction("What's running?")),
          const SizedBox(height: 8),
          _QuickActionChip(label: 'New project', onTap: () => onQuickAction('New project')),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmMono(
            fontSize: 11,
            color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;
  final ThemeData theme;
  final void Function(String command)? onRunCommand;
  final VoidCallback? onLongPress;
  final bool isLast;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.theme,
    this.onRunCommand,
    this.onLongPress,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final segments = _parseCodeBlocks(message.content);
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: message.streaming ? null : onLongPress,
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                for (final seg in segments)
                  seg.isCode
                      ? _CodeBlock(seg: seg, onRunCommand: onRunCommand)
                      : _TextBlock(seg: seg, isUser: isUser, isDark: isDark, theme: theme),
                if (message.streaming)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: SizedBox(
                      width: 8,
                      child: Text(
                        '▌',
                        style: GoogleFonts.dmMono(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!message.streaming)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                timeStr,
                style: GoogleFonts.dmMono(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF555555) : const Color(0xFFBBBBBB),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_MessageSegment> _parseCodeBlocks(String text) {
    final segments = <_MessageSegment>[];
    final parts = text.split('```');

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      if (i.isOdd) {
        final code = parts[i];
        final lines = code.split('\n');
        final lang = lines.first.trim();
        final content = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
        segments.add(_MessageSegment(
          isCode: true,
          text: content.isNotEmpty ? content : code,
          language: lang,
        ));
      } else {
        segments.add(_MessageSegment(isCode: false, text: parts[i].trim()));
      }
    }

    return segments;
  }
}

class _MessageSegment {
  final bool isCode;
  final String text;
  final String? language;

  _MessageSegment({required this.isCode, required this.text, this.language});
}

class _TextBlock extends StatelessWidget {
  final _MessageSegment seg;
  final bool isUser;
  final bool isDark;
  final ThemeData theme;

  const _TextBlock({
    required this.seg,
    required this.isUser,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : (isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          seg.text,
          style: GoogleFonts.dmMono(
            fontSize: 13,
            height: 1.4,
            color: isUser ? const Color(0xFF0A0A0A) : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatefulWidget {
  final _MessageSegment seg;
  final void Function(String command)? onRunCommand;

  const _CodeBlock({required this.seg, this.onRunCommand});

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF050505) : const Color(0xFFE8E8E0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 6, 0),
                  child: Row(
                    children: [
                      if (widget.seg.language != null &&
                          widget.seg.language!.isNotEmpty)
                        Text(
                          widget.seg.language!,
                          style: GoogleFonts.dmMono(
                            fontSize: 10,
                            color: isDark
                                ? const Color(0xFF666666)
                                : const Color(0xFF999999),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.seg.text));
                          HapticFeedback.lightImpact();
                          setState(() => _copied = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _copied = false);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            _copied ? 'Copied' : 'Copy',
                            style: GoogleFonts.dmMono(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF666666)
                                  : const Color(0xFF999999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: Text(
                    widget.seg.text,
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onRunCommand != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onRunCommand!(widget.seg.text);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFE0E0E0),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.terminal,
                          size: 12,
                          color: isDark
                              ? const Color(0xFF666666)
                              : const Color(0xFF999999),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Run in Terminal',
                          style: GoogleFonts.dmMono(
                            fontSize: 10,
                            color: isDark
                                ? const Color(0xFF666666)
                                : const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final AnimationController animController;
  final bool isDark;

  const _TypingIndicator({
    required this.animController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: AnimatedBuilder(
              animation: animController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Opacity(
                        opacity: ((animController.value + delay) % 1.0) > 0.5
                            ? 1.0
                            : 0.3,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF666666)
                                : const Color(0xFF999999),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFileChip extends StatelessWidget {
  final String path;
  final bool isDark;
  final VoidCallback onDismiss;

  const _ActiveFileChip({
    required this.path,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              path,
              style: GoogleFonts.dmMono(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: 14,
              color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isDark;
  final bool isWaiting;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    this.focusNode,
    required this.isDark,
    required this.isWaiting,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 6, 8, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isWaiting,
              style: GoogleFonts.dmMono(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Ask anything...',
                hintStyle: GoogleFonts.dmMono(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: isWaiting ? null : (_) => onSend(),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: isWaiting ? null : onSend,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isWaiting
                    ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0))
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.arrow_upward,
                size: 16,
                color: isWaiting
                    ? (isDark ? const Color(0xFF666666) : const Color(0xFF999999))
                    : const Color(0xFF0A0A0A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
