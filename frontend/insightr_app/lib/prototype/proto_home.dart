// PHASE 0 PROTOTYPE — Home / Daily Intelligence Center surface. Not production.
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'mock_data.dart';
import 'proto_common.dart';
import 'proto_concept_page.dart';
import 'proto_connection_detail.dart';
import 'proto_entry_detail.dart';

class ProtoHome extends StatelessWidget {
  const ProtoHome({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final newConnections = MockGraph.connections;
    final suggested = MockGraph.concepts.take(4).toList();
    final continueLearning = MockGraph.concepts.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [
        Text('Good evening', style: t.bodyMedium),
        Text('Your Intelligence', style: t.headlineMedium),
        const SizedBox(height: 20),

        // Daily Intelligence Brief
        ProtoCard(
          borderColor: InsightrColors.borderGold,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 16, color: InsightrColors.goldPrimary),
                const SizedBox(width: 8),
                Text('DAILY BRIEF', style: t.labelSmall),
              ]),
              const SizedBox(height: 12),
              Text('Today you connected 4 ideas across AI Agents and MCP.',
                  style: t.titleSmall),
              const SizedBox(height: 8),
              Text('2 new concepts · 4 new connections · recommended next: Agent Planning',
                  style: t.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Continue Learning
        ProtoSectionLabel('Continue Learning'),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: continueLearning.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = continueLearning[i];
              return SizedBox(
                width: 160,
                child: ProtoCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProtoConceptPage(conceptId: c.id))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(conceptIcon(c.type),
                          color: InsightrColors.goldLight, size: 18),
                      const Spacer(),
                      Text(c.name, style: t.bodyLarge, maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${MockGraph.entriesFor(c).length} entries',
                          style: t.bodySmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // New Connections -> Connection Detail
        ProtoSectionLabel('New Connections Discovered'),
        for (final conn in newConnections) ...[
          Builder(builder: (context) {
            final a = MockGraph.entry(conn.fromEntryId);
            final b = MockGraph.entry(conn.toEntryId);
            return ProtoCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProtoConnectionDetail(connectionId: conn.id))),
              child: Row(children: [
                Expanded(
                  child: Row(children: [
                    Flexible(
                        child: Text(a.title,
                            style: t.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.sync_alt_rounded,
                          size: 16, color: InsightrColors.goldPrimary),
                    ),
                    Flexible(
                        child: Text(b.title,
                            style: t.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: InsightrColors.textMuted),
              ]),
            );
          }),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),

        // Suggested Next Concepts
        ProtoSectionLabel('Suggested Next Concepts'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in suggested)
              ProtoChip(c.name,
                  icon: conceptIcon(c.type),
                  gold: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProtoConceptPage(conceptId: c.id)))),
          ],
        ),
        const SizedBox(height: 24),

        // A direct jump into an entry to start a traversal
        ProtoSectionLabel('Recently Captured'),
        for (final e in MockGraph.entries) ...[
          ProtoCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProtoEntryDetail(entryId: e.id))),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: t.bodyLarge),
                    const SizedBox(height: 2),
                    Text(e.hook, style: t.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: InsightrColors.textMuted),
            ]),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
