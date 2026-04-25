import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 3x3 pattern input: calls [onPatternComplete] when the user lifts their finger
/// after connecting at least [minLength] dots (default 4).
class AppPatternPad extends StatefulWidget {
  const AppPatternPad({
    super.key,
    this.minLength = 4,
    required this.onPatternComplete,
    this.errorPulse = false,
  });

  final int minLength;
  final void Function(List<int> path) onPatternComplete;
  final bool errorPulse;

  @override
  State<AppPatternPad> createState() => _AppPatternPadState();
}

class _AppPatternPadState extends State<AppPatternPad> with SingleTickerProviderStateMixin {
  final List<int> _path = [];
  Offset? _current;
  late AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void didUpdateWidget(covariant AppPatternPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorPulse && !oldWidget.errorPulse) {
      _shake.forward(from: 0);
      _path.clear();
      _current = null;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  int? _hitTest(Offset local, double cell, double pad) {
    for (var i = 0; i < 9; i++) {
      final cx = pad + (i % 3) * cell + cell / 2;
      final cy = pad + (i ~/ 3) * cell + cell / 2;
      final d = (local - Offset(cx, cy)).distance;
      if (d < cell * 0.35) return i;
    }
    return null;
  }

  void _addDot(int i) {
    if (_path.isEmpty || _path.last != i) {
      setState(() => _path.add(i));
    }
  }

  void _finish() {
    final p = List<int>.from(_path);
    _current = null;
    _path.clear();
    setState(() {});
    if (p.length >= widget.minLength) {
      widget.onPatternComplete(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    const pad = 12.0;
    final cell = (size - pad * 2) / 3;

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * 6 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            setState(() {
              _path.clear();
              _current = e.localPosition;
              final hit = _hitTest(e.localPosition, cell, pad);
              if (hit != null) _addDot(hit);
            });
          },
          onPointerMove: (e) {
            setState(() {
              _current = e.localPosition;
              final hit = _hitTest(e.localPosition, cell, pad);
              if (hit != null) _addDot(hit);
            });
          },
          onPointerUp: (_) => _finish(),
          onPointerCancel: (_) => _finish(),
          child: CustomPaint(
            painter: _PatternPainter(
              path: _path,
              current: _current,
              cell: cell,
              pad: pad,
              errorColor: widget.errorPulse ? Colors.redAccent : null,
            ),
            size: const Size(size, size),
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.path,
    required this.current,
    required this.cell,
    required this.pad,
    this.errorColor,
  });

  final List<int> path;
  final Offset? current;
  final double cell;
  final double pad;
  final Color? errorColor;

  Offset _center(int i) {
    final cx = pad + (i % 3) * cell + cell / 2;
    final cy = pad + (i ~/ 3) * cell + cell / 2;
    return Offset(cx, cy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = (errorColor ?? Colors.blue).withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotFill = Paint()..color = Colors.grey.shade300;
    final dotBorder = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 9; i++) {
      final c = _center(i);
      canvas.drawCircle(c, 10, dotFill);
      canvas.drawCircle(c, 10, dotBorder);
    }

    if (path.length > 1) {
      final pts = path.map(_center).toList();
      for (var i = 0; i < pts.length - 1; i++) {
        canvas.drawLine(pts[i], pts[i + 1], linePaint);
      }
    }

    if (current != null && path.isNotEmpty) {
      canvas.drawLine(_center(path.last), current!, linePaint);
    }

    for (final i in path) {
      final c = _center(i);
      canvas.drawCircle(c, 14, Paint()..color = (errorColor ?? Colors.blue).withValues(alpha: 0.35));
      canvas.drawCircle(c, 8, Paint()..color = errorColor ?? Colors.blue);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.current != current ||
        oldDelegate.errorColor != errorColor;
  }
}
