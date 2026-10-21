// Componentes reutilizables: imágenes, avatar, estrellas, botones, chips,
// stepper, barra superior, hoja inferior, etc.
import 'package:flutter/material.dart';

import '../config.dart';
import '../state/app_scope.dart';
import '../theme/palette.dart';
import '../utils/format.dart';

/// Imagen de internet con respaldo: si la URL falla, muestra un fondo café con un ícono.
class NetImg extends StatelessWidget {
  final String? src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallback;
  final BorderRadius? radius;

  const NetImg(this.src, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.fallback = '☕', this.radius});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget fb() => Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.primary2, p.primary],
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(fallback, style: p.text(size: 22, color: p.primaryInk, weight: FontWeight.w800)),
            ),
          ),
        );
    final url = mediaUrl(src);
    Widget img = url == null
        ? fb()
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => fb(),
            loadingBuilder: (ctx, child, progress) =>
                progress == null ? child : Container(width: width, height: height, color: p.surface2),
          );
    if (radius != null) img = ClipRRect(borderRadius: radius!, child: img);
    return img;
  }
}

class Avatar extends StatelessWidget {
  final String? src;
  final String name;
  final double size;
  final bool ring;
  const Avatar({super.key, this.src, this.name = '', this.size = 44, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join();
    final p = context.pal;
    return Container(
      width: size,
      height: size,
      padding: ring ? const EdgeInsets.all(3) : EdgeInsets.zero,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring ? p.surface : null),
      child: ClipOval(child: NetImg(src, width: size, height: size, fallback: initials)),
    );
  }
}

class Stars extends StatelessWidget {
  final double value;
  final double size;
  final bool showValue;
  final int? count;
  const Stars({super.key, required this.value, this.size = 14, this.showValue = false, this.count});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(value >= i - 0.25 ? Icons.star_rounded : Icons.star_outline_rounded, size: size + 2, color: Palette.star),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(value.toStringAsFixed(1), style: p.text(size: size, weight: FontWeight.w800)),
        ],
        if (count != null) ...[
          const SizedBox(width: 3),
          Text('($count)', style: p.muted(size: size - 1)),
        ],
      ],
    );
  }
}

class ScoreBadge extends StatelessWidget {
  final double sca;
  final bool large;
  const ScoreBadge({super.key, required this.sca, this.large = false});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 8 : 5),
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(large ? 14 : 10),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(fmtSca(sca), style: p.display(size: large ? 24 : 16, color: Colors.white, height: 1)),
          Text('SCA', style: p.text(size: large ? 10 : 8, weight: FontWeight.w800, color: Colors.white70)),
        ],
      ),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  final String? label;
  const VerifiedBadge({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (label == null) return Icon(Icons.verified_rounded, size: 16, color: p.accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_user_outlined, size: 15, color: p.accent),
        const SizedBox(width: 5),
        Text(label!, style: p.text(size: 13, weight: FontWeight.w700, color: p.accent)),
      ]),
    );
  }
}

enum BtnKind { primary, outline, ghost, light, demo }

/// Botón de la app (variantes: primario, contorno, fantasma, claro, demo).
class Btn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailing;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final bool large;
  final bool block;
  final bool small;

  const Btn(
    this.label, {
    super.key,
    this.icon,
    this.trailing,
    this.onPressed,
    this.kind = BtnKind.primary,
    this.large = false,
    this.block = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    late Color bg, fg;
    BorderSide side = BorderSide.none;
    switch (kind) {
      case BtnKind.primary:
        bg = p.primary;
        fg = p.primaryInk;
        break;
      case BtnKind.outline:
        bg = p.surface;
        fg = p.primary;
        side = BorderSide(color: p.primary, width: 1.6);
        break;
      case BtnKind.ghost:
        bg = p.surface2;
        fg = p.ink;
        break;
      case BtnKind.light:
        bg = Colors.white;
        fg = p.primary;
        break;
      case BtnKind.demo:
        bg = p.warmSoft;
        fg = p.warm;
        side = BorderSide(color: p.warm.withValues(alpha: 0.5), width: 1.2);
        break;
    }
    final h = small ? 38.0 : (large ? p.btnH + 4 : p.btnH);
    final disabled = onPressed == null;
    final text = Text(
      label,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: p.text(size: small ? 13 : (large ? p.fs + 1 : p.fs), weight: FontWeight.w800, color: fg),
    );
    final content = LayoutBuilder(
      builder: (context, c) => Row(
        mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: small ? 16 : 20, color: fg), const SizedBox(width: 8)],
          // Flexible solo si el ancho está acotado (si no, Flutter lanza un error de layout)
          c.hasBoundedWidth ? Flexible(child: text) : text,
          if (trailing != null) ...[const SizedBox(width: 6), Icon(trailing, size: small ? 16 : 20, color: fg)],
        ],
      ),
    );
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(p.radiusSm), side: side),
        child: InkWell(
          borderRadius: BorderRadius.circular(p.radiusSm),
          onTap: onPressed,
          child: Container(
            height: h,
            width: block ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: small ? 12 : 18),
            alignment: block ? Alignment.center : null,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Chip seleccionable.
class ChipBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool big;
  const ChipBtn(this.label, {super.key, this.active = false, this.onTap, this.big = false});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: active ? p.primary : p.surface,
      shape: StadiumBorder(side: BorderSide(color: active ? p.primary : p.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: big ? 18 : 14, vertical: big ? 12 : 8),
          child: Text(label, style: p.text(size: big ? p.fs : p.fs - 2, weight: FontWeight.w700, color: active ? p.primaryInk : p.ink)),
        ),
      ),
    );
  }
}

