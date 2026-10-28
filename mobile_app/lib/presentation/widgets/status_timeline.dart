// Línea de estado Cotizado → Confirmado → Enviado → Entregado.
import 'package:flutter/material.dart';

import '../../core/constants/catalog.dart';
import '../providers/app_context.dart';
import '../../core/utils/format.dart';

class StatusTimeline extends StatelessWidget {
  final int status;
  final List<int> history;
  final bool vertical;
  const StatusTimeline({super.key, required this.status, this.history = const [], this.vertical = false});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;

    Widget dot(int i, double size) {
      final done = i < status;
      final current = i == status;
      final icon = done ? Icons.check_rounded : statusSteps[i].icon;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? p.accent : (current ? p.warm : p.surface2),
          border: Border.all(color: done ? p.accent : (current ? p.warm : p.line), width: 2),
        ),
        child: Icon(icon, size: size * 0.55, color: (done || current) ? Colors.white : p.ink2),
      );
    }

    if (vertical) {
      return Column(
        children: [
          for (var i = 0; i < statusSteps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(children: [
                    dot(i, 34),
                    if (i < statusSteps.length - 1)
                      Expanded(
                        child: Container(width: 3, color: i < status ? p.accent : p.line, margin: const EdgeInsets.symmetric(vertical: 2)),
                      ),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(statusSteps[i].of(app.lang),
                              style: p.text(weight: i <= status ? FontWeight.w800 : FontWeight.w600, color: i <= status ? p.ink : p.ink2)),
                          if (i < history.length && history[i] > 0) Text(fmtDate(history[i], app.lang), style: p.muted(size: p.fs - 4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < statusSteps.length; i++)
            Expanded(
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : (i <= status ? p.accent : p.line))),
                    dot(i, 24),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == statusSteps.length - 1 ? Colors.transparent : (i < status ? p.accent : p.line),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    statusSteps[i].of(app.lang),
                    textAlign: TextAlign.center,
                    style: p.text(
                      size: 11,
                      weight: i == status ? FontWeight.w800 : FontWeight.w600,
                      color: i <= status ? p.ink : p.ink2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
