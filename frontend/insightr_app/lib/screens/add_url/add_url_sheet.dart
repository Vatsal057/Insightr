import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'dart:ui';
import '../../core/widgets/pill_button.dart';
import '../processing/processing_screen.dart';

class AddUrlSheet extends StatefulWidget {
  final void Function(int entryId) onProcessed;

  const AddUrlSheet({super.key, required this.onProcessed});

  @override
  State<AddUrlSheet> createState() => _AddUrlSheetState();
}

class _AddUrlSheetState extends State<AddUrlSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    if (!mounted) return;
    Navigator.pop(context); // Close sheet

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProcessingScreen(
        url: url,
        onCompleted: widget.onProcessed,
      ),
    ));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() => _controller.text = data!.text!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xCC14140A),
            border: Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 20),
          Text('Add a Short', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text("We'll extract insights automatically", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          // URL Input
          GestureDetector(
            onTap: _pasteFromClipboard,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                borderRadius: InsightrRadii.fullAll,
                border: Border.all(color: InsightrColors.borderGold, width: 1),
              ),
              child: Row(children: [
                const Icon(Icons.link_rounded, size: 18, color: InsightrColors.goldMuted),
                const SizedBox(width: 10),
                Expanded(child: _controller.text.isEmpty
                    ? Text('Tap to paste URL', style: GoogleFonts.inter(
                        fontSize: 15, color: InsightrColors.textMuted,
                      ))
                    : Text(_controller.text,
                        style: GoogleFonts.inter(
                          fontSize: 15, color: InsightrColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _controller.clear()),
                    child: const Icon(Icons.close_rounded, size: 16, color: InsightrColors.textMuted),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text('Instagram, TikTok, or YouTube Shorts',
            style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textMuted)),
          const SizedBox(height: 20),
          // Also allow typing
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(fontSize: 15, color: InsightrColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Or type / paste URL manually',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: InsightrColors.textMuted),
              filled: true,
              fillColor: const Color(0x0AFFFFFF),
              border: OutlineInputBorder(
                borderRadius: InsightrRadii.lgAll,
                borderSide: const BorderSide(color: Color(0x14FFFFFF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: InsightrRadii.lgAll,
                borderSide: const BorderSide(color: Color(0x14FFFFFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: InsightrRadii.lgAll,
                borderSide: const BorderSide(color: InsightrColors.goldPrimary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Process',
            icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF1A1200), size: 18),
            onTap: _process,
          ),
        ],
      ),
    )));
  }
}

