import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../sources/code_source.dart';
import '../providers/project_provider.dart';

class FileTreeWidget extends StatelessWidget {
  const FileTreeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ProjectProvider>();
    final files = provider.currentFiles;
    final loading = provider.loadingFiles;
    final error = provider.error;
    final currentPath = provider.currentDirectory;

    return Column(
      children: [
        _BreadcrumbBar(
          path: currentPath,
          isDark: isDark,
          onTap: (path) => provider.navigateToDirectory(path),
          onGoUp: () => provider.goUp(),
        ),
        Expanded(
          child: _buildBody(context, files, loading, error, isDark, provider),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<FileNode> files,
    bool loading,
    String? error,
    bool isDark,
    ProjectProvider provider,
  ) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error,
            style: GoogleFonts.dmMono(fontSize: 11, color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (files.isEmpty) {
      return Center(
        child: Text(
          'Empty directory',
          style: GoogleFonts.dmMono(
            fontSize: 12,
            color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshFiles(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: files.length,
        separatorBuilder: (_, _) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          final entry = files[index];
          return _FileTreeRow(
            entry: entry,
            isDark: isDark,
            onTap: () {
              if (entry.isDirectory) {
                provider.navigateToDirectory(entry.path);
              } else {
                provider.openFile(entry.path);
              }
            },
          );
        },
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  final String path;
  final bool isDark;
  final void Function(String path) onTap;
  final VoidCallback onGoUp;

  const _BreadcrumbBar({
    required this.path,
    required this.isDark,
    required this.onTap,
    required this.onGoUp,
  });

  @override
  Widget build(BuildContext context) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    return Container(
      height: 38,
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
          if (segments.isNotEmpty)
            GestureDetector(
              onTap: onGoUp,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.arrow_upward,
                  size: 14,
                  color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: segments.length,
              separatorBuilder: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '/',
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
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
                        fontSize: 11,
                        fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                        color: isLast
                            ? (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333))
                            : (isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FileTreeRow extends StatelessWidget {
  final FileNode entry;
  final bool isDark;
  final VoidCallback onTap;

  const _FileTreeRow({
    required this.entry,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDot = entry.name.startsWith('.');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Icon(
              entry.isDirectory ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
              size: 15,
              color: entry.isDirectory
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? const Color(0xFF555555) : const Color(0xFFBBBBBB)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.name,
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: isDot
                      ? (isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA))
                      : Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
