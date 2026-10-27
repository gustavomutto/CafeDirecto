// Calificación mutua tras la entrega — RF-20, RF-21.
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_scope.dart';
import '../theme/palette.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/loader.dart';

const _labels = {
  'es': ['', 'Malo', 'Regular', 'Bueno', 'Muy bueno', '¡Excelente!'],
  'en': ['', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent!'],
};

class RateAgreementScreen extends StatelessWidget {
  final int agreementId;
  const RateAgreementScreen({super.key, required this.agreementId});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    return Loader<Agreement>(
      load: () async => Agreement.fromJson(await app.api.get('/agreements/$agreementId') as Map),
      frame: (c) => Scaffold(backgroundColor: p.bg, body: SafeArea(child: Column(children: [const TopBar(), Expanded(child: c)]))),
      builder: (context, a, _) => _RateForm(agreement: a),
    );
  }
}

class _RateForm extends StatefulWidget {
  final Agreement agreement;
  const _RateForm({required this.agreement});

  @override
  State<_RateForm> createState() => _RateFormState();
}

class _RateFormState extends State<_RateForm> {
  bool _busy = false;
  int stars = 0;
  final Set<String> tags = {};
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final a = widget.agreement;
    final name = app.isFarmer ? a.buyerName : a.farmerName;
    final sub = app.isFarmer ? a.buyerDisplay : a.farmDisplay;
    final photo = app.isFarmer ? a.buyerPhoto : a.farmerPhoto;

    Future<void> submit() async {
      setState(() => _busy = true);
      try {
        await app.api.post('/agreements/${a.id}/rate', {'stars': stars, 'tags': tags.toList(), 'comment': _comment.text.trim()});
        app.showToast(app.tr('¡Gracias por calificar!', 'Thanks for your rating!'), '⭐');
        app.touch();
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        app.showError(e);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: app.tr('Calificar', 'Rate')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Center(child: Avatar(src: photo, name: name, size: 88)),
                const SizedBox(height: 10),
                Text(name, textAlign: TextAlign.center, style: p.display(size: 26)),
                Text('$sub · ${a.code}', textAlign: TextAlign.center, style: p.muted()),
                const SizedBox(height: 22),
                Text(app.tr('¿Cómo te fue con este negocio?', 'How was this deal?'),
                    textAlign: TextAlign.center, style: p.text(size: p.fs + 1, weight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      iconSize: 46,
                      onPressed: () => setState(() => stars = i),
                      icon: Icon(stars >= i ? Icons.star_rounded : Icons.star_outline_rounded, color: Palette.star),
                    ),
                ]),
                SizedBox(
                  height: 28,
                  child: Text(_labels[app.lang]![stars], textAlign: TextAlign.center, style: p.text(weight: FontWeight.w800, color: p.warm)),
                ),
                const SizedBox(height: 10),
                Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                  for (final t in tagsFor[app.role]!)
                    ChipBtn(app.pick(ratingTags[t]),
                        active: tags.contains(t), onTap: () => setState(() => tags.contains(t) ? tags.remove(t) : tags.add(t))),
                ]),
                const SizedBox(height: 18),
                TextField(
                  controller: _comment,
                  maxLines: 3,
                  style: p.text(),
                  decoration: InputDecoration(hintText: app.tr('Comentario (opcional)', 'Comment (optional)')),
                ),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: ScreenFooter(children: [
        Expanded(
          child: Btn(app.tr('Enviar calificación', 'Submit rating'),
              icon: Icons.check_rounded, large: true, block: true, onPressed: (stars == 0 || _busy) ? null : submit),
        ),
      ]),
    );
  }
}
