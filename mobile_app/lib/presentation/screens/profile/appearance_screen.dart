// Apariencia: idioma, modo de color (claro, neutro, oscuro o automático), color principal y tamaño de letra.
// Todo se aplica al instante; la vista previa de arriba muestra cómo queda.
import 'package:flutter/material.dart';

import '../../../core/theme/appearance.dart';
import '../../../core/theme/palette.dart';
import '../../providers/app_context.dart';
import '../../widgets/common.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final look = context.appearance;
    final p = context.pal;
    String t(String es, String en) => app.tr(es, en);

    Widget label(String text, [String? hint]) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: p.display(size: p.farmer ? 20 : 18)),
            if (hint != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(hint, style: p.muted(size: 13))),
          ]),
        );

    final modes = <ThemeChoice, (String, IconData)>{
      ThemeChoice.light: (t('Claro', 'Light'), Icons.light_mode_outlined),
      ThemeChoice.neutral: (t('Neutro', 'Neutral'), Icons.contrast_rounded),
      ThemeChoice.dark: (t('Oscuro', 'Dark'), Icons.dark_mode_outlined),
      ThemeChoice.system: (t('Automático', 'Automatic'), Icons.brightness_auto_outlined),
    };
    final accents = <AccentChoice, String>{
      AccentChoice.cafe: t('Café', 'Coffee'),
      AccentChoice.verde: t('Verde', 'Green'),
      AccentChoice.azul: t('Azul', 'Blue'),
      AccentChoice.vino: t('Vino', 'Wine'),
      AccentChoice.terracota: t('Terracota', 'Terracotta'),
    };

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: t('Apariencia', 'Appearance'), subtitle: t('Idioma, colores y letra', 'Language, colors and text')),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
              const _Preview(),

              label(t('Idioma', 'Language'), t('Cambia toda la app. Los mensajes que recibas llegan traducidos a este idioma.',
                  'Changes the whole app. Messages you receive are translated into this language.')),
              Segmented(
                options: const {'es': '🇪🇸 Español', 'en': '🇺🇸 English'},
                value: app.lang,
                onChanged: context.session.setLang,
              ),

              label(t('Modo', 'Mode'), look.theme == ThemeChoice.system ? t('Sigue el modo claro u oscuro de tu teléfono.', 'Follows your phone light or dark mode.') : null),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  for (final e in modes.entries)
                    _ModeCard(
                      label: e.value.$1,
                      icon: e.value.$2,
                      mode: e.key,
                      selected: look.theme == e.key,
                      onTap: () => look.setTheme(e.key),
                    ),
                ],
              ),

              label(t('Color principal', 'Main color'), t('Botones, títulos y elementos destacados.', 'Buttons, titles and highlights.')),
              Wrap(spacing: 14, runSpacing: 12, children: [
                for (final e in accents.entries)
                  _Swatch(
                    color: accentSwatch(e.key, farmer: p.farmer, dark: p.dark),
                    label: e.value,
                    selected: look.accent == e.key,
                    onTap: () => look.setAccent(e.key),
                  ),
              ]),

              label(t('Tamaño de la letra', 'Text size')),
              Segmented(
                options: {
                  TextSizeChoice.normal.name: t('Normal', 'Normal'),
                  TextSizeChoice.large.name: t('Grande', 'Large'),
                  TextSizeChoice.xlarge.name: t('Muy grande', 'Extra large'),
                },
                value: look.textSize.name,
                onChanged: (v) => look.setTextSize(TextSizeChoice.values.byName(v)),
              ),

              const SizedBox(height: 26),
              Btn(
                t('Restablecer apariencia', 'Reset appearance'),
                kind: BtnKind.ghost,
                icon: Icons.restart_alt_rounded,
                block: true,
                onPressed: look.settings == AppearanceSettings.defaults
                    ? null
                    : () {
                        look.reset();
                        app.showToast(t('Apariencia original', 'Original appearance'));
                      },
              ),
              const SizedBox(height: 8),
              Text(t('La apariencia se guarda en este teléfono.', 'Appearance is saved on this phone.'),
                  textAlign: TextAlign.center, style: p.muted(size: 12)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Muestra en pequeño una tarjeta, un botón y una etiqueta con los colores actuales.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    return CardBox(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.warmSoft, shape: BoxShape.circle),
            child: const Text('☕', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pink Bourbon · Huila', style: p.display(size: 18)),
              Text(app.tr('Así se ven tus pantallas', 'This is how your screens look'), style: p.muted(size: 13)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(99)),
            child: Text('88 SCA', style: p.text(size: 12, weight: FontWeight.w800, color: p.accent)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Btn(app.tr('Escribir', 'Message'), icon: Icons.chat_bubble_outline_rounded, small: true, block: true, onPressed: () {})),
          const SizedBox(width: 8),
          Expanded(child: Btn(app.tr('Ver lote', 'View lot'), kind: BtnKind.outline, small: true, block: true, onPressed: () {})),
        ]),
      ]),
    );
  }
}

/// Tarjeta de un modo con una mini muestra de sus colores.
class _ModeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeChoice mode;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({required this.label, required this.icon, required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final look = context.appearance;
    final role = p.farmer ? 'farmer' : 'buyer';
    // El automático muestra mitad claro y mitad oscuro.
    final a = resolvePalette(role, mode: mode == ThemeChoice.system ? ThemeChoice.light : mode, accent: look.accent);
    final b = mode == ThemeChoice.system ? resolvePalette(role, mode: ThemeChoice.dark, accent: look.accent) : a;

    Widget half(Palette q) => Expanded(
          child: Container(
            color: q.bg,
            padding: const EdgeInsets.all(6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(height: 6, width: 34, decoration: BoxDecoration(color: q.ink, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 4),
              Container(height: 5, width: 22, decoration: BoxDecoration(color: q.ink2, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 6),
              Container(height: 10, width: 30, decoration: BoxDecoration(color: q.primary, borderRadius: BorderRadius.circular(4))),
            ]),
          ),
        );

    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(p.radiusSm),
        side: BorderSide(color: selected ? p.primary : p.line, width: selected ? 2.2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(children: [
          Expanded(child: Row(children: [half(a), if (mode == ThemeChoice.system) half(b)])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              Icon(icon, size: 18, color: selected ? p.primary : p.ink2),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: p.text(size: p.fs - 2, weight: FontWeight.w800, color: selected ? p.primary : p.ink))),
              if (selected) Icon(Icons.check_circle_rounded, size: 18, color: p.primary),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch({required this.color, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? p.ink : Colors.transparent, width: 2)),
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: p.line)),
              child: selected ? Icon(Icons.check_rounded, size: 20, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white) : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: p.text(size: 12, weight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? p.ink : p.ink2)),
        ]),
      ),
    );
  }
}