/// Etiqueta no interactiva (notas de catación, etiquetas de calificación).
class NoteChip extends StatelessWidget {
  final String label;
  const NoteChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: p.warmSoft, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: p.text(size: p.fs - 3, weight: FontWeight.w700, color: p.primary)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(text, style: p.display(size: p.farmer ? 21 : 19)),
    );
  }
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: color ?? p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(p.radius), side: BorderSide(color: p.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Control − valor + con botones grandes.
class QtyStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final String Function(double)? format;
  final String? label;

  const QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 9999,
    this.format,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget btn(IconData icon, bool enabled, double next) => Material(
          color: enabled ? p.primary : p.surface2,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? () => onChanged(round2(next)) : null,
            child: SizedBox(
              width: p.btnH,
              height: p.btnH,
              child: Icon(icon, size: 26, color: enabled ? p.primaryInk : p.ink2),
            ),
          ),
        );
    final shown = format != null ? format!(value) : (value % 1 == 0 ? value.toStringAsFixed(0) : value.toString());
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(p.radius),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          btn(Icons.remove_rounded, value > min, value - step < min ? min : value - step),
          Expanded(
            child: Column(
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(shown, style: p.display(size: 26))),
                if (label != null) Text(label!, textAlign: TextAlign.center, style: p.muted(size: p.fs - 3)),
              ],
            ),
          ),
          btn(Icons.add_rounded, value < max, value + step > max ? max : value + step),
        ],
      ),
    );
  }
}

/// Barra superior de cada pantalla.
class TopBar extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? right;
  final Widget? child;
  final bool transparent;
  final bool back;

  const TopBar({super.key, this.title, this.subtitle, this.right, this.child, this.transparent = false, this.back = true});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    Widget backBtn() => transparent
        ? Material(
            color: Colors.black.withValues(alpha: 0.35),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: app.tr('Volver', 'Back'),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          )
        : IconButton(
            tooltip: app.tr('Volver', 'Back'),
            icon: Icon(Icons.arrow_back_rounded, color: p.ink, size: 26),
            onPressed: () => Navigator.of(context).maybePop(),
          );
    return Container(
      color: transparent ? Colors.transparent : p.surface,
      padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
      child: Row(
        children: [
          if (back) backBtn() else const SizedBox(width: 12),
          const SizedBox(width: 4),
          Expanded(
            child: child ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.text(size: p.fs + 1, weight: FontWeight.w800)),
                    if (subtitle != null) Text(subtitle!, style: p.muted(size: p.fs - 3)),
                  ],
                ),
          ),
          if (right != null) right!,
        ],
      ),
    );
  }
}

