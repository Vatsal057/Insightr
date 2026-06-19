import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/feed_card.dart';
import '../../services/api_service.dart';
import '../add_url/add_url_sheet.dart';
import '../insight_detail/insight_detail_screen.dart';
import '../search/search_screen.dart';
import '../actions/action_items_screen.dart';
import '../vault/knowledge_vault_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  int _navIndex = 0;
  int _pendingActionCount = 0;
  String _activeFilter = 'All';
  List<FeedCard> _allCards = [];
  bool _loading = true;
  String? _error;

  // Filters derived from actual feed card fields (populated after load)

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final items = await _api.getTodo(done: false);
      if (mounted) setState(() => _pendingActionCount = items.length);
    } catch (_) {}
  }

  Future<void> _loadFeed() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cards = await _api.getFeed();
      setState(() { _allCards = cards; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<String> get _filters {
    final fields = _allCards
        .map((c) => c.field.trim())
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...fields];
  }

  List<FeedCard> get _filteredCards {
    if (_activeFilter == 'All') return _allCards;
    return _allCards
        .where((c) => c.field.toLowerCase() == _activeFilter.toLowerCase())
        .toList();
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 1: return const KnowledgeVaultScreen();
      case 2: return const ActionItemsScreen();
      case 3: return const SearchScreen();
      case 4: return const _ProfileWrapper();
      default: return _buildFeed();
    }
  }

  Widget _buildFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              )),
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF8A6A30), Color(0xFF5A4020)]),
                ),
                child: const Icon(Icons.person_rounded, color: InsightrColors.textPrimary, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hi there 👋', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('Welcome back', style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary)),
            ])),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x0FFFFFFF),
                border: Border.all(color: const Color(0x14FFFFFF), width: 1),
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 18, color: InsightrColors.textSecondary),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Text('Your Vault', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: InsightrColors.textPrimary)),
        ),
        // Filter pills
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => PillButton(
              label: _filters[i],
              isActive: _activeFilter == _filters[i],
              onTap: () => setState(() => _activeFilter = _filters[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Feed
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
            : _error != null
                ? _ErrorState(error: _error!, onRetry: _loadFeed)
                : _filteredCards.isEmpty
                    ? _EmptyState(filter: _activeFilter)
                    : RefreshIndicator(
                        color: InsightrColors.goldPrimary,
                        onRefresh: _loadFeed,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
                          itemCount: _filteredCards.length,
                          itemBuilder: (_, i) => _FeedCardWidget(
                            card: _filteredCards[i],
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => InsightDetailScreen(entryId: _filteredCards[i].id),
                            )),
                          ),
                        ),
                      )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: InsightrColors.bgDark,
      body: SafeArea(bottom: false, child: _buildBody()),
      floatingActionButton: _navIndex == 0
          ? InsightrFab(onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddUrlSheet(onProcessed: (id) {
                    _loadFeed(); // Refresh so the new entry appears in the feed
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => InsightDetailScreen(entryId: id),
                    ));
                  }),
                );
              })
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        child: InsightrBottomNav(
          currentIndex: _navIndex,
          onTap: (i) {
            setState(() => _navIndex = i);
            // Always refresh pending count when switching tabs so the badge stays accurate
            _loadPendingCount();
          },
          pendingCount: _pendingActionCount,
        ),
      ),
    );
  }
}

// Strips the nested Scaffold from ProfileScreen when it's embedded inside HomeScreen.
// ProfileScreen manages its own Scaffold (for settings push navigation), so we
// unwrap it here to avoid double-Scaffold issues.
class _ProfileWrapper extends StatelessWidget {
  const _ProfileWrapper();

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}

// ─── Feed Card Widget ─────────────────────────────────────────────────────────

class _FeedCardWidget extends StatelessWidget {
  final FeedCard card;
  final VoidCallback onTap;

  const _FeedCardWidget({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TagChip(label: card.field.isEmpty ? 'General' : card.field),
          const SizedBox(height: 8),
          Text(card.title, style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w700, height: 1.25,
            color: InsightrColors.textPrimary,
          )),
          const SizedBox(height: 6),
          Text(card.hook, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          // Stats row
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (card.actionItemCount > 0) _StatPill('${card.actionItemCount} actions'),
          ]),
          if (card.topAction != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x0FC9A84C),
                borderRadius: InsightrRadii.mdAll,
                border: Border.all(color: const Color(0x1FC9A84C), width: 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TOP ACTION', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: InsightrColors.goldPrimary, letterSpacing: 0.5,
                )),
                const SizedBox(height: 6),
                Text(card.topAction!.text, style: GoogleFonts.inter(
                  fontSize: 13, height: 1.5, color: InsightrColors.textPrimary,
                )),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  const _StatPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: InsightrRadii.fullAll,
        border: Border.all(color: const Color(0x12FFFFFF), width: 1),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x0AFFFFFF),
          border: Border.all(color: const Color(0x14FFFFFF), width: 1),
        ),
        child: const Icon(Icons.inbox_rounded, size: 32, color: InsightrColors.textMuted),
      ),
      const SizedBox(height: 16),
      Text('No $filter insights yet', style: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w700, color: InsightrColors.textPrimary,
      )),
      const SizedBox(height: 8),
      Text('Add a video URL to get started', style: GoogleFonts.inter(
        fontSize: 14, color: InsightrColors.textSecondary,
      )),
    ]));
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x14E05C4A),
            border: Border.all(color: const Color(0x40E05C4A), width: 1),
          ),
          child: const Icon(Icons.wifi_off_rounded, size: 32, color: InsightrColors.red),
        ),
        const SizedBox(height: 16),
        Text('Backend unreachable', style: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 8),
        Text(error, style: GoogleFonts.inter(
          fontSize: 12, color: InsightrColors.red.withAlpha(178), fontStyle: FontStyle.italic,
        ), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Make sure the backend is running\non port 8000', style: GoogleFonts.inter(
          fontSize: 14, color: InsightrColors.textSecondary,
        ), textAlign: TextAlign.center),
        const SizedBox(height: 24),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0x1FC9A84C),
            borderRadius: InsightrRadii.fullAll,
            border: Border.all(color: InsightrColors.borderGold, width: 1),
          ),
          child: Text('Retry', style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: InsightrColors.goldPrimary,
          )),
        ),
      ),
    ])));
  }
}
