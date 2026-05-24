import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/connection_provider.dart';

class OnboardingPermissionScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPermissionScreen({super.key, required this.onComplete});

  @override
  State<OnboardingPermissionScreen> createState() =>
      _OnboardingPermissionScreenState();
}

class _OnboardingPermissionScreenState
    extends State<OnboardingPermissionScreen> {
  final _storage = const FlutterSecureStorage();
  int _selected = 1; // default: askMe

  final _options = [
    {
      'title': 'Read Only',
      'desc': 'AI can view files but never execute commands',
      'value': 'readOnly',
    },
    {
      'title': 'Ask Me',
      'desc': 'AI suggests commands, you approve each one',
      'value': 'askMe',
    },
    {
      'title': 'Full Access',
      'desc': 'AI can run any command without confirmation',
      'value': 'fullAccess',
    },
  ];

  void _continue() {
    final provider = context.read<ConnectionProvider>();
    final val = _options[_selected];
    final level = PermissionLevel.values.firstWhere(
      (e) => e.name == val['value'],
    );
    provider.setPermissionLevel(level);
    _storage.write(key: 'onboarding_complete', value: 'true');
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Text(
                'PaperCode',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmMono(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'your vps. your ai. your terminal.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: const Color(0xFF666666),
                ),
              ),
              const Spacer(flex: 2),
              Text(
                'AI Access Level',
                style: GoogleFonts.dmMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFCCCCCC),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Control what the AI can do on your server.',
                style: GoogleFonts.dmMono(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 28),
              ...List.generate(_options.length, (i) {
                final opt = _options[i];
                final isSelected = _selected == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent.withValues(alpha: 0.1)
                            : const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? accent : const Color(0xFF2A2A2A),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? accent : const Color(0xFF555555),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['title']!,
                                  style: GoogleFonts.dmMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFFE8E8E0)
                                        : const Color(0xFF888888),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt['desc']!,
                                  style: GoogleFonts.dmMono(
                                    fontSize: 10,
                                    color: const Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(flex: 3),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF0A0A0A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'Continue →',
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
