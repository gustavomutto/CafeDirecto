// Sugerencias para el tipo de comprador: al tocar una, se escribe en el campo en el idioma de la app.
// Como el perfil muestra el tipo con buyerTypeLabel, se ve traducido al cambiar de idioma.
import 'package:flutter/material.dart';

import '../../core/constants/catalog.dart';
import '../providers/app_context.dart';

class BuyerTypeChips extends StatelessWidget {
  final TextEditingController controller;
  final String lang;
  const BuyerTypeChips({super.key, required this.controller, required this.lang});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final selected = buyerTypeKey(value.text);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in buyerTypes.entries)
              ChoiceChip(
                label: Text(e.value.of(lang)),
                selected: selected == e.key,
                showCheckmark: false,
                labelStyle: p.text(size: p.fs - 3, weight: FontWeight.w700, color: selected == e.key ? p.primaryInk : p.ink),
                selectedColor: p.primary,
                backgroundColor: p.surface,
                side: BorderSide(color: selected == e.key ? p.primary : p.line),
                onSelected: (_) => controller.text = e.value.of(lang),
              ),
          ]),
        );
      },
    );
  }
}
