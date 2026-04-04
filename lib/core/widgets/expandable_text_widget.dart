import 'package:flutter/material.dart';

/// A text widget that shows at most [maxLines] lines and provides
/// a tappable "Read more" / "Read less" toggle.
///
/// Usage:
///   ExpandableText(
///     text: longDescription,
///     maxLines: 2,
///     style: TextStyle(fontSize: 12, color: Colors.grey),
///   )
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final String expandText;
  final String collapseText;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.style,
    this.linkStyle,
    this.expandText = 'Read more',
    this.collapseText = 'Read less',
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Determine whether the text actually overflows at maxLines
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 32);

    final didOverflow = textPainter.didExceedMaxLines;

    // If text fits, render it as-is — no toggle needed
    if (!didOverflow) {
      return Text(widget.text, style: widget.style);
    }

    final toggleStyle =
        widget.linkStyle ??
        TextStyle(
          fontSize: (widget.style?.fontSize ?? 12) - 0.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1565C0), // blue link colour
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _expanded ? null : widget.maxLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? widget.collapseText : widget.expandText,
            style: toggleStyle,
          ),
        ),
      ],
    );
  }
}
