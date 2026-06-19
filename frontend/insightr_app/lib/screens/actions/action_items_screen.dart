import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/action_item.dart';
import '../../services/api_service.dart';
import '../insight_detail/insight_detail_screen.dart';

class ActionItemsScreen extends StatefulWidget {
  const ActionItemsScreen({super.key});

  @override
  State<ActionItemsScreen> createState() => _ActionItemsScreenState();
}

class _ActionItemsScreenState extends State<ActionItemsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<ActionItem> _items = [];
  bool _loading = true;

  // Filter: 'pending' | 'done' | 'all'
  String _filter = 'pending';

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final filters = ['pending', 'all', 'done'];
        setState(() => _filter = filters[_tabController.index]);
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final bool? done = switch (_filter) {
        'pending' => false,
        'done'    => true,
        _         => null,
      };
      final items = await _api.getTodo(done: done);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(ActionItem item) async {
    // Optimistic update
    setState(() {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx >= 0) _items[idx] = item.copyWith(done: !item.done);
    });
    try {
      await _api.toggleTodo(item.id, done: !item.done);
      await _load(silent: true);
    } catch (_) {
      // Revert
      setState(() {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx >= 0) _items[idx] = item;
      });
    }
  }

  // Group items by entryId, preserving order of first appearance
  Map<int, List<ActionItem>> get _grouped {
    final map = <int, List<ActionItem>>{};
    for (final item in _items) {
      map.putIfAbsent(item.entryId, () => []).add(item);
    }
    return map;
  }

  int get _pendingCount => _items.where((i) => !i.done).length;
  int get _doneCount => _items.where((i) => i.done).length;

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Column(children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Actions',
                  style: GoogleFonts.inter(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    letterSpacing: -0.5, color: InsightrColors.textPrimary,
                  ))),
                // Pending badge
                if (_pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1AC9A84C),
                      borderRadius: InsightrRadii.fullAll,
                      border: Border.all(color: InsightrColors.borderGold),
                    ),
                    child: Text('$_pendingCount pending',
                      style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: InsightrColors.goldPrimary,
                      )),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(
                _filter == 'pending'
                    ? 'Actions you\'ve committed to from your reels'
                    : _filter == 'done'
                        ? '$_doneCount completed actions'
                        : '${_items.length} total actions across ${grouped.length} insights',
                style: GoogleFonts.inter(
                  fontSize: 13, color: InsightrColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // ── Tabs ───────────────────────────────────────────────────
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x08FFFFFF),
                  borderRadius: InsightrRadii.fullAll,
                  border: Border.all(color: const Color(0x10FFFFFF)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: InsightrColors.goldPrimary,
                    borderRadius: InsightrRadii.fullAll,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                  labelColor: const Color(0xFF1A1200),
                  unselectedLabelColor: InsightrColors.textSecondary,
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'All'),
                    Tab(text: 'Done'),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: InsightrColors.goldPrimary, strokeWidth: 2))
                : grouped.isEmpty
                    ? _EmptyState(filter: _filter)
                    : RefreshIndicator(
                        color: InsightrColors.goldPrimary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                          itemCount: grouped.length,
                          itemBuilder: (ctx, idx) {
                            final entryId = grouped.keys.elementAt(idx);
                            final entryItems = grouped[entryId]!;
                            return _ReelGroup(
                              entryId: entryId,
                              items: entryItems,
                              onToggle: _toggle,
                            );
                          },
                        ),
                      ),
          ),
        ]);
  }
}

// ─── Reel Group ──────────────────────────────────────────────────────────────
// One card per source insight, with priority sub-sections inside

class _ReelGroup extends StatelessWidget {
  final int entryId;
  final List<ActionItem> items;
  final Future<void> Function(ActionItem) onToggle;

  const _ReelGroup({
    required this.entryId,
    required this.items,
    required this.onToggle,
  });

  static const _priorityOrder = ['now', 'soon', 'someday'];
  static const _priorityLabel = {'now': 'NOW', 'soon': 'SOON', 'someday': 'SOMEDAY'};
  static const _priorityColor = {
    'now':     InsightrColors.goldPrimary,
    'soon':    Color(0xFF6A9AD4),
    'someday': InsightrColors.textMuted,
  };

  String get _sourceTitle => items.first.title ?? 'Untitled Insight';
  String get _sourceField => items.first.entryField ?? '';
  int get _doneCount => items.where((i) => i.done).length;
  int get _total => items.length;

