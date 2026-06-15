import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/action_item.dart';
import '../../services/api_service.dart';

class CompletedActionsScreen extends StatefulWidget {
  const CompletedActionsScreen({super.key});

  @override
  State<CompletedActionsScreen> createState() => _CompletedActionsScreenState();
}

class _CompletedActionsScreenState extends State<CompletedActionsScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<ActionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _api.getTodo(done: true);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleItem(ActionItem item, bool done) async {
    try {
      await _api.toggleTodo(item.id, done: done);
      _load(); // Reload after toggling to remove it from this list
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      appBar: AppBar(
        backgroundColor: InsightrColors.bgDark,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x12FFFFFF),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 16),
          ),
        ),
        title: Text('Completed', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
          : _items.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0x08FFFFFF),
                        borderRadius: InsightrRadii.lgAll,
                        border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
                      ),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => _toggleItem(item, false),
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x265C9A6A),
                              border: Border.all(color: const Color(0x665C9A6A), width: 1.5),
                            ),
                            child: const Icon(Icons.check_rounded, size: 12, color: InsightrColors.green),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.text, style: GoogleFonts.inter(
                          fontSize: 14, color: InsightrColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ))),
                      ]),
                    );
                  },
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x1A5C9A6A),
          border: Border.all(color: const Color(0x4D5C9A6A), width: 1.5),
        ),
        child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: InsightrColors.green),
      ),
      const SizedBox(height: 16),
      Text('No completed actions yet', style: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w700, color: InsightrColors.textPrimary,
      )),
      const SizedBox(height: 8),
      Text('Finish tasks from your Action Items', style: GoogleFonts.inter(
        fontSize: 14, color: InsightrColors.textSecondary,
      )),
    ]));
  }
}
