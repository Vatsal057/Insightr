import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/name_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool(AppConstants.hasSeenOnboardingKey) ?? false;
  final savedUsername = prefs.getString(AppConstants.usernameKey) ?? '';

  // Restore username into ApiService if already registered
  if (savedUsername.isNotEmpty) {
    ApiService().setUsername(savedUsername);
  }

  await ApiService().initialize();

  runApp(InsightrApp(
    showOnboarding: !hasSeenOnboarding,
    hasUsername: savedUsername.isNotEmpty,
  ));
}

class InsightrApp extends StatelessWidget {
  final bool showOnboarding;
  final bool hasUsername;
  const InsightrApp({super.key, required this.showOnboarding, required this.hasUsername});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insightr',
      theme: InsightrTheme.theme,
      debugShowCheckedModeBanner: false,
      home: showOnboarding
          ? const _OnboardingFlow()
          : hasUsername
              ? const HomeScreen()
              : _NameOnly(),
    );
  }
}

/// Only shows the name screen (for users who saw onboarding but somehow lack a username).
class _NameOnly extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NameScreen(onComplete: (_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    });
  }
}

/// Manages the 2-screen onboarding flow: Welcome → Name → Home.
class _OnboardingFlow extends StatefulWidget {
  const _OnboardingFlow();

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  int _page = 0;

  void _next() => setState(() => _page++);

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_page) {
      0 => SplashScreen(onComplete: _next),
      _ => NameScreen(onComplete: (_) => _goHome()),
    };
  }
}
