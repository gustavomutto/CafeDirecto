// Burbujas del chat: texto con traducción, foto, cotización, acuerdo y mensajes del sistema.
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_scope.dart';
import '../utils/format.dart';
import 'agreement_card.dart';
import 'common.dart';
import 'quote_card.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final QuoteHandlers handlers;
  final Agreement? agreement; // para mensajes de tipo 'agreement'
  final VoidCallback? onOpenPhoto;
  const MessageBubble({super.key, required this.msg, required this.handlers, this.agreement, this.onOpenPhoto});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;

    if (msg.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(99)),
            child: Text(app.pick(msg.sys), textAlign: TextAlign.center, style: p.muted(size: 12, weight: FontWeight.w600)),
          ),
        ),
      );
    }

    if (msg.type == 'agreement') {
      if (agreement == null) {
        return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      }
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: AgreementCard(agreement: agreement!, inChat: true));
    }

    final mine = msg.senderId == app.user?.id;
    final ink = mine ? p.primaryInk : p.ink;
    final footer = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (msg.viaVoice) ...[
          Icon(Icons.mic_none_rounded, size: 12, color: (mine && msg.type != 'quote') ? ink.withValues(alpha: 0.7) : p.ink2),
          const SizedBox(width: 3),
        ],
        Text(fmtTime(msg.createdAt, lang), style: p.text(size: 11, color: (mine && msg.type != 'quote') ? ink.withValues(alpha: 0.7) : p.ink2)),
        if (mine) ...[
          const SizedBox(width: 4),
          if (msg.pending)
            Icon(Icons.schedule_rounded, size: 12, color: p.warm)
          else
            Icon(Icons.done_all_rounded, size: 14, color: msg.type == 'quote' ? p.accent : const Color(0xFF8FD3A8)),
        ],
      ]),
    );

    if (msg.type == 'quote' && msg.quote != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [QuoteCard(msg: msg, handlers: handlers), footer],
        ),
      );
    }

    final text = (msg.text ?? '').trim();
    final hasTranslation = (msg.translation ?? '').trim().isNotEmpty && msg.translation != msg.text;
    final foreign = msg.lang != null && msg.lang != lang;

    final content = <Widget>[
      if (msg.type == 'photo')
        GestureDetector(
          onTap: onOpenPhoto,
          child: NetImg(msg.photo, height: 200, width: 240, fallback: '📷', radius: BorderRadius.circular(p.radiusSm - 4)),
        ),
      if (msg.type == 'photo' && text.isNotEmpty) const SizedBox(height: 6),
      if (text.isNotEmpty)
        Text(
          text,
          style: p.text(
            size: foreign && hasTranslation ? p.fs - 2 : p.fs,
            color: foreign && hasTranslation ? ink.withValues(alpha: 0.75) : ink,
            weight: FontWeight.w600,
          ),
        ),
      if (text.isNotEmpty && hasTranslation) _TranslationBlock(msg: msg, mine: mine),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          child: Opacity(
            opacity: msg.pending ? 0.7 : 1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: mine ? p.primary : p.surface,
                border: mine ? null : Border.all(color: p.line),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(p.radius),
                  topRight: Radius.circular(p.radius),
                  bottomLeft: Radius.circular(mine ? p.radius : 6),
                  bottomRight: Radius.circular(mine ? 6 : p.radius),
                ),
              ),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [...content, Align(alignment: Alignment.centerRight, child: footer)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TranslationBlock extends StatelessWidget {
  final ChatMessage msg;
  final bool mine;
  const _TranslationBlock({required this.msg, required this.mine});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final from = msg.lang ?? 'es';
    final String label;
    if (from == lang) {
      label = from == 'es' ? 'Traducido al inglés' : 'Translated to Spanish';
    } else {
      label = from == 'en' ? 'Traducido del inglés' : 'Translated from Spanish';
    }
    final forMe = from != lang;
    final ink = mine ? p.primaryInk : p.ink;
    final bg = mine ? Colors.white.withValues(alpha: 0.12) : (forMe ? p.accentSoft : p.surface2);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.translate_rounded, size: 13, color: mine ? ink.withValues(alpha: 0.75) : p.accent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label, style: p.text(size: 11, weight: FontWeight.w700, color: mine ? ink.withValues(alpha: 0.75) : p.accent)),
          ),
        ]),
        const SizedBox(height: 3),
        Text(msg.translation ?? '',
            style: p.text(size: forMe ? p.fs : p.fs - 2, weight: forMe ? FontWeight.w700 : FontWeight.w500, color: ink)),
      ]),
    );
  }
}
