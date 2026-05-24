import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/connection_provider.dart';
import '../models/server_profile.dart';
import 'add_server_screen.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ConnectionProvider>().loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final provider = context.watch<ConnectionProvider>();
    final profiles = provider.profiles;
    final connectedId = provider.activeProfile?.id;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    'Servers',
                    style: GoogleFonts.dmMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (provider.isConnecting)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddServerScreen()),
                    ),
                    child: Icon(Icons.add, size: 20, color: accent),
                  ),
                ],
              ),
            ),
            Expanded(
              child: profiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No servers yet',
                            style: GoogleFonts.dmMono(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddServerScreen()),
                            ),
                            child: Icon(Icons.add_circle_outline, size: 40, color: accent),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: profiles.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 0,
                        indent: 16,
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                      ),
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        final isConnected = profile.id == connectedId && provider.isConnected;
                        final timeStr = _formatTime(profile.lastConnected);

                        return Dismissible(
                          key: ValueKey(profile.id),
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
                                title: Text(
                                  'Delete "${profile.name}"?',
                                  style: GoogleFonts.dmMono(fontSize: 13, color: theme.colorScheme.onSurface),
                                ),
                                content: Text(
                                  'This cannot be undone.',
                                  style: GoogleFonts.dmMono(fontSize: 11, color: isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text('Cancel', style: GoogleFonts.dmMono(fontSize: 11)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: Text('Delete', style: GoogleFonts.dmMono(fontSize: 11, color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) => provider.deleteProfile(profile.id),
                          child: GestureDetector(
                            onTap: () => isConnected ? null : provider.connectToProfile(profile),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isConnected
                                          ? const Color(0xFF44FF88)
                                          : (isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.name,
                                          style: GoogleFonts.dmMono(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${profile.host}:${profile.port}',
                                          style: GoogleFonts.dmMono(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: profile.type == ServerType.local
                                          ? const Color(0xFF00F5FF).withValues(alpha: 0.15)
                                          : accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      profile.type == ServerType.local ? 'LOCAL' : 'REMOTE',
                                      style: GoogleFonts.dmMono(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: profile.type == ServerType.local
                                            ? const Color(0xFF00F5FF)
                                            : accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeStr,
                                    style: GoogleFonts.dmMono(
                                      fontSize: 9,
                                      color: isDark ? const Color(0xFF444444) : const Color(0xFFBBBBBB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddServerScreen()),
        ),
        backgroundColor: accent,
        foregroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.add, size: 22),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
