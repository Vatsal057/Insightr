import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../services/api_service.dart';

class NameScreen extends StatefulWidget {
  final void Function(String username) onComplete;
  const NameScreen({super.key, required this.onComplete});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (name.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final api = ApiService();
      api.setUsername(name);
      await api.register(name);

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.usernameKey, name.toLowerCase());
      await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);

      if (mounted) widget.onComplete(name);
    } catch (e) {
      // If backend is unreachable, still save locally and proceed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.usernameKey, name.toLowerCase());
      await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);
      ApiService().setUsername(name);
      if (mounted) widget.onComplete(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 0.7),
              radius: 1.2,
              colors: [Color(0x30C9A84C), Colors.transparent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: InsightrColors.goldPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFF1A1200), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('Insightr', style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: InsightrColors.textPrimary,
                    )),
                  ]),
                  const Spacer(flex: 2),
                  // Heading
                  Text(
                    "What's your\nname?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 42, fontWeight: FontWeight.w800,
                      letterSpacing: -1, height: 1.1,
                      color: InsightrColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "We'll use this to keep your vault personal.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15, color: InsightrColors.textSecondary, height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Input
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _submit(),
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w600,
                      color: InsightrColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w600,
                        color: InsightrColors.textMuted,
                      ),
                      filled: true,
                      fillColor: const Color(0x0AFFFFFF),
                      border: OutlineInputBorder(
                        borderRadius: InsightrRadii.xlAll,
                        borderSide: const BorderSide(color: Color(0x14FFFFFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: InsightrRadii.xlAll,
                        borderSide: const BorderSide(color: Color(0x14FFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: InsightrRadii.xlAll,
                        borderSide: const BorderSide(color: InsightrColors.goldPrimary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: GoogleFonts.inter(
                      fontSize: 13, color: InsightrColors.red,
                    )),
                  ],
                  const Spacer(flex: 3),
                  // Submit
                  SizedBox(
                    width: 280,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(
                            color: InsightrColors.goldPrimary, strokeWidth: 2,
                          ))
                        : PrimaryButton(
                            label: 'Continue',
                            icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A1200), size: 18),
                            onTap: _submit,
                          ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
