// PHASE 0 — DESIGN VALIDATION PROTOTYPE (THROWAWAY)
//
// This file is intentionally self-contained mock data with no backend, no
// Riverpod, and no derivation engines. Its only purpose is to validate the
// knowledge-network traversal (Entry -> Concept -> Connection -> Entry) before
// any production code is written. It is NOT promoted into the build.
//
// Run with:  flutter run -t lib/prototype/main_prototype.dart

class PConcept {
  final int id;
  final String name;
  final String type; // framework | tool | concept | methodology | book | person | website
  final String summary;
  final List<int> entryIds;
  const PConcept({
    required this.id,
    required this.name,
    required this.type,
    required this.summary,
    required this.entryIds,
  });
}

class PArtifact {
  final String name;
  final String type; // book | research_paper | tool | framework | ...
  final String description;
  final List<int> entryIds;
  const PArtifact({
    required this.name,
    required this.type,
    required this.description,
    required this.entryIds,
  });
}

class PActionItem {
  final String text;
  final String priority; // now | soon | someday
  final bool done;
  const PActionItem(this.text, this.priority, {this.done = false});
}

class PEntry {
  final int id;
  final String title;
  final String hook;
  final String field;
  final String contentType;
  final String capturedAt;
  final String takeawayHeadline;
  final String takeawayBody;
  final List<int> conceptIds;
  final List<String> tags;
  final List<PActionItem> actions;
  const PEntry({
    required this.id,
    required this.title,
    required this.hook,
    required this.field,
    required this.contentType,
    required this.capturedAt,
    required this.takeawayHeadline,
    required this.takeawayBody,
    required this.conceptIds,
    required this.tags,
    required this.actions,
  });
}

class PConnection {
  final int id;
  final int fromEntryId;
  final int toEntryId;
  final String reason;
  const PConnection({
    required this.id,
    required this.fromEntryId,
    required this.toEntryId,
    required this.reason,
  });
}

/// The single source of truth for the prototype's knowledge network.
class MockGraph {
  static const List<PConcept> concepts = [
    PConcept(
      id: 1,
      name: 'AI Agents',
      type: 'concept',
      summary:
          'Autonomous systems that perceive, reason, plan, and act toward goals '
          'using tools and memory, often orchestrated by a language model.',
      entryIds: [1, 2, 4],
    ),
    PConcept(
      id: 2,
      name: 'Tool Calling',
      type: 'framework',
      summary:
          'The mechanism by which an LLM invokes external functions or APIs, '
          'turning generated intent into concrete actions in the world.',
      entryIds: [1, 3],
    ),
    PConcept(
      id: 3,
      name: 'MCP',
      type: 'framework',
      summary:
          'Model Context Protocol — a standard interface for connecting models '
          'to tools, data sources, and memory in a portable way.',
      entryIds: [3, 4],
    ),
    PConcept(
      id: 4,
      name: 'Agent Memory',
      type: 'concept',
      summary:
          'Techniques that let agents retain and recall context across steps and '
          'sessions, spanning short-term scratchpads and long-term stores.',
      entryIds: [2, 4],
    ),
    PConcept(
      id: 5,
      name: 'Agent Planning',
      type: 'methodology',
      summary:
          'Decomposing a goal into ordered sub-tasks an agent can execute and '
          'verify, the bridge between reasoning and tool use.',
      entryIds: [1, 2],
    ),
  ];

  static const List<PArtifact> artifacts = [
    PArtifact(
      name: 'ReAct: Reasoning + Acting',
      type: 'research_paper',
      description:
          'Foundational paper interleaving chain-of-thought reasoning with tool '
          'actions to build more capable agents.',
      entryIds: [1, 2],
    ),
    PArtifact(
      name: 'LangGraph',
      type: 'tool',
      description: 'A library for building stateful, multi-step agent workflows.',
      entryIds: [3],
    ),
  ];

