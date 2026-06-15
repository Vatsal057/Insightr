import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/collection.dart';
import '../../models/feed_card.dart';
import '../../services/api_service.dart';
import '../insight_detail/insight_detail_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;
  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final _api = ApiService();
  List<FeedCard> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _api.getCollectionEntries(widget.collection.name);
      setState(() { _entries = entries; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
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
              shape: BoxShape.circle, color: const Color(0x12FFFFFF),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 16),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.collection.name, style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700,
          )),
          Text('${widget.collection.entryCount} insights', style: GoogleFonts.inter(
            fontSize: 12, color: InsightrColors.textSecondary,
          )),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
          : RefreshIndicator(
              color: InsightrColors.goldPrimary,
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                itemCount: _entries.length,
                itemBuilder: (_, i) {
                  final e = _entries[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => InsightDetailScreen(entryId: e.id),
                      )),
                      child: GlassCard(padding: const EdgeInsets.all(16), child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0x1FC9A84C),
                                borderRadius: InsightrRadii.fullAll,
                                border: Border.all(color: const Color(0x40C9A84C), width: 1),
                              ),
                              child: Text(e.field.isEmpty ? 'General' : e.field, style: GoogleFonts.inter(
                                fontSize: 10, fontWeight: FontWeight.w600, color: InsightrColors.goldPrimary,
                              )),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded, color: InsightrColors.textMuted, size: 14),
                          ]),
                          const SizedBox(height: 8),
                          Text(e.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(e.hook, style: GoogleFonts.inter(
                            fontSize: 13, color: InsightrColors.textSecondary, height: 1.4,
                          ), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      )),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
