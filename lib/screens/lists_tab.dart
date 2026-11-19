import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';

/// Edit the Priority and Buy-first lists the bot reads at 11:10.
class ListsTab extends StatefulWidget {
  const ListsTab({super.key, required this.api, required this.refresh});

  final HubApi api;
  final ValueListenable<int> refresh;

  @override
  State<ListsTab> createState() => _ListsTabState();
}

class _ListsTabState extends State<ListsTab> {
  late Future<Watchlists> _future = widget.api.watchlists();

  @override
  void initState() {
    super.initState();
    widget.refresh.addListener(_reload);
  }

  @override
  void dispose() {
    widget.refresh.removeListener(_reload);
    super.dispose();
  }

  void _reload() => setState(() => _future = widget.api.watchlists());

  Future<void> _change(Future<Watchlists> Function() call) async {
    try {
      final lists = await call();
      if (!mounted) return;
      setState(() => _future = Future.value(lists));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _future;
      },
      color: T.accent,
      backgroundColor: T.surface,
      child: FutureBuilder<Watchlists>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return loadingBody();
          }
          if (snap.hasError) {
            return messageBody('Lists', '${snap.error}', error: true);
          }
          final lists = snap.data!;
          return ListView(
            padding: pagePad,
            children: [
              const PageHead(
                'Lists',
                lede: 'How the bot picks what to buy at 11:10.',
              ),
              _ListSection(
                title: 'Buy first',
                note:
                    'Bought once at 11:10, even without a BUY signal. '
                    'Skipped while you hold it.',
                symbols: lists.buyFirst,
                first: true,
                onAdd: (s) =>
                    _change(() => widget.api.addToWatchlist('buy_first', s)),
                onRemove: (s) => _change(
                  () => widget.api.removeFromWatchlist('buy_first', s),
                ),
              ),
              _ListSection(
                title: 'Priority',
                note:
                    'One of these is bought per day when it has a BUY '
                    'signal, before other signals.',
                symbols: lists.priority,
                onAdd: (s) =>
                    _change(() => widget.api.addToWatchlist('priority', s)),
                onRemove: (s) => _change(
                  () => widget.api.removeFromWatchlist('priority', s),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ListSection extends StatefulWidget {
  const _ListSection({
    required this.title,
    required this.note,
    required this.symbols,
    required this.onAdd,
    required this.onRemove,
    this.first = false,
  });

  final String title;
  final String note;
  final List<String> symbols;
  final Future<void> Function(String symbol) onAdd;
  final Future<void> Function(String symbol) onRemove;
  final bool first;

  @override
  State<_ListSection> createState() => _ListSectionState();
}

class _ListSectionState extends State<_ListSection> {
  final _symbol = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _symbol.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final sym = _symbol.text.trim().toUpperCase();
    if (sym.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    await widget.onAdd(sym);
    if (!mounted) return;
    setState(() => _saving = false);
    _symbol.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '${widget.title} (${widget.symbols.length})',
          first: widget.first,
        ),
        Text(
          widget.note,
          style: T.sans(size: 12, color: T.faint, height: 16 / 12),
        ),
        const SizedBox(height: 12),
        if (widget.symbols.isEmpty)
          Text('Empty.', style: T.sans(color: T.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in widget.symbols)
                InputChip(
                  label: Text(s, style: T.mono(size: T.fsSm)),
                  onDeleted: () => widget.onRemove(s),
                  deleteButtonTooltipMessage: 'Remove $s',
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _symbol,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Symbol, e.g. NABIL',
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _saving ? null : _add,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}