  static const List<PEntry> entries = [
    PEntry(
      id: 1,
      title: 'How AI Agents Actually Work',
      hook: 'An agent is a loop, not a model.',
      field: 'Technology',
      contentType: 'coding_tutorial',
      capturedAt: '2026-06-18',
      takeawayHeadline:
          'Agents are reasoning loops that call tools until a goal is met.',
      takeawayBody:
          'The model proposes an action, a tool executes it, the result feeds '
          'back in, and the loop repeats. Planning and tool calling are the two '
          'halves that make autonomy possible.',
      conceptIds: [1, 2, 5],
      tags: ['agents', 'llm', 'tools'],
      actions: [
        PActionItem('Build a minimal ReAct loop with one tool', 'now'),
        PActionItem('List 3 tools your agent actually needs', 'soon'),
      ],
    ),
    PEntry(
      id: 2,
      title: 'Why Agents Forget',
      hook: 'Without memory, every step starts from zero.',
      field: 'Technology',
      contentType: 'research_breakdown',
      capturedAt: '2026-06-19',
      takeawayHeadline: 'Memory is what turns a chatbot into an agent.',
      takeawayBody:
          'Short-term scratchpads hold the current task; long-term stores recall '
          'past sessions. Planning depends on both to avoid repeating work.',
      conceptIds: [1, 4, 5],
      tags: ['agents', 'memory', 'planning'],
      actions: [
        PActionItem('Add a scratchpad to your agent loop', 'now'),
        PActionItem('Evaluate a vector store for long-term memory', 'someday'),
      ],
    ),
    PEntry(
      id: 3,
      title: 'MCP in 5 Minutes',
      hook: 'One protocol to connect every tool.',
      field: 'Technology',
      contentType: 'tool_review',
      capturedAt: '2026-06-20',
      takeawayHeadline: 'MCP standardizes how models reach tools and data.',
      takeawayBody:
          'Instead of bespoke integrations, MCP exposes tools through a common '
          'interface — so tool calling becomes portable across models and apps.',
      conceptIds: [2, 3],
      tags: ['mcp', 'tools', 'protocol'],
      actions: [
        PActionItem('Wire one MCP server to your editor', 'now'),
      ],
    ),
    PEntry(
      id: 4,
      title: 'Memory + MCP = Persistent Agents',
      hook: 'Give your agent a memory it can carry anywhere.',
      field: 'Technology',
      contentType: 'opinion',
      capturedAt: '2026-06-21',
      takeawayHeadline: 'MCP can expose memory as just another tool.',
      takeawayBody:
          'Treating long-term memory as an MCP-exposed resource lets any agent '
          'read and write persistent context without custom plumbing.',
      conceptIds: [1, 3, 4],
      tags: ['agents', 'memory', 'mcp'],
      actions: [
        PActionItem('Sketch a memory-as-tool MCP schema', 'soon'),
      ],
    ),
  ];

  static const List<PConnection> connections = [
    PConnection(
      id: 1,
      fromEntryId: 1,
      toEntryId: 3,
      reason:
          'both mention: tool calling; shared concept: Tool Calling',
    ),
    PConnection(
      id: 2,
      fromEntryId: 2,
      toEntryId: 4,
      reason: 'same field: Technology; shared concepts: AI Agents, Agent Memory',
    ),
    PConnection(
      id: 3,
      fromEntryId: 1,
      toEntryId: 2,
      reason: 'shared concepts: AI Agents, Agent Planning',
    ),
    PConnection(
      id: 4,
      fromEntryId: 3,
      toEntryId: 4,
      reason: 'shared concept: MCP',
    ),
  ];

  // ── Lookups ───────────────────────────────────────────────────────────────

  static PEntry entry(int id) => entries.firstWhere((e) => e.id == id);
  static PConcept concept(int id) => concepts.firstWhere((c) => c.id == id);
  static PConnection connection(int id) =>
      connections.firstWhere((c) => c.id == id);

  static List<PConcept> conceptsFor(PEntry e) =>
      e.conceptIds.map(concept).toList();

  static List<PEntry> entriesFor(PConcept c) =>
      c.entryIds.map(entry).toList();

  static List<PConnection> connectionsFor(int entryId) => connections
      .where((c) => c.fromEntryId == entryId || c.toEntryId == entryId)
      .toList();

  static List<PArtifact> artifactsFor(PEntry e) =>
      artifacts.where((a) => a.entryIds.contains(e.id)).toList();

  /// Concepts that share at least one entry with [c] (excluding itself).
  static List<PConcept> relatedConcepts(PConcept c) {
    return concepts.where((other) {
      if (other.id == c.id) return false;
      return other.entryIds.any((id) => c.entryIds.contains(id));
    }).toList();
  }

  static List<PArtifact> sharedArtifacts(PEntry a, PEntry b) => artifacts
      .where((art) => art.entryIds.contains(a.id) && art.entryIds.contains(b.id))
      .toList();

  static List<PConcept> sharedConcepts(PEntry a, PEntry b) => concepts
      .where((c) => a.conceptIds.contains(c.id) && b.conceptIds.contains(c.id))
      .toList();
}
