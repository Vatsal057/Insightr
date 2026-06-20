// PHASE 0 — DESIGN VALIDATION PROTOTYPE entry point (THROWAWAY).
//
// Validates the knowledge-network traversal across Navigation Shell, Home,
// Entry Detail, Connection Detail, and Concept Page using mock data only.
// No backend, no Riverpod, no engines, no persistence.
//
// Run with:  flutter run -t lib/prototype/main_prototype.dart
//
// This file is NOT part of the production build (production uses lib/main.dart).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import 'proto_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProtoApp());
}

class ProtoApp extends StatelessWidget {
  const ProtoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insightr · Phase 0 Prototype',
      theme: InsightrTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const ProtoShell(),
    );
  }
}

/// The five-destination shell. Each tab keeps its own Navigator so the
/// traversal back-stack is preserved per destination (validates Req 26).
class ProtoShell extends StatefulWidget {
  const ProtoShell({super.key});
  @override
  State<ProtoShell> createState() => _ProtoShellState();
}

class _ProtoShellState extends State<ProtoShell> {
  int _index = 0;

  // Independent navigators so each destination preserves its stack.
  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  static const _labels = ['Home', 'Explore', 'Capture', 'Vault', 'Profile'];
  static const _icons = [
    Icons.home_rounded,
    Icons.travel_explore_rounded,
    Icons.add_rounded,
    Icons.inventory_2_rounded,
    Icons.person_outline_rounded,
  ];

  void _onTap(int i) {
    if (i == _index) {
      // Already-active: pop to root (no-op for traversal otherwise).
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = i);
  }

  Widget _rootFor(int i) {
    switch (i) {
      case 0:
        return const ProtoHome();
      case 2:
        return const _Placeholder('Capture', Icons.add_rounded,
            'The animated ingestion pipeline lives here.');
      case 1:
        return const _Placeholder('Explore', Icons.travel_explore_rounded,
            'Universal Search, Knowledge Graph, Discovery.');
      case 3:
        return const _Placeholder('Vault', Icons.inventory_2_rounded,
            'Entries · Concepts · Artifacts · Collections.');
      default:
        return const _Placeholder('Profile', Icons.person_outline_rounded,
            'Identity · Health · Timeline · Mentor.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < 5; i++)
            Navigator(
              key: _navKeys[i],
              onGenerateRoute: (_) =>
                  MaterialPageRoute(builder: (_) => _DestinationScaffold(child: _rootFor(i))),
            ),
        ],
      ),
      bottomNavigationBar: _ProtoNavBar(
        index: _index,
        labels: _labels,
        icons: _icons,
        onTap: _onTap,
      ),
    );
  }
}

class _DestinationScaffold extends StatelessWidget {
  final Widget child;
  const _DestinationScaffold({required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: InsightrColors.bgDark, body: child);
  }
}

class _ProtoNavBar extends StatelessWidget {
  final int index;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onTap;
  const _ProtoNavBar({
    required this.index,
    required this.labels,
    required this.icons,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: InsightrColors.navBg,
        border: Border(top: BorderSide(color: InsightrColors.glassBorder, width: 0.8)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(child: _item(context, i)),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, int i) {
    final active = i == index;
    final isCapture = i == 2;

    if (isCapture) {
      // Distinct, larger, gold center node (validates Req 2.5 framing).
      return GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [InsightrColors.goldLight, InsightrColors.goldPrimary],
              ),
            ),
            child: const Icon(Icons.add_rounded, color: Color(0xFF1A1200)),
          ),
        ),
      );
    }

    final color =
        active ? InsightrColors.goldPrimary : InsightrColors.textSecondary;
    return GestureDetector(
      onTap: () => onTap(i),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[i], size: 22, color: color),
          const SizedBox(height: 4),
          Text(labels[i],
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final String body;
  const _Placeholder(this.title, this.icon, this.body);
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: InsightrColors.goldMuted),
            const SizedBox(height: 16),
            Text(title, style: t.titleLarge),
            const SizedBox(height: 8),
            Text(body, style: t.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('(Phase 0 placeholder — traversal is validated via Home.)',
                style: t.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