/// Selector segmentado (por ejemplo ES / EN).
class Segmented extends StatelessWidget {
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final bool small;
  const Segmented({super.key, required this.options, required this.value, required this.onChanged, this.small = false});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(p.radiusSm)),
      child: Row(
        mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max,
        children: options.entries.map((e) {
          final active = e.key == value;
          final cell = GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: small ? 14 : 10, vertical: small ? 6 : 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? p.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(p.radiusSm - 3),
                boxShadow: active ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))] : null,
              ),
              child: Text(e.value,
                  textAlign: TextAlign.center,
                  style: p.text(size: small ? 13 : p.fs - 2, weight: FontWeight.w800, color: active ? p.ink : p.ink2)),
            ),
          );
          return small ? cell : Expanded(child: cell);
        }).toList(),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String? text;
  final Widget? action;
  const EmptyState({super.key, this.icon = '☕', required this.title, this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: p.display(size: 20)),
          if (text != null) ...[const SizedBox(height: 6), Text(text!, textAlign: TextAlign.center, style: p.muted())],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final bool big;
  const CountBadge(this.count, {super.key, this.color, this.big = false});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      constraints: BoxConstraints(minWidth: big ? 26 : 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color ?? p.danger, borderRadius: BorderRadius.circular(99)),
      child: Text(count > 9 ? '9+' : '$count',
          textAlign: TextAlign.center, style: p.text(size: big ? 13 : 11, weight: FontWeight.w800, color: Colors.white)),
    );
  }
}

/// Ficha de dato (ícono + etiqueta + valor). Se usa en cuadrículas de 2 columnas.
class Spec {
  final IconData icon;
  final String label;
  final String value;
  final bool wide;
  const Spec(this.icon, this.label, this.value, {this.wide = false});
}

class SpecGrid extends StatelessWidget {
  final List<Spec> specs;
  const SpecGrid(this.specs, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return LayoutBuilder(builder: (context, c) {
      const gap = 10.0;
      final half = (c.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: specs
            .map((s) => Container(
                  width: s.wide ? c.maxWidth : half,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(p.radiusSm),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(s.icon, size: 18, color: p.warm),
                      const SizedBox(height: 4),
                      Text(s.label, style: p.muted(size: p.fs - 4)),
                      Text(s.value, style: p.text(size: p.fs - 1, weight: FontWeight.w800)),
                    ],
                  ),
                ))
            .toList(),
      );
    });
  }
}

/// Texto pequeño con ícono de información.
class FinePrint extends StatelessWidget {
  final String text;
  const FinePrint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline_rounded, size: 14, color: p.ink2)),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: p.muted(size: p.fs - 4))),
      ]),
    );
  }
}

/// Caja de total ("Total del negocio: US$ …").
class TotalBox extends StatelessWidget {
  final String label;
  final String value;
  const TotalBox(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(p.radiusSm)),
      child: Row(children: [
        Expanded(child: Text(label, style: p.text(weight: FontWeight.w700, color: p.accent))),
        Text(value, style: p.display(size: 22, color: p.accent)),
      ]),
    );
  }
}

/// Barra inferior fija de una pantalla (botones de acción).
class ScreenFooter extends StatelessWidget {
  final List<Widget> children;
  const ScreenFooter({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.line))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              children[i],
            ],
          ]),
        ),
      ),
    );
  }
}

/// Abre una hoja inferior con título, cuerpo desplazable y pie opcional.
/// [body] y [footer] reciben un `setSheet` para refrescar la hoja.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext ctx, StateSetter setSheet) body,
  Widget Function(BuildContext ctx, StateSetter setSheet)? footer,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
      final p = ctx.pal;
      return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(p.radius + 6)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 42, height: 5, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(9))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(children: [
                Expanded(child: Text(title, style: p.display(size: 22))),
                IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close_rounded, color: p.ink)),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: body(ctx, setSheet),
              ),
            ),
            if (footer != null)
              Container(
                decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.line))),
                child: SafeArea(
                  top: false,
                  child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), child: footer(ctx, setSheet)),
                ),
              ),
            if (footer == null) SafeArea(top: false, child: const SizedBox(height: 4)),
          ],
        ),
      );
    }),
  );
}

/// Sección de filtro/título dentro de una hoja.
class SheetLabel extends StatelessWidget {
  final String text;
  final String? trailing;
  const SheetLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(children: [
        Expanded(child: Text(text, style: p.text(weight: FontWeight.w800))),
        if (trailing != null) Text(trailing!, style: p.text(weight: FontWeight.w800, color: p.accent)),
      ]),
    );
  }
}


/// Pantalla de carga.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: context.pal.primary)));
  }
}

/// Mensaje de error con botón para reintentar.
class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return EmptyState(
      icon: '📡',
      title: app.tr('No se pudo cargar', 'Could not load'),
      text: error.toString(),
      action: Btn(app.tr('Reintentar', 'Retry'), icon: Icons.refresh_rounded, kind: BtnKind.outline, onPressed: onRetry),
    );
  }
}
