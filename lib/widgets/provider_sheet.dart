import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/ollama_provider.dart';

void showProviderSheet(
  BuildContext context,
  AIProviderType currentType,
  void Function(AIProviderType) onSelect,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final accent = Theme.of(context).colorScheme.primary;
  final conn = context.read<ConnectionProvider>();
  final ollamaProvider = context.read<OllamaProvider>();
  final ollamaTipVisible = ValueNotifier(false);

  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    'AI Provider',
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                ),
                ...AIProvider.all.map((provider) {
                  final isSelected = provider.type == currentType;
                  final hasKey = conn.hasApiKey(provider.type);
                  final isOllama = provider.type == AIProviderType.ollama;
                  final ollamaReachable = ollamaProvider.isReachable;

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (isOllama && ollamaReachable != true) {
                            setSheetState(() => ollamaTipVisible.value = !ollamaTipVisible.value);
                          } else {
                            onSelect(provider.type);
                            Navigator.of(ctx).pop();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSelected)
                                Container(
                                  width: 3,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )
                              else
                                const SizedBox(width: 13),
                              Column(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: provider.requiresApiKey
                                          ? (hasKey
                                              ? const Color(0xFF44FF88)
                                              : const Color(0xFFFF4444))
                                          : provider.dotColor,
                                    ),
                                  ),
                                  if (!provider.requiresApiKey)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '—',
                                        style: GoogleFonts.dmMono(
                                          fontSize: 7,
                                          color: const Color(0xFF555555),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          provider.name,
                                          style: GoogleFonts.dmMono(
                                            fontSize: 13,
                                            color: isSelected
                                                ? (isDark
                                                    ? const Color(0xFFE8E8E0)
                                                    : const Color(0xFF1A1A1A))
                                                : (isDark
                                                    ? const Color(0xFF888888)
                                                    : const Color(0xFF666666)),
                                          ),
                                        ),
                                        if (provider.isFree) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF44FF88)
                                                  .withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              'FREE',
                                              style: GoogleFonts.dmMono(
                                                fontSize: 7,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF44FF88),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (isOllama) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: ollamaReachable == true
                                                  ? const Color(0xFF44FF88).withValues(alpha: 0.15)
                                                  : const Color(0xFF555555).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              ollamaReachable == true ? 'RUNNING' : 'OFFLINE',
                                              style: GoogleFonts.dmMono(
                                                fontSize: 7,
                                                fontWeight: FontWeight.w600,
                                                color: ollamaReachable == true
                                                    ? const Color(0xFF44FF88)
                                                    : const Color(0xFF555555),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      provider.baseUrl.isNotEmpty
                                          ? provider.baseUrl
                                          : '(user defined)',
                                      style: GoogleFonts.dmMono(
                                        fontSize: 9,
                                        color: isDark
                                            ? const Color(0xFF555555)
                                            : const Color(0xFFAAAAAA),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      provider.rateLimit,
                                      style: GoogleFonts.dmMono(
                                        fontSize: 8,
                                        color: isDark
                                            ? const Color(0xFF444444)
                                            : const Color(0xFFBBBBBB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isOllama && ollamaTipVisible.value && ollamaReachable != true)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ollamaReachable == false
                                    ? 'Not detected. Start Ollama on your device or LAN machine.'
                                    : 'Check connection to verify Ollama status.',
                                style: GoogleFonts.dmMono(
                                  fontSize: 10,
                                  color: isDark
                                      ? const Color(0xFF666666)
                                      : const Color(0xFF999999),
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  onSelect(provider.type);
                                },
                                child: Text(
                                  'Manage Ollama \u2192',
                                  style: GoogleFonts.dmMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      );
    },
  );
}
