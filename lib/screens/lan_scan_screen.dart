import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/lan_scanner_provider.dart';

class LANScanScreen extends StatefulWidget {
  const LANScanScreen({super.key});

  @override
  State<LANScanScreen> createState() => _LANScanScreenState();
}

class _LANScanScreenState extends State<LANScanScreen> {
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoStarted) {
        _autoStarted = true;
        _startScan();
      }
    });
  }

  void _startScan() {
    context.read<LANScannerProvider>().startScan();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final provider = context.watch<LANScannerProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Local Network',
          style: GoogleFonts.dmMono(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.close, size: 20, color: isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            height: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStatusBar(theme, isDark, accent, provider),
          if (provider.isScanning || provider.progress > 0)
            _buildProgressBar(accent, provider),
          Expanded(
            child: provider.discovered.isEmpty
                ? _buildEmptyState(theme, isDark, accent, provider)
                : _buildResultsList(theme, isDark, accent, provider),
          ),
          if (!provider.isScanning && provider.discovered.isNotEmpty)
            _buildScanAgain(accent, provider),
        ],
      ),
      floatingActionButton: !provider.isScanning && provider.discovered.isEmpty
          ? FloatingActionButton(
              onPressed: _startScan,
              backgroundColor: accent,
              foregroundColor: const Color(0xFF0A0A0A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.wifi_find, size: 22),
            )
          : null,
    );
  }

  Widget _buildStatusBar(ThemeData theme, bool isDark, Color accent, LANScannerProvider provider) {
    String statusText;
    Color textColor;

    if (provider.error != null) {
      statusText = provider.error!;
      textColor = Colors.redAccent;
    } else if (provider.isScanning) {
      final subnet = provider.localIP != null
          ? '${provider.localIP!.split('.').take(3).join('.')}.x'
          : 'local network';
      statusText = 'Scanning $subnet — ${provider.discovered.length} found';
      textColor = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    } else if (provider.discovered.isNotEmpty) {
      statusText = '${provider.discovered.length} device${provider.discovered.length == 1 ? '' : 's'} found';
      textColor = const Color(0xFF44FF88);
    } else if (provider.progress > 0) {
      statusText = 'Scan complete — no devices found';
      textColor = isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA);
    } else {
      statusText = 'Tap scan to find local SSH servers';
      textColor = isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        statusText,
        style: GoogleFonts.dmMono(fontSize: 11, color: textColor),
      ),
    );
  }

  Widget _buildProgressBar(Color accent, LANScannerProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: LinearProgressIndicator(
        value: provider.progress,
        minHeight: 2,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, Color accent, LANScannerProvider provider) {
    if (provider.isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PulseGrid(active: true, accent: accent),
            const SizedBox(height: 24),
            Text(
              'Scanning...',
              style: GoogleFonts.dmMono(
                fontSize: 11,
                color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 32, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmMono(fontSize: 11, color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              _buildRetryButton(accent),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulseGrid(active: false, accent: accent),
          const SizedBox(height: 24),
          Text(
            'No devices found',
            style: GoogleFonts.dmMono(
              fontSize: 11,
              color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton(Color accent) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: _startScan,
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          'Retry',
          style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme, bool isDark, Color accent, LANScannerProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: provider.discovered.length,
      separatorBuilder: (_, _) => Divider(
        height: 0,
        indent: 16,
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      ),
      itemBuilder: (context, index) {
        final host = provider.discovered[index];

        return GestureDetector(
          onTap: () => Navigator.of(context).pop({
            'ip': host.ip,
            'hostname': host.hostname ?? host.ip,
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        host.ip,
                        style: GoogleFonts.dmMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        host.hostname ?? 'Unknown host',
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'LOCAL',
                    style: GoogleFonts.dmMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00F5FF),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${host.responseMs}ms',
                    style: GoogleFonts.dmMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanAgain(Color accent, LANScannerProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: OutlinedButton(
          onPressed: _startScan,
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text(
            'Scan Again',
            style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _PulseGrid extends StatefulWidget {
  final bool active;
  final Color accent;

  const _PulseGrid({required this.active, required this.accent});

  @override
  State<_PulseGrid> createState() => _PulseGridState();
}

class _PulseGridState extends State<_PulseGrid> {
  final List<double> _opacities = List.filled(25, 0.06);
  Timer? _timer;
  final _random = Random();
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _wasActive = widget.active;
    if (widget.active) _startPulsing();
  }

  @override
  void didUpdateWidget(_PulseGrid old) {
    super.didUpdateWidget(old);
    if (widget.active && !_wasActive) {
      _wasActive = true;
      _startPulsing();
    } else if (!widget.active && _wasActive) {
      _wasActive = false;
      _timer?.cancel();
      if (mounted) {
        setState(() => _opacities.fillRange(0, 25, 0.06));
      }
    }
  }

  void _startPulsing() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !widget.active) return;
      setState(() {
        for (int i = 0; i < 3; i++) {
          final idx = _random.nextInt(25);
          _opacities[idx] = 0.3 + _random.nextDouble() * 0.5;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children: List.generate(25, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accent.withValues(alpha: _opacities[i]),
            ),
          );
        }),
      ),
    );
  }
}
