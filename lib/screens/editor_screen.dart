import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/project_provider.dart';
import '../providers/connection_provider.dart';
import '../sources/code_source.dart';
import '../sources/ssh_source.dart';
import '../widgets/file_tree_widget.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/ai_assistant_panel.dart';
import 'server_list_screen.dart';

class EditorScreen extends StatefulWidget {
  final VoidCallback? onOpenChat;

  const EditorScreen({super.key, this.onOpenChat});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  bool _showTree = true;
  bool _showAi = false;

  @override
  void initState() {
    super.initState();
    final project = context.read<ProjectProvider>();
    if (!project.initialized) {
      project.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final project = context.watch<ProjectProvider>();
    final connection = context.watch<ConnectionProvider>();
    final hasRemoteSource = connection.isConnected;

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            isDark: isDark,
            sourceLabel: project.sourceLabel,
            sourceType: project.sourceType,
            showTree: _showTree,
            showAi: _showAi,
            hasRemoteSource: hasRemoteSource,
            onToggleTree: () => setState(() => _showTree = !_showTree),
            onToggleAi: () => setState(() => _showAi = !_showAi),
            onSourceChanged: (type) => _handleSourceChange(context, project, connection, type),
          ),
          Expanded(
            child: project.source == null
                ? _NoSourceState(isDark: isDark, hasRemoteSource: hasRemoteSource)
                : Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (_showTree)
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.35,
                                child: _buildSidePanel(context, isDark, project),
                              ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: _buildEditorPanel(context, isDark, project),
                            ),
                          ],
                        ),
                      ),
                      if (_showAi)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: AIAssistantPanel(),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel(BuildContext context, bool isDark, ProjectProvider project) {
    return Column(
      children: [
        _SourceBadge(sourceType: project.sourceType, isDark: isDark),
        const Divider(height: 1),
        Expanded(
          child: ClipRect(child: FileTreeWidget()),
        ),
      ],
    );
  }

  Widget _buildEditorPanel(BuildContext context, bool isDark, ProjectProvider project) {
    final activeTab = project.activeTab;
    final openTabs = project.openTabs;

    if (openTabs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 48,
              color: isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a file to edit',
              style: GoogleFonts.dmMono(
                fontSize: 13,
                color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _TabBar(
          tabs: openTabs,
          activeIndex: project.activeTabIndex,
          isDark: isDark,
          onSelect: (i) => project.setActiveTab(i),
          onClose: (i) => _confirmClose(context, project, i),
          onSave: (i) => project.saveTab(i),
        ),
        const Divider(height: 1),
        Expanded(
          child: activeTab != null
              ? CodeEditorWidget(
                  key: ValueKey(activeTab.path + activeTab.content.length.toString()),
                  content: activeTab.content,
                  language: _languageFromPath(activeTab.path),
                  editable: project.sourceType != SourceType.github,
                  onChanged: (val) {
                    final idx = project.activeTabIndex;
                    if (idx >= 0) {
                      project.updateTabContent(idx, val);
                    }
                  },
                )
              : const SizedBox(),
        ),
        if (activeTab != null)
          _StatusBar(
            isDark: isDark,
            path: activeTab.path,
            isDirty: activeTab.isDirty,
            language: _languageFromPath(activeTab.path),
          ),
      ],
    );
  }

  void _handleSourceChange(
    BuildContext context,
    ProjectProvider project,
    ConnectionProvider connection,
    SourceType? type,
  ) {
    switch (type) {
      case SourceType.local:
        project.setLocalSource();
      case SourceType.ssh:
        if (connection.isConnected && connection.client != null) {
          project.setSSHSource(SSHSource(
            connection.client!,
            host: connection.host,
          ));
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServerListScreen()),
          );
        }
      case SourceType.github:
        _showGitHubDialog(context, project);
      default:
        break;
    }
  }

  void _showGitHubDialog(BuildContext context, ProjectProvider project) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ownerController = TextEditingController();
    final repoController = TextEditingController();
    final tokenController = TextEditingController();

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
                'Open GitHub Repository',
                style: GoogleFonts.dmMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ownerController,
                style: GoogleFonts.dmMono(fontSize: 13, color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Owner (e.g. flutter)',
                  hintStyle: GoogleFonts.dmMono(fontSize: 12, color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repoController,
                style: GoogleFonts.dmMono(fontSize: 13, color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Repository (e.g. flutter)',
                  hintStyle: GoogleFonts.dmMono(fontSize: 12, color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenController,
                obscureText: true,
                style: GoogleFonts.dmMono(fontSize: 13, color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Token (optional, for private repos)',
                  hintStyle: GoogleFonts.dmMono(fontSize: 12, color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: () {
                    final owner = ownerController.text.trim();
                    final repo = repoController.text.trim();
                    if (owner.isNotEmpty && repo.isNotEmpty) {
                      project.setGitHubSource(
                        owner: owner,
                        repo: repo,
                        token: tokenController.text.trim().isNotEmpty ? tokenController.text.trim() : null,
                      );
                      Navigator.of(ctx).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: const Color(0xFF0A0A0A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    'Open Repository',
                    style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClose(BuildContext context, ProjectProvider project, int index) async {
    final tab = project.openTabs[index];
    if (tab.hasUnsavedChanges) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
          title: Text(
            'Unsaved Changes',
            style: GoogleFonts.dmMono(fontSize: 13, color: theme.colorScheme.onSurface),
          ),
          content: Text(
            'Save changes to ${tab.name}?',
            style: GoogleFonts.dmMono(fontSize: 11, color: isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: Text('Cancel', style: GoogleFonts.dmMono(fontSize: 11)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('discard'),
              child: Text('Discard', style: GoogleFonts.dmMono(fontSize: 11, color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('save'),
              child: Text('Save', style: GoogleFonts.dmMono(fontSize: 11)),
            ),
          ],
        ),
      );
      if (result == 'save') {
        await project.saveTab(index);
      }
      if (result != 'cancel') {
        project.closeTab(index);
      }
    } else {
      project.closeTab(index);
    }
  }

  String _languageFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart': return 'dart';
      case 'py': return 'python';
      case 'js':
      case 'jsx': return 'javascript';
      case 'ts':
      case 'tsx': return 'typescript';
      case 'java': return 'java';
      case 'kt': return 'kotlin';
      case 'swift': return 'swift';
      case 'go': return 'go';
      case 'rs': return 'rust';
      case 'rb': return 'ruby';
      case 'php': return 'php';
      case 'c':
      case 'cpp':
      case 'h':
      case 'hpp': return 'cpp';
      case 'cs': return 'csharp';
      case 'html': return 'html';
      case 'css': return 'css';
      case 'json': return 'json';
      case 'yaml':
      case 'yml': return 'yaml';
      case 'md': return 'markdown';
      case 'xml': return 'xml';
      case 'sh':
      case 'bash': return 'bash';
      case 'sql': return 'sql';
      default: return 'dart';
    }
  }
}

class _TopBar extends StatelessWidget {
  final bool isDark;
  final String sourceLabel;
  final SourceType? sourceType;
  final bool showTree;
  final bool showAi;
  final bool hasRemoteSource;
  final VoidCallback onToggleTree;
  final VoidCallback onToggleAi;
  final ValueChanged<SourceType> onSourceChanged;

  const _TopBar({
    required this.isDark,
    required this.sourceLabel,
    required this.sourceType,
    required this.showTree,
    required this.showAi,
    required this.hasRemoteSource,
    required this.onToggleTree,
    required this.onToggleAi,
    required this.onSourceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          GestureDetector(
            onTap: onToggleTree,
            child: Icon(
              showTree ? Icons.pan_tool_alt_outlined : Icons.menu_open_outlined,
              size: 16,
              color: accent,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showSourcePicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForSource(sourceType),
                    size: 12,
                    color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sourceLabel,
                    style: GoogleFonts.dmMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onToggleAi,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: showAi ? accent.withValues(alpha: 0.15) : null,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: showAi ? accent : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'AI',
                    style: GoogleFonts.dmMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: showAi ? accent : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForSource(SourceType? type) {
    switch (type) {
      case SourceType.local: return Icons.phone_android_outlined;
      case SourceType.ssh: return Icons.dns_outlined;
      case SourceType.github: return Icons.code;
      default: return Icons.folder_outlined;
    }
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
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
                  'Code Source',
                  style: GoogleFonts.dmMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              _sourceOption(ctx, Icons.phone_android_outlined, 'Local Storage', SourceType.local, 'Files on this device'),
              _sourceOption(ctx, Icons.dns_outlined, 'SSH Server', SourceType.ssh, hasRemoteSource ? 'Connected server' : 'Connect to a server'),
              _sourceOption(ctx, Icons.code, 'GitHub', SourceType.github, 'Browse a repository'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption(BuildContext ctx, IconData icon, String label, SourceType type, String subtitle) {
    final isActive = sourceType == type;
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.of(ctx).pop();
        onSourceChanged(type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final SourceType? sourceType;
  final bool isDark;

  const _SourceBadge({required this.sourceType, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(
            _icon(),
            size: 11,
            color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
          ),
          const SizedBox(width: 4),
          Text(
            _label(),
            style: GoogleFonts.dmMono(
              fontSize: 9,
              color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    switch (sourceType) {
      case SourceType.local: return Icons.phone_android_outlined;
      case SourceType.ssh: return Icons.dns_outlined;
      case SourceType.github: return Icons.code;
      default: return Icons.folder_outlined;
    }
  }

  String _label() {
    switch (sourceType) {
      case SourceType.local: return 'LOCAL';
      case SourceType.ssh: return 'SSH';
      case SourceType.github: return 'GITHUB';
      default: return '';
    }
  }
}

class _TabBar extends StatelessWidget {
  final List tabs;
  final int activeIndex;
  final bool isDark;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;
  final ValueChanged<int> onSave;

  const _TabBar({
    required this.tabs,
    required this.activeIndex,
    required this.isDark,
    required this.onSelect,
    required this.onClose,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index] as dynamic;
          final isActive = index == activeIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 160),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF))
                    : null,
                border: Border(
                  right: BorderSide(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 11,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : (isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      tab.name,
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        color: isActive
                            ? (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333))
                            : (isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tab.isDirty)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onClose(index),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final bool isDark;
  final String path;
  final bool isDirty;
  final String language;

  const _StatusBar({
    required this.isDark,
    required this.path,
    required this.isDirty,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F0),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            language.toUpperCase(),
            style: GoogleFonts.dmMono(
              fontSize: 9,
              color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
            ),
          ),
          const Spacer(),
          if (isDirty)
            Text(
              'unsaved',
              style: GoogleFonts.dmMono(
                fontSize: 9,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            path.split('/').last,
            style: GoogleFonts.dmMono(
              fontSize: 9,
              color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSourceState extends StatelessWidget {
  final bool isDark;
  final bool hasRemoteSource;

  const _NoSourceState({required this.isDark, required this.hasRemoteSource});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose a code source to begin',
            style: GoogleFonts.dmMono(
              fontSize: 13,
              color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Local · SSH · GitHub',
            style: GoogleFonts.dmMono(
              fontSize: 11,
              color: isDark ? const Color(0xFF444444) : const Color(0xFFBBBBBB),
            ),
          ),
        ],
      ),
    );
  }
}
