import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/lan_scanner_provider.dart';
import 'providers/ollama_provider.dart';
import 'providers/project_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/connect_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/terminal_screen.dart';
import 'screens/files_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_permission_screen.dart';
import 'widgets/bottom_nav.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => LANScannerProvider()),
        ChangeNotifierProvider(create: (_) => OllamaProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const PaperCodeApp(),
    ),
  );
}

class PaperCodeApp extends StatefulWidget {
  const PaperCodeApp({super.key});

  @override
  State<PaperCodeApp> createState() => _PaperCodeAppState();
}

class _PaperCodeAppState extends State<PaperCodeApp> {
  bool? _onboardingComplete;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final val = await _storage.read(key: 'onboarding_complete');
    if (mounted) {
      setState(() => _onboardingComplete = val == 'true');
    }
  }

  void _finishOnboarding() {
    setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(const Color(0xFFE8FF00), 1.0),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'PaperCode',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: AppTheme.light(themeProvider.accentColor, themeProvider.fontSizeScale),
          darkTheme: AppTheme.dark(themeProvider.accentColor, themeProvider.fontSizeScale),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: _onboardingComplete == true
              ? Consumer<ConnectionProvider>(
                  builder: (context, connection, _) {
                    return connection.localMode || connection.isConnected
                        ? const MainShell()
                        : const ConnectScreen();
                  },
                )
              : OnboardingPermissionScreen(onComplete: _finishOnboarding),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  void _goToChat() {
    setState(() => _currentIndex = 0);
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'DM Mono', fontSize: 12)),
        backgroundColor: const Color(0xFFFF4444),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _showSnackbar(details.exceptionAsString());
    };

    return Scaffold(
      body: Column(
        children: [
          Consumer<ConnectionProvider>(
            builder: (context, conn, _) =>
                conn.isConnecting
                    ? LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : const SizedBox(height: 0),
          ),
          Expanded(
            child: SafeArea(
              top: false,
                  child: IndexedStack(
                index: _currentIndex,
                children: [
                  EditorScreen(onOpenChat: _goToChat),
                  const ChatScreen(),
                  const TerminalScreen(),
                  FilesScreen(onOpenChat: _goToChat),
                  const SettingsScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNav(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
