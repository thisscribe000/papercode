import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:google_fonts/google_fonts.dart';

class CodeEditorWidget extends StatefulWidget {
  final String content;
  final String language;
  final bool editable;
  final ValueChanged<String>? onChanged;

  const CodeEditorWidget({
    super.key,
    required this.content,
    this.language = 'dart',
    this.editable = true,
    this.onChanged,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final bool _showHighlighted = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content && !_focusNode.hasFocus) {
      final offset = _controller.selection.baseOffset;
      _controller.text = widget.content;
      if (offset <= _controller.text.length) {
        _controller.selection = TextSelection.collapsed(offset: offset);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        if (_showHighlighted && widget.content.isNotEmpty && !_focusNode.hasFocus)
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: HighlightView(
                widget.content,
                language: _mapLanguage(widget.language),
                theme: isDark ? atomOneDarkTheme : githubTheme,
                padding: const EdgeInsets.all(0),
                textStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                height: 1.5,
                color: _showHighlighted && !_focusNode.hasFocus
                    ? Colors.transparent
                    : (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A)),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                widget.onChanged?.call(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _mapLanguage(String lang) {
    switch (lang) {
      case 'dart':
        return 'dart';
      case 'python':
        return 'python';
      case 'javascript':
        return 'javascript';
      case 'typescript':
        return 'typescript';
      case 'java':
        return 'java';
      case 'kotlin':
        return 'kotlin';
      case 'swift':
        return 'swift';
      case 'go':
        return 'go';
      case 'rust':
        return 'rust';
      case 'ruby':
        return 'ruby';
      case 'php':
        return 'php';
      case 'cpp':
        return 'cpp';
      case 'csharp':
        return 'csharp';
      case 'html':
        return 'html';
      case 'css':
        return 'css';
      case 'json':
        return 'json';
      case 'yaml':
        return 'yaml';
      case 'markdown':
        return 'markdown';
      case 'xml':
        return 'xml';
      case 'bash':
        return 'bash';
      case 'sql':
        return 'sql';
      default:
        return 'dart';
    }
  }
}
