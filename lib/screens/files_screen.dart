import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../providers/connection_provider.dart';

class _FileEntry {
  final String name;
  final String fullPath;
  final bool isDirectory;
  final int? size;
  final String permissions;

  _FileEntry({
    required this.name,
    required this.fullPath,
    required this.isDirectory,
    this.size,
    required this.permissions,
  });
}

class FilesScreen extends StatefulWidget {
  final VoidCallback? onOpenChat;

  const FilesScreen({super.key, this.onOpenChat});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _currentPath = '/root';
  List<_FileEntry> _allEntries = [];
  bool _loading = true;
  String? _error;
  bool _showDotfiles = false;

  List<_FileEntry> get _entries =>
      _showDotfiles ? _allEntries : _allEntries.where((e) => !e.name.startsWith('.')).toList();

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory({String? path}) async {
    if (path != null) _currentPath = path;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = context.read<ConnectionProvider>().client;
      if (client == null) throw Exception('Not connected.');
      final result = await client.run('ls -la "$_currentPath"');
      final output = utf8.decode(result);
      _allEntries = _parseLsOutput(output);
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  List<_FileEntry> _parseLsOutput(String output) {
    final entries = <_FileEntry>[];
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.isEmpty || line.startsWith('total ')) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 8) continue;

      final permissions = parts[0];
      if (permissions.length < 10) continue;

      final isDir = permissions[0] == 'd';
      final isLink = permissions[0] == 'l';
      final size = int.tryParse(parts[4]);
      final name = parts.sublist(8).join(' ');

      if (name == '.' || name == '..') continue;

      final path = '$_currentPath/$name';

      entries.add(_FileEntry(
        name: name,
        fullPath: path,
        isDirectory: isDir || isLink,
        size: isDir ? null : size,
        permissions: permissions,
      ));
    }

    entries.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  void _navigateToFolder(_FileEntry entry) {
    _loadDirectory(path: entry.fullPath);
  }

  void _goUp() {
    if (_currentPath == '/root') return;
    final parent = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
    _loadDirectory(path: parent.isEmpty ? '/' : parent);
  }

  void _toggleDotfiles() {
    setState(() => _showDotfiles = !_showDotfiles);
  }

  void _showFileActions(_FileEntry entry) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  entry.name,
                  style: GoogleFonts.dmMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.isDirectory)
                _actionTile(ctx, Icons.folder_open_outlined, 'Open', () {
                  Navigator.of(ctx).pop();
                  _navigateToFolder(entry);
                })
              else ...[
                _actionTile(ctx, Icons.visibility_outlined, 'View', () {
                  Navigator.of(ctx).pop();
                  _openFile(entry);
                }),
                _actionTile(ctx, Icons.send_outlined, 'Send to Chat', () {
                  final provider = context.read<ConnectionProvider>();
                  provider.setActiveFile(entry.fullPath, '');
                  widget.onOpenChat?.call();
                  Navigator.of(ctx).pop();
                }),
              ],
              _actionTile(ctx, Icons.copy_outlined, 'Copy Path', () {
                Clipboard.setData(ClipboardData(text: entry.fullPath));
                HapticFeedback.lightImpact();
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Path copied', style: TextStyle(fontFamily: 'DM Mono', fontSize: 12)),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFile(_FileEntry entry) async {
    if (entry.isDirectory) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) => _FileViewer(
        entry: entry,
        onSendToChat: () {
          final provider = context.read<ConnectionProvider>();
          provider.setActiveFile(entry.fullPath, '');
          widget.onOpenChat?.call();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _BreadcrumbBar(
            path: _currentPath,
            isDark: isDark,
            onTap: (path) => _loadDirectory(path: path),
            onToggleDotfiles: _toggleDotfiles,
            showDotfiles: _showDotfiles,
          ),
          Expanded(
            child: _buildBody(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: GoogleFonts.dmMono(fontSize: 12, color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_entries.isEmpty)
          Center(
            child: Text(
              'Empty directory',
              style: GoogleFonts.dmMono(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          )
        else
          RefreshIndicator(
            onRefresh: () => _loadDirectory(),
            color: theme.colorScheme.primary,
            backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _entries.length,
              separatorBuilder: (_, _) => Divider(
                height: 0,
                indent: 52,
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE0E0E0),
              ),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return _FileRow(
                  entry: entry,
                  theme: theme,
                  isDark: isDark,
                  onTap: () => entry.isDirectory
                      ? _navigateToFolder(entry)
                      : _openFile(entry),
                  onLongPress: () => _showFileActions(entry),
                );
              },
            ),
          ),
        if (_currentPath != '/root')
          Positioned(
            left: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              heroTag: 'back',
              backgroundColor: isDark
                  ? const Color(0xFF141414)
                  : const Color(0xFFFFFFFF),
              foregroundColor: isDark
                  ? const Color(0xFF666666)
                  : const Color(0xFF999999),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE0E0E0),
                ),
              ),
              onPressed: _goUp,
              child: const Icon(Icons.arrow_upward, size: 18),
            ),
          ),
      ],
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  final String path;
  final bool isDark;
  final void Function(String path) onTap;
  final VoidCallback onToggleDotfiles;
  final bool showDotfiles;

  const _BreadcrumbBar({
    required this.path,
    required this.isDark,
    required this.onTap,
    required this.onToggleDotfiles,
    required this.showDotfiles,
  });

  @override
  Widget build(BuildContext context) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

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
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: segments.length,
              separatorBuilder: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '/',
                  style: GoogleFonts.dmMono(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
                  ),
                ),
              ),
              itemBuilder: (context, index) {
                final segPath = '/${segments.take(index + 1).join('/')}';
                final isLast = index == segments.length - 1;
                return GestureDetector(
                  onTap: isLast ? null : () => onTap(segPath),
                  child: Center(
                    child: Text(
                      segments[index],
                      style: GoogleFonts.dmMono(
                        fontSize: 12,
                        fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                        color: isLast
                            ? (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333))
                            : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
                        decoration: isLast ? null : TextDecoration.underline,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          GestureDetector(
            onTap: onToggleDotfiles,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                showDotfiles ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 16,
                color: showDotfiles
                    ? (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333))
                    : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final _FileEntry entry;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FileRow({
    required this.entry,
    required this.theme,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDot = entry.name.startsWith('.');
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              entry.isDirectory ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
              size: 18,
              color: entry.isDirectory
                  ? theme.colorScheme.primary
                  : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.name,
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  color: isDot
                      ? (isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA))
                      : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.size != null)
              Text(
                _formatSize(entry.size!),
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

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _FileViewer extends StatefulWidget {
  final _FileEntry entry;
  final VoidCallback onSendToChat;

  const _FileViewer({required this.entry, required this.onSendToChat});

  @override
  State<_FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<_FileViewer> {
  String? _content;
  bool _loadingContent = true;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final client = context.read<ConnectionProvider>().client;
      if (client == null) throw Exception('Not connected.');
      final result = await client.run('cat "${widget.entry.fullPath}"', runInPty: false);
      _content = utf8.decode(result);
    } catch (e) {
      _contentError = e.toString();
    }
    if (mounted) setState(() => _loadingContent = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.entry.name,
                        style: GoogleFonts.dmMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loadingContent
                    ? const Center(child: CircularProgressIndicator())
                    : _contentError != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _contentError!,
                                style: GoogleFonts.dmMono(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _content ?? '',
                              style: GoogleFonts.dmMono(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: widget.onSendToChat,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: const Color(0xFF0A0A0A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'Send to Chat',
                      style: GoogleFonts.dmMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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
}
