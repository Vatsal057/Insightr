import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/feature_screen.dart';
import 'screens/onboarding/vault_onboard_screen.dart';
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

  await ApiService().initialize();

  runApp(InsightrApp(showOnboarding: !hasSeenOnboarding));
}

class InsightrApp extends StatelessWidget {
  final bool showOnboarding;
  const InsightrApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insightr',
      theme: InsightrTheme.theme,
      debugShowCheckedModeBanner: false,
      home: showOnboarding
          ? const _OnboardingFlow()
          : const HomeScreen(),
    );
  }
}

/// Manages the 3-screen onboarding flow before reaching HomeScreen.
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
      1 => FeatureScreen(onContinue: _next),
      _ => VaultOnboardScreen(onComplete: _goHome),
    };
  }
}
