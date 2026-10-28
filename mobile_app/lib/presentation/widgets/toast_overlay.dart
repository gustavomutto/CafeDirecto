// Capa encima de todas las pantallas para los avisos breves (toasts).
import 'package:flutter/material.dart';

import '../providers/app_context.dart';

class ToastOverlay extends StatelessWidget {
  final Widget child;
  const ToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          left: 24,
          right: 24,
          bottom: mq.padding.bottom + 96,
          child: const Align(alignment: Alignment.bottomCenter, heightFactor: 1, child: ToastView()),
        ),
      ],
    );
  }
}

class ToastView extends StatelessWidget {
  const ToastView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final t = app.toast;
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: t == null
            ? const SizedBox.shrink()
            : Material(
                key: ValueKey(t.id),
                color: const Color(0xF21C1410),
                borderRadius: BorderRadius.circular(16),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(t.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Flexible(child: Text(t.text, style: p.text(size: 14, weight: FontWeight.w700, color: Colors.white))),
                  ]),
                ),
              ),
      ),
    );
  }
}