  @override
  Widget build(BuildContext context) {
    // Group items by priority within this reel
    final byPriority = <String, List<ActionItem>>{};
    for (final p in _priorityOrder) {
      final group = items.where((i) => i.priority == p).toList();
      if (group.isNotEmpty) byPriority[p] = group;
    }

    final allDone = _doneCount == _total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Source insight header ──────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => InsightDetailScreen(entryId: entryId),
          )),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Progress indicator
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 32, height: 32,
                  child: CircularProgressIndicator(
                    value: _total > 0 ? _doneCount / _total : 0,
                    strokeWidth: 2.5,
                    backgroundColor: const Color(0x18FFFFFF),
                    color: allDone
                        ? InsightrColors.green
                        : InsightrColors.goldPrimary,
                  ),
                ),
                Text('$_doneCount', style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  color: allDone ? InsightrColors.green : InsightrColors.goldPrimary,
                )),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_sourceTitle,
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: InsightrColors.textPrimary, height: 1.3,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(children: [
                  if (_sourceField.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
                      decoration: BoxDecoration(
                        color: const Color(0x14C9A84C),
                        borderRadius: InsightrRadii.fullAll,
                        border: Border.all(color: InsightrColors.borderGold),
                      ),
                      child: Text(_sourceField,
                        style: GoogleFonts.inter(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: InsightrColors.goldMuted, letterSpacing: 0.3,
                        )),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text('$_doneCount / $_total done',
                    style: GoogleFonts.inter(
                      fontSize: 11, color: InsightrColors.textMuted,
                    )),
                ]),
              ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                size: 14, color: InsightrColors.textMuted),
            ]),
          ),
        ),

        // ── Action items by priority ───────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: InsightrRadii.lgAll,
            border: Border.all(color: const Color(0x0EFFFFFF), width: 1),
          ),
          child: Column(children: [
            for (int pi = 0; pi < byPriority.length; pi++) ...[
              Builder(builder: (_) {
                final priority = byPriority.keys.elementAt(pi);
                final group = byPriority[priority]!;
                final color = _priorityColor[priority] ?? InsightrColors.textSecondary;
                final label = _priorityLabel[priority] ?? priority.toUpperCase();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Priority label
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    child: Row(children: [
                      Container(width: 6, height: 6,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(label, style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        letterSpacing: 1.5, color: color,
                      )),
                    ]),
                  ),
                  // Items in this priority
                  ...group.map((item) => _ActionRow(
                    item: item,
                    priorityColor: color,
                    onToggle: () => onToggle(item),
                    isLast: item == group.last &&
                            pi == byPriority.length - 1,
                  )),
                ]);
              }),
              if (pi < byPriority.length - 1)
                const Divider(height: 1, color: Color(0x08FFFFFF), indent: 14, endIndent: 14),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ─── Individual Action Row ────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final ActionItem item;
  final Color priorityColor;
  final VoidCallback onToggle;
  final bool isLast;

  const _ActionRow({
    required this.item,
    required this.priorityColor,
    required this.onToggle,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 6, 14, isLast ? 14 : 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.done
                    ? priorityColor.withAlpha(50)
                    : const Color(0x08FFFFFF),
                border: Border.all(
                  color: item.done ? priorityColor : const Color(0x28FFFFFF),
                  width: 1.5,
                ),
              ),
              child: item.done
                  ? Icon(Icons.check_rounded, size: 11, color: priorityColor)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              item.text,
              style: GoogleFonts.inter(
                fontSize: 13, height: 1.4,
                color: item.done
                    ? InsightrColors.textMuted
                    : InsightrColors.textPrimary,
                decoration: item.done ? TextDecoration.lineThrough : null,
                decorationColor: InsightrColors.textMuted,
                fontWeight: item.done ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
            if (item.timeEstimate != null) ...[
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.schedule_rounded, size: 10,
                  color: item.done ? InsightrColors.textMuted : InsightrColors.goldMuted),
                const SizedBox(width: 3),
                Text(item.timeEstimate!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: item.done ? InsightrColors.textMuted : InsightrColors.goldMuted,
                  )),
              ]),
            ],
          ])),
        ]),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isDone = filter == 'done';
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 120),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x0AFFFFFF),
              border: Border.all(color: const Color(0x14FFFFFF), width: 1),
            ),
            child: Icon(
              isDone
                  ? Icons.sentiment_satisfied_alt_rounded
                  : Icons.check_circle_outline_rounded,
              size: 30,
              color: InsightrColors.goldPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isDone ? 'Nothing completed yet' : 'All caught up!',
            style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: InsightrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isDone
                ? 'Complete actions from your saved reels and they\'ll show up here.'
                : 'No pending actions. Save a reel to get your next steps.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13, color: InsightrColors.textSecondary, height: 1.6,
            ),
          ),
        ]),
      ),
    );
  }
}
