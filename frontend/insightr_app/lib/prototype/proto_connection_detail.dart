// PHASE 0 PROTOTYPE — Connection Detail surface (the fourth pillar). Not production.
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'mock_data.dart';
import 'proto_common.dart';
import 'proto_concept_page.dart';
import 'proto_entry_detail.dart';

class ProtoConnectionDetail extends StatelessWidget {
  final int connectionId;
  const ProtoConnectionDetail({super.key, required this.connectionId});

  @override
  Widget build(BuildContext context) {
    final conn = MockGraph.connection(connectionId);
    final a = MockGraph.entry(conn.fromEntryId);
    final b = MockGraph.entry(conn.toEntryId);
    final sharedConcepts = MockGraph.sharedConcepts(a, b);
    final sharedArtifacts = MockGraph.sharedArtifacts(a, b);
    final t = Theme.of(context).textTheme;

    // Suggested next exploration: a related concept not already shared.
    final suggested = MockGraph.concepts
        .where((c) =>
            (a.conceptIds.contains(c.id) || b.conceptIds.contains(c.id)) &&
            !sharedConcepts.contains(c))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge Pathway')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          // Endpoints + reason
          ProtoCard(
            borderColor: InsightrColors.borderGold,
            child: Column(
              children: [
                _endpoint(context, a),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Icon(Icons.share_rounded,
                        size: 16, color: InsightrColors.goldPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(conn.reason,
                            style: t.bodySmall
                                ?.copyWith(color: InsightrColors.goldLight))),
                  ]),
                ),
                _endpoint(context, b),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ProtoSectionLabel('Shared Concepts'),
          if (sharedConcepts.isEmpty)
            ProtoCard(child: Text('No shared concepts.', style: t.bodyMedium))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in sharedConcepts)
                  ProtoChip(c.name,
                      icon: conceptIcon(c.type),
                      gold: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProtoConceptPage(conceptId: c.id)))),
              ],
            ),
          const SizedBox(height: 20),

          ProtoSectionLabel('Shared Artifacts'),
          if (sharedArtifacts.isEmpty)
            ProtoCard(child: Text('No shared artifacts.', style: t.bodyMedium))
          else
            for (final art in sharedArtifacts) ...[
              ProtoCard(
                child: Row(children: [
                  Icon(artifactIcon(art.type),
                      size: 18, color: InsightrColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(art.name, style: t.bodyLarge)),
                ]),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),

          // Suggested next exploration — the metric we most want to validate.
          ProtoSectionLabel('Suggested Next Exploration'),
          if (suggested.isEmpty)
            ProtoCard(child: Text('Nothing suggested yet.', style: t.bodyMedium))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in suggested)
                  ProtoChip(c.name,
                      icon: Icons.auto_awesome_rounded,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProtoConceptPage(conceptId: c.id)))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _endpoint(BuildContext context, PEntry e) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProtoEntryDetail(entryId: e.id))),
      child: Row(children: [
        Icon(Icons.article_rounded, size: 18, color: InsightrColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(e.title, style: t.bodyLarge)),
        const Icon(Icons.chevron_right_rounded, color: InsightrColors.textMuted),
      ]),
    );
  }
}
