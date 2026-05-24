import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool> showConfirmCommandSheet(BuildContext context, String command) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final accent = Theme.of(context).colorScheme.primary;

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Run Command',
              style: GoogleFonts.dmMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F0EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                command,
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFF666666)
                            : const Color(0xFF999999),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE0E0E0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dmMono(fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: const Color(0xFF0A0A0A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Run it',
                        style: GoogleFonts.dmMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  ).then((r) => r ?? false);
}
