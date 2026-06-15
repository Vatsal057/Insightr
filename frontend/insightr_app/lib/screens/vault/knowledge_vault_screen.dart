import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/concept.dart';
import '../../models/collection.dart';
import '../../services/api_service.dart';
import 'concept_detail_screen.dart';
import 'collection_detail_screen.dart';

class KnowledgeVaultScreen extends StatefulWidget {
  const KnowledgeVaultScreen({super.key});

  @override
  State<KnowledgeVaultScreen> createState() => _KnowledgeVaultScreenState();
}

class _KnowledgeVaultScreenState extends State<KnowledgeVaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _api = ApiService();

  List<Concept> _concepts = [];
  List<Collection> _collections = [];
  bool _loadingConcepts = true;
  bool _loadingCollections = true;
  String _conceptFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadConcepts();
    _loadCollections();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadConcepts({String? type}) async {
    setState(() => _loadingConcepts = true);
    try {
      final c = await _api.getConcepts(conceptType: type == 'all' ? null : type);
      setState(() { _concepts = c; _loadingConcepts = false; });
    } catch (_) {
      setState(() => _loadingConcepts = false);
    }
  }

  Future<void> _loadCollections() async {
    try {
      final c = await _api.getCollections();
      setState(() { _collections = c; _loadingCollections = false; });
    } catch (_) {
      setState(() => _loadingCollections = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Text('Knowledge\nVault', style: Theme.of(context).textTheme.displaySmall?.copyWith(
          letterSpacing: -1.0, height: 1.05,
        )),
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: _VaultStat(value: '${_concepts.length}', label: 'Concepts')),
          const SizedBox(width: 8),
          Expanded(child: _VaultStat(value: '${_collections.length}', label: 'Collections')),
          const SizedBox(width: 8),
          Expanded(child: _VaultStat(value: '${_collections.fold<int>(0, (s, c) => s + c.entryCount)}', label: 'Entries')),
        ]),
      ),
      const SizedBox(height: 16),
      // Search Bar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: InsightrRadii.lgAll,
            border: Border.all(color: const Color(0x14FFFFFF), width: 1),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, size: 18, color: InsightrColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: GoogleFonts.inter(fontSize: 14, color: InsightrColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search vault...',
                  hintStyle: GoogleFonts.inter(color: InsightrColors.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      // Tab bar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: InsightrRadii.fullAll,
          ),
          child: TabBar(
            controller: _tabs,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: InsightrColors.goldPrimary,
              borderRadius: InsightrRadii.fullAll,
            ),
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: const Color(0xFF1A1200),
            unselectedLabelColor: InsightrColors.textSecondary,
            tabs: const [Tab(text: 'Concepts'), Tab(text: 'Collections')],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Expanded(child: TabBarView(
        controller: _tabs,
        children: [_ConceptsTab(
          concepts: _concepts,
          loading: _loadingConcepts,
          filter: _conceptFilter,
          onFilter: (t) {
            setState(() => _conceptFilter = t);
            _loadConcepts(type: t);
          },
          onTap: (c) => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ConceptDetailScreen(concept: c),
          )),
        ),
        _CollectionsTab(
          collections: _collections,
          loading: _loadingCollections,
          onTap: (c) => Navigator.push(context, MaterialPageRoute(
            builder: (_) => CollectionDetailScreen(collection: c),
          )),
          onRefresh: _loadCollections,
        )],
      )),
    ]);
  }
}

class _ConceptsTab extends StatelessWidget {
  final List<Concept> concepts;
  final bool loading;
  final String filter;
  final void Function(String) onFilter;
  final void Function(Concept) onTap;

  const _ConceptsTab({
    required this.concepts, required this.loading,
    required this.filter, required this.onFilter, required this.onTap,
  });

  static const _types = ['all', 'framework', 'book', 'person', 'tool', 'methodology'];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter
      SizedBox(height: 44, child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _types[i];
          return GestureDetector(
            onTap: () => onFilter(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: InsightrRadii.fullAll,
                color: filter == t ? const Color(0x1FC9A84C) : const Color(0x0AFFFFFF),
                border: Border.all(
                  color: filter == t ? InsightrColors.borderGold : const Color(0x14FFFFFF), width: 1,
                ),
              ),
              child: Text(
                t == 'all' ? 'All' : t[0].toUpperCase() + t.substring(1),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: filter == t ? InsightrColors.goldPrimary : InsightrColors.textSecondary,
                ),
              ),
            ),
          );
        },
      )),
      const SizedBox(height: 12),
      Expanded(child: loading
          ? const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
              itemCount: concepts.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ConceptCard(concept: concepts[i], onTap: () => onTap(concepts[i])),
              ),
            )),
    ]);
  }
}

class _ConceptCard extends StatelessWidget {
  final Concept concept;
  final VoidCallback onTap;
  const _ConceptCard({required this.concept, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ConceptTagChip(conceptType: concept.conceptType),
            const SizedBox(height: 8),
            Text(concept.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
            const SizedBox(height: 4),
            Text(concept.summary, style: GoogleFonts.inter(
              fontSize: 13, color: InsightrColors.textSecondary, height: 1.4,
            ), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded, color: InsightrColors.textMuted, size: 20),
        ]),
      ),
    );
  }
}

class _CollectionsTab extends StatelessWidget {
  final List<Collection> collections;
  final bool loading;
  final void Function(Collection) onTap;
  final Future<void> Function() onRefresh;

  const _CollectionsTab({
    required this.collections, required this.loading,
    required this.onTap, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
        : RefreshIndicator(
            color: InsightrColors.goldPrimary,
            onRefresh: onRefresh,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x1FC9A84C),
                      borderRadius: InsightrRadii.fullAll,
                      border: Border.all(color: InsightrColors.borderGold, width: 1),
                    ),
                    child: Row(children: [
                      const Icon(Icons.add_rounded, size: 16, color: InsightrColors.goldPrimary),
                      const SizedBox(width: 6),
                      Text('New Collection', style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700, color: InsightrColors.goldPrimary,
                      )),
                    ]),
                  ),
                ]),
              ),
              Expanded(
                child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
              ),
              itemCount: collections.length,
              itemBuilder: (_, i) => _CollectionCard(
                collection: collections[i],
                onTap: () => onTap(collections[i]),
              ),
            ),
          ),
        ]),
      );
  }
}

class _CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;
  const _CollectionCard({required this.collection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0x1FC9A84C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bookmark_rounded, color: InsightrColors.goldPrimary, size: 20),
          ),
          const SizedBox(height: 10),
          Text(collection.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${collection.entryCount} insights', style: GoogleFonts.inter(
            fontSize: 12, color: InsightrColors.textSecondary,
          )),
        ]),
      ),
    );
  }
}

class _VaultStat extends StatelessWidget {
  final String value;
  final String label;
  const _VaultStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: InsightrRadii.lgAll,
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w800, color: InsightrColors.goldPrimary,
        )),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: InsightrColors.textSecondary,
        )),
      ]),
    );
  }
}
