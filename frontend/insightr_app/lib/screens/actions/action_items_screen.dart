import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/action_item.dart';
import '../../services/api_service.dart';

class ActionItemsScreen extends StatefulWidget {
  const ActionItemsScreen({super.key});

  @override
  State<ActionItemsScreen> createState() => _ActionItemsScreenState();
}

class _ActionItemsScreenState extends State<ActionItemsScreen> {
  final _api = ApiService();
  List<ActionItem> _items = [];
  bool _loading = true;
  bool _showDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _api.getTodo(done: _showDone ? null : false);
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(ActionItem item) async {
    try {
      await _api.toggleTodo(item.id, done: !item.done);
      await _load();
    } catch (_) {}
  }

  List<ActionItem> _byPriority(String priority) =>
      _items.where((i) => i.priority == priority).toList();

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
      ),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(children: [
          Expanded(child: Text('Actions', style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 40, letterSpacing: -1.5,
          ))),
          GestureDetector(
            onTap: () => setState(() { _showDone = !_showDone; _load(); }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                borderRadius: InsightrRadii.fullAll,
                border: Border.all(color: const Color(0x14FFFFFF), width: 1),
              ),
              child: Text(_showDone ? 'All' : 'Pending', style: GoogleFonts.inter(
                fontSize: 12, color: InsightrColors.textSecondary,
              )),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Your next steps', style: Theme.of(context).textTheme.bodyMedium),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
            : RefreshIndicator(
                color: InsightrColors.goldPrimary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
                  children: [
                    if (_byPriority('now').isNotEmpty) ...[
                      _PriorityHeader('NOW', InsightrColors.goldPrimary),
                      ..._byPriority('now').map((i) => _ActionCard(item: i, onToggle: () => _toggle(i))),
                    ],
                    if (_byPriority('soon').isNotEmpty) ...[
                      _PriorityHeader('SOON', InsightrColors.textSecondary),
                      ..._byPriority('soon').map((i) => _ActionCard(item: i, onToggle: () => _toggle(i))),
                    ],
                    if (_byPriority('someday').isNotEmpty) ...[
                      _PriorityHeader('SOMEDAY', InsightrColors.textMuted),
                      ..._byPriority('someday').map((i) => _ActionCard(item: i, onToggle: () => _toggle(i))),
                    ],
                    if (_items.isEmpty)
                      _EmptyState(),
                  ],
                ),
              ),
      ),
    ]),
    ));
  }
}

class _PriorityHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _PriorityHeader(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: color,
        )),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final ActionItem item;
  final VoidCallback onToggle;
  const _ActionCard({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.done ? const Color(0x265C9A6A) : Colors.transparent,
                border: Border.all(
                  color: item.done ? InsightrColors.green : const Color(0x26FFFFFF),
                  width: 1.5,
                ),
              ),
              child: item.done
                  ? const Icon(Icons.check_rounded, size: 12, color: InsightrColors.green)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              item.text,
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,
                color: item.done ? InsightrColors.textMuted : InsightrColors.textPrimary,
                decoration: item.done ? TextDecoration.lineThrough : null,
                decorationColor: InsightrColors.textMuted,
              ),
            ),
            if (item.title != null || item.timeEstimate != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                if (item.title != null)
                  Text(item.title!, style: GoogleFonts.inter(
                    fontSize: 12, color: InsightrColors.textMuted,
                  )),
                if (item.title != null && item.timeEstimate != null)
                  Text(' · ', style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textMuted)),
                if (item.timeEstimate != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.schedule_rounded, size: 10, color: InsightrColors.textMuted),
                    const SizedBox(width: 3),
                    Text(item.timeEstimate!, style: GoogleFonts.inter(
                      fontSize: 11, color: InsightrColors.textMuted,
                    )),
                  ]),
              ]),
            ],
          ])),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x0AFFFFFF),
            border: Border.all(color: const Color(0x14FFFFFF), width: 1),
          ),
          child: const Icon(Icons.check_circle_rounded, size: 32, color: InsightrColors.goldPrimary),
        ),
        const SizedBox(height: 24),
        Text('All Caught Up!', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text("You've completed all your pending action items. Time to learn something new.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15, color: InsightrColors.textSecondary, height: 1.5,
            ),
          ),
        ),
      ]),
    ));
  }
}
