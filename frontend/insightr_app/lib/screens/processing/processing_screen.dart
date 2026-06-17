import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class ProcessingScreen extends StatefulWidget {
  final String url;
  final void Function(int entryId) onCompleted;

  const ProcessingScreen({super.key, required this.url, required this.onCompleted});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  Timer? _timer;
  String? _taskId;
  int _activeStep = 0;
  double _progress = 0;
  bool _failed = false;
  String? _errorMsg;

  final _steps = [
    ('Downloading', 'Fetching video source'),
    ('Transcribing audio', 'Speech-to-text model'),
    ('Extracting frames', 'Key visual moments'),
    ('Running AI analysis', 'Semantic understanding'),
    ('Saving to vault', 'Building insight card'),
  ];

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    try {
      final taskId = await _api.processUrl(widget.url);
      setState(() => _taskId = taskId);
      _timer = Timer.periodic(AppConstants.pollingInterval, (_) => _poll());
    } catch (e) {
      setState(() { _failed = true; _errorMsg = e.toString(); });
    }
  }

  Future<void> _poll() async {
    if (_taskId == null) return;
    if (!mounted) {
      _timer?.cancel();
      return;
    }
    try {
      final status = await _api.pollStatus(_taskId!);
      if (!mounted) return;

      if (status.status == 'completed' && status.entryId != null) {
        _timer?.cancel();
        setState(() { _activeStep = 4; _progress = 1.0; });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context);
          widget.onCompleted(status.entryId!);
        }
      } else if (status.status == 'failed') {
        _timer?.cancel();
        setState(() { _failed = true; _errorMsg = status.error ?? 'Unknown error'; });
      } else {
        // Advance progress visually
        setState(() {
          _progress = (_progress + 0.08).clamp(0, 0.9);
          _activeStep = (_progress * _steps.length).floor().clamp(0, _steps.length - 1);
        });
      }
    } catch (e) {
      // Don't stop on transient network errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.6),
            radius: 1.2,
            colors: [Color(0x2EC9A84C), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: _failed ? _buildError() : _buildProcessing(),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return Column(
      children: [
        const SizedBox(height: 60),
        // Circular progress + icon
        SizedBox(
          width: 180, height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180, height: 180,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 6,
                  color: const Color(0x0DFFFFFF),
                ),
              ),
              SizedBox(
                width: 180, height: 180,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    color: InsightrColors.goldPrimary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1AC9A84C),
                ),
                child: Center(
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: InsightrColors.goldPrimary,
                      boxShadow: [BoxShadow(
                        color: InsightrColors.goldPrimary.withAlpha(128),
                        blurRadius: 32,
                      )],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2A230C), size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text('Building your insight card...', style: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 8),
        Text('This usually takes under 30 seconds', style: GoogleFonts.inter(
          fontSize: 14, color: InsightrColors.textSecondary,
        )),
        const SizedBox(height: 48),
        // Steps stepper
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: _steps.asMap().entries.map((e) {
                final idx = e.key;
                final (title, subtitle) = e.value;
                final isDone = idx < _activeStep;
                final isActive = idx == _activeStep;
                return _StepRow(
                  title: title,
                  subtitle: subtitle,
                  isDone: isDone,
                  isActive: isActive,
                  isLast: idx == _steps.length - 1,
                );
              }).toList(),
            ),
          ),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: const Color(0x14FFFFFF),
                valueColor: const AlwaysStoppedAnimation(InsightrColors.goldPrimary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text('${(_progress * 100).toInt()}% complete', style: GoogleFonts.inter(
              fontSize: 12, color: InsightrColors.textMuted,
            )),
          ]),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(
            fontSize: 15, color: InsightrColors.textSecondary,
          )),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildError() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x14E05C4A),
            border: Border.all(color: const Color(0x40E05C4A), width: 1),
          ),
          child: const Icon(Icons.error_outline_rounded, size: 40, color: InsightrColors.red),
        ),
        const SizedBox(height: 24),
        Text('Processing Failed', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(
          'Something went wrong while processing this URL.',
          style: GoogleFonts.inter(fontSize: 14, color: InsightrColors.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x0FE05C4A),
              borderRadius: InsightrRadii.lgAll,
              border: Border.all(color: const Color(0x2EE05C4A), width: 1),
            ),
            child: Text(_errorMsg!, style: GoogleFonts.sourceCodePro(
              fontSize: 12, color: InsightrColors.red,
            )),
          ),
        ],
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            decoration: BoxDecoration(
              borderRadius: InsightrRadii.fullAll,
              color: const Color(0x0FFFFFFF),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
            child: Text('Go Back', style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600,
            )),
          ),
        ),
      ]),
    ));
  }
}

class _StepRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  const _StepRow({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF14120B),
            border: Border.all(
              color: isDone
                  ? InsightrColors.goldPrimary.withAlpha(128)
                  : isActive
                      ? InsightrColors.goldPrimary.withAlpha(204)
                      : const Color(0x0FFFFFFF),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [BoxShadow(
              color: InsightrColors.goldPrimary.withAlpha(76),
              blurRadius: 16,
            )] : [],
          ),
          child: isDone
              ? const Icon(Icons.check_rounded, size: 14, color: InsightrColors.goldPrimary)
              : isActive
                  ? Center(child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: InsightrColors.goldPrimary,
                      ),
                    ))
                  : Center(child: Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0x26FFFFFF),
                      ),
                    )),
        ),
        if (!isLast) Container(
          width: 1, height: 32,
          color: isDone ? const Color(0x66C9A84C) : const Color(0x0FFFFFFF),
        ),
      ]),
      const SizedBox(width: 16),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: isActive
                ? InsightrColors.goldPrimary
                : isDone
                    ? InsightrColors.textPrimary
                    : InsightrColors.textMuted,
          )),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(
            fontSize: 12,
            color: (isDone || isActive) ? InsightrColors.textSecondary : InsightrColors.textMuted,
          )),
        ]),
      )),
    ]);
  }
}
