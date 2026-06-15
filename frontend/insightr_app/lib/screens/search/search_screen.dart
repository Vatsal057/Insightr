import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/feed_card.dart';
import '../../services/api_service.dart';
import '../insight_detail/insight_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();
  List<FeedCard> _results = [];
  bool _loading = false;
  bool _hasSearched = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }
    setState(() { _loading = true; _hasSearched = true; });
    try {
      final results = await _api.search(q.trim());
      setState(() { _results = results; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Text('Search', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 40, letterSpacing: -1.5)),
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Search your knowledge vault', style: Theme.of(context).textTheme.bodyMedium),
      ),
      const SizedBox(height: 16),
      // Search input
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _controller,
            onChanged: (v) => _search(v),
            onSubmitted: (v) => _search(v),
            style: GoogleFonts.inter(fontSize: 15, color: InsightrColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by topic, tag, or keyword...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: InsightrColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: InsightrColors.textMuted, size: 20),
              filled: true,
              fillColor: const Color(0x0AFFFFFF),
              border: OutlineInputBorder(
                borderRadius: InsightrRadii.fullAll,
                borderSide: const BorderSide(color: Color(0x14FFFFFF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: InsightrRadii.fullAll,
                borderSide: const BorderSide(color: Color(0x14FFFFFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: InsightrRadii.fullAll,
                borderSide: const BorderSide(color: InsightrColors.goldPrimary),
              ),
            ),
          )),
        ]),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
            : !_hasSearched
                ? _SearchHints()
                : _results.isEmpty
                    ? _NoResults(query: _controller.text)
                    : Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Row(children: [
                            Text('${_results.length} results for "$_controller.text"', style: GoogleFonts.inter(
                              fontSize: 13, color: InsightrColors.textSecondary,
                            )),
                            const Spacer(),
                            Text('Sort by: ', style: GoogleFonts.inter(
                              fontSize: 13, color: InsightrColors.textMuted,
                            )),
                            Text('Relevance', style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: InsightrColors.goldPrimary,
                            )),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: InsightrColors.goldPrimary),
                          ]),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
                            itemCount: _results.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FeedCardWidget(
                                card: _results[i],
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => InsightDetailScreen(entryId: _results[i].id),
                                )),
                              ),
                            ),
                          ),
                        ),
                      ]),
      ),
    ]);
  }
}

class _SearchHints extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SUGGESTED TOPICS', style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: InsightrColors.goldMuted,
        )),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          'Productivity', 'Startup', 'Finance', 'AI', 'Fitness', 'Mindset',
        ].map((t) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: InsightrRadii.fullAll,
            border: Border.all(color: const Color(0x14FFFFFF), width: 1),
          ),
          child: Text(t, style: GoogleFonts.inter(fontSize: 13, color: InsightrColors.textSecondary)),
        )).toList()),
      ]),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

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
        child: const Icon(Icons.search_off_rounded, size: 32, color: InsightrColors.textMuted),
      ),
      const SizedBox(height: 16),
      Text('No results for "$query"', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Try a different keyword or topic', style: GoogleFonts.inter(
        fontSize: 14, color: InsightrColors.textSecondary,
      )),
    ]));
  }
}

class _FeedCardWidget extends StatelessWidget {
  final FeedCard card;
  final VoidCallback onTap;
  const _FeedCardWidget({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0x1FC9A84C),
                borderRadius: InsightrRadii.fullAll,
                border: Border.all(color: const Color(0x40C9A84C), width: 1),
              ),
              child: Text(card.field.isEmpty ? 'General' : card.field, style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600, color: InsightrColors.goldPrimary,
              )),
            ),
            const SizedBox(width: 8),
            Text('2h ago', style: GoogleFonts.inter(
              fontSize: 10, color: InsightrColors.textMuted,
            )),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: InsightrColors.textMuted, size: 16),
          ]),
          const SizedBox(height: 8),
          Text(card.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 6),
          Text(card.hook, style: GoogleFonts.inter(
            fontSize: 13, color: InsightrColors.textSecondary, height: 1.4,
          ), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
