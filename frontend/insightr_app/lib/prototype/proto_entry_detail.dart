// PHASE 0 PROTOTYPE — Entry Detail surface. Not production code.
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'mock_data.dart';
import 'proto_common.dart';
import 'proto_concept_page.dart';
import 'proto_connection_detail.dart';

class ProtoEntryDetail extends StatelessWidget {
  final int entryId;
  const ProtoEntryDetail({super.key, required this.entryId});

  @override
  Widget build(BuildContext context) {
    final e = MockGraph.entry(entryId);
    final concepts = MockGraph.conceptsFor(e);
    final conns = MockGraph.connectionsFor(e.id);
    final artifacts = MockGraph.artifactsFor(e);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Entry')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          // Hero
          Text(e.title, style: t.titleLarge),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.bolt_rounded, size: 14, color: InsightrColors.goldPrimary),
            const SizedBox(width: 4),
            Text('${e.field} · ${e.contentType} · ${e.capturedAt}',
                style: t.bodySmall),
          ]),
          const SizedBox(height: 16),

          // Evolution trail (Captured -> Connected -> Expanded -> Applied)
          ProtoCard(
            borderColor: InsightrColors.borderGold,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _evo(context, 'Captured', e.capturedAt.substring(5)),
                _evo(context, 'Connected', '${conns.length}'),
                _evo(context, 'Expanded', '${concepts.length}'),
                _evo(context, 'Applied',
                    '${e.actions.where((a) => a.done).length}'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // The Grab
          ProtoSectionLabel('The Grab'),
          ProtoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.hook, style: t.bodyLarge),
                const SizedBox(height: 8),
                Text(e.actions.isNotEmpty ? 'Next: ${e.actions.first.text}' : '',
                    style: t.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Core takeaway
          ProtoSectionLabel('Core Takeaway'),
          ProtoCard(
            borderColor: InsightrColors.borderGold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.takeawayHeadline,
                    style: t.titleSmall?.copyWith(color: InsightrColors.goldLight)),
                const SizedBox(height: 8),
                Text(e.takeawayBody, style: t.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Concepts -> Concept Page
          ProtoSectionLabel('Concepts'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in concepts)
                ProtoChip(
                  c.name,
                  icon: conceptIcon(c.type),
                  gold: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProtoConceptPage(conceptId: c.id))),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Connections -> Connection Detail
          ProtoSectionLabel('Connections'),
          for (final c in conns) ...[
            Builder(builder: (context) {
              final otherId = c.fromEntryId == e.id ? c.toEntryId : c.fromEntryId;
              final other = MockGraph.entry(otherId);
              return ProtoCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProtoConnectionDetail(connectionId: c.id))),
                child: Row(children: [
                  Icon(Icons.share_rounded,
                      size: 18, color: InsightrColors.goldPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(other.title, style: t.bodyLarge),
                        const SizedBox(height: 2),
                        Text(c.reason, style: t.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: InsightrColors.textMuted),
                ]),
              );
            }),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),

          // Artifacts
          if (artifacts.isNotEmpty) ...[
            ProtoSectionLabel('Referenced Artifacts'),
            for (final a in artifacts) ...[
              ProtoCard(
                child: Row(children: [
                  Icon(artifactIcon(a.type), size: 18, color: InsightrColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.name, style: t.bodyLarge),
                        const SizedBox(height: 2),
                        Text(a.description, style: t.bodySmall),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget _evo(BuildContext context, String label, String value) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: t.titleSmall?.copyWith(color: InsightrColors.goldLight)),
        const SizedBox(height: 2),
        Text(label, style: t.labelMedium),
      ],
    );
  }
}
