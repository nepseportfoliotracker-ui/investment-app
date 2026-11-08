import 'package:flutter/material.dart';

import 'theme.dart';

/// Building blocks matching the backtesting app's portfolio page:
/// a page heading (h1 + lede), small uppercase section labels, big
/// figures in mono, underline tabs, and dense ruled rows.

const pagePad = EdgeInsets.fromLTRB(16, 24, 16, 96);

/// h1 + optional lede.
class PageHead extends StatelessWidget {
  const PageHead(this.title, {super.key, this.lede, this.trailing});

  final String title;
  final String? lede;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: T.sans(
                    size: T.fsXl,
                    height: 40 / 32,
                    weight: FontWeight.w600,
                    color: T.textStrong,
                    letterSpacing: -.02 * 32,
                  ),
                ),
                if (lede != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      lede!,
                      style: T.sans(color: T.muted, height: 24 / 13),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small uppercase label above a section (the reference's h3).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.first = false, this.trailing});

  final String text;
  final bool first;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 40, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: T.sans(
                size: T.fsXs,
                height: 16 / 11,
                weight: FontWeight.w600,
                color: T.muted,
                letterSpacing: .08 * 11,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class Fig {
  const Fig(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;
}

/// The big numbers of a section: mono value over a muted label, in a grid.
class Figures extends StatelessWidget {
  const Figures(this.items, {super.key, this.columns = 2});

  final List<Fig> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const gapX = 32.0;
        final w = (box.maxWidth - gapX * (columns - 1)) / columns;
        return Wrap(
          spacing: gapX,
          runSpacing: 24,
          children: [
            for (final f in items)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        f.value,
                        maxLines: 1,
                        style: T.mono(
                          size: T.fsLg,
                          height: 24 / 20,
                          weight: FontWeight.w500,
                          color: f.color ?? T.textStrong,
                          letterSpacing: -.01 * 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.label,
                      style: T.sans(size: 12, height: 16 / 12, color: T.muted),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Underline tabs (the reference's .seg).
class Seg<V> extends StatelessWidget {
  const Seg({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final V value;
  final List<(V, String)> options;
  final ValueChanged<V> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: T.line)),
      ),
      child: Row(
        children: [
          for (final (v, label) in options)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: InkWell(
                onTap: () => onChanged(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: v == value ? T.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    label,
                    style: T.sans(
                      weight: v == value ? FontWeight.w600 : FontWeight.w500,
                      color: v == value ? T.textStrong : T.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One table column: header text and alignment.
class Col {
  const Col(this.label, {this.numeric = true, this.flex = 1});

  final String label;
  final bool numeric;
  final int flex;
}

/// Dense table: faint header, rules between rows, numbers in mono.
/// The first column is the row's name (sans, bold).
class RuledTable extends StatelessWidget {
  const RuledTable({super.key, required this.columns, required this.rows});

  final List<Col> columns;
  final List<List<Widget>> rows;

  static Widget name(String s) => Text(
    s,
    style: T.sans(weight: FontWeight.w600, color: T.textStrong),
    overflow: TextOverflow.ellipsis,
  );

  static Widget num(String s, {Color? color}) => Text(
    s,
    style: T.mono(color: color ?? T.text, height: 16 / 12),
    maxLines: 1,
    overflow: TextOverflow.fade,
    softWrap: false,
  );

  Widget _row(List<Widget> cells, {bool header = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: T.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            Expanded(
              flex: columns[i].flex,
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 12),
                child: Align(
                  alignment: columns[i].numeric && i != 0
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: cells[i],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row([
          for (final c in columns)
            Text(
              c.label,
              style: T.sans(
                size: T.fsXs,
                weight: FontWeight.w500,
                color: T.faint,
              ),
            ),
        ], header: true),
        for (final r in rows) _row(r),
      ],
    );
  }
}

/// A short status line with a coloured rule on the left (notices).
class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.title,
    this.body,
    this.color = T.warn,
    this.action,
    this.onAction,
  });

  final String title;
  final String? body;
  final Color color;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: T.sans(weight: FontWeight.w600, color: T.textStrong),
                ),
                if (body != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      body!,
                      style: T.sans(size: 12, color: T.muted, height: 16 / 12),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// Text-only button in muted grey (the reference's .link).
class LinkButton extends StatelessWidget {
  const LinkButton(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(label),
  );
}

/// Loading / error / empty bodies that still allow pull-to-refresh.
Widget loadingBody() => ListView(
  children: const [
    SizedBox(
      height: 320,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
  ],
);

Widget messageBody(String title, String message, {bool error = false}) =>
    ListView(
      padding: pagePad,
      children: [
        PageHead(title),
        Text(
          message,
          style: T.sans(color: error ? T.down : T.muted, height: 24 / 13),
        ),
      ],
    );
