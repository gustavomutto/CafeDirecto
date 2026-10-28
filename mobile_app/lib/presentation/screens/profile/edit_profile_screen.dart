// Editar mis datos y el perfil de mi finca o empresa, con fotos reales.
// Los textos largos (historia, frase, "sobre nosotros") se escriben en tu idioma
// y el servidor los traduce automáticamente al otro idioma.
import 'package:flutter/material.dart';

import '../../../core/constants/catalog.dart';
import '../../../core/utils/media.dart';
import '../../../domain/entities/user.dart';
import '../../providers/app_context.dart';
import '../../widgets/buyer_type_chips.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_picker.dart';

int? _idFromUrl(String? url) => imageIdFromUrl(url);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final c = <String, TextEditingController>{};
  late String lang;
  String region = '';
  Set<String> vars = {};
  Set<String> procs = {};
  Set<String> notes = {};
  int? photoId;
  int? coverId;
  List<int> gallery = [];
  bool _busy = false;
  bool _init = false;

  TextEditingController _c(String k) => c.putIfAbsent(k, () => TextEditingController());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final app = context.session;
    final u = app.user!;
    lang = u.lang;
    _c('name').text = u.name;
    _c('phone').text = u.phone;
    photoId = _idFromUrl(u.photo);
    final f = app.farm;
    final b = app.buyer;
    if (f != null) {
      _c('farmName').text = f.name;
      region = f.region;
      _c('municipality').text = f.municipality;
      _c('altitude').text = f.altitude > 0 ? '${f.altitude}' : '';
      _c('hectares').text = f.hectares > 0 ? '${f.hectares}' : '';
      _c('sca').text = f.sca > 0 ? '${f.sca}' : '';
      _c('since').text = f.since?.toString() ?? '';
      _c('story').text = f.story.of(lang);
      _c('quote').text = f.quote.of(lang);
      _c('certifications').text = f.certifications.join('\n');
      vars = {...f.varieties};
      procs = {...f.processes};
      notes = {...f.notes};
      coverId = _idFromUrl(f.cover);
      gallery = f.gallery.map(_idFromUrl).whereType<int>().toList();
    }
    if (b != null) {
      _c('company').text = b.company;
      _c('city').text = b.city;
      _c('country').text = b.country;
      _c('type').text = b.type;
      _c('volume').text = b.volume;
      _c('since').text = b.since?.toString() ?? '';
      _c('about').text = b.about.of(lang);
      _c('looking').text = b.looking.of(lang);
      coverId = _idFromUrl(b.cover);
    }
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.session;
    setState(() => _busy = true);
    try {
      await app.updateAccount(AccountUpdate(name: _c('name').text.trim(), phone: _c('phone').text.trim(), lang: lang, photoId: photoId));
      if (app.isFarmer) {
        await app.updateFarmProfile(FarmProfileUpdate(
          lang: lang,
          name: _c('farmName').text.trim(),
          region: region,
          municipality: _c('municipality').text.trim(),
          altitude: int.tryParse(_c('altitude').text.trim()) ?? 0,
          hectares: double.tryParse(_c('hectares').text.trim().replaceAll(',', '.')) ?? 0,
          sca: double.tryParse(_c('sca').text.trim().replaceAll(',', '.')) ?? 0,
          since: int.tryParse(_c('since').text.trim()),
          varieties: vars.toList(),
          processes: procs.toList(),
          notes: notes.toList(),
          story: _c('story').text.trim(),
          quote: _c('quote').text.trim(),
          certifications: _c('certifications').text.trim(),
          coverId: coverId,
          gallery: gallery,
        ));
      } else {
        await app.updateBuyerProfile(BuyerProfileUpdate(
          lang: lang,
          company: _c('company').text.trim(),
          city: _c('city').text.trim(),
          country: _c('country').text.trim(),
          type: _c('type').text.trim(),
          volume: _c('volume').text.trim(),
          since: int.tryParse(_c('since').text.trim()),
          about: _c('about').text.trim(),
          looking: _c('looking').text.trim(),
          coverId: coverId,
        ));
      }
      app.showToast(app.tr('Perfil guardado y traducido', 'Profile saved and translated'));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      app.showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final farmer = app.isFarmer;
    String t(String es, String en) => app.tr(es, en);

    Widget field(String key, String label, {TextInputType? type, int lines = 1, String? hint}) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: p.text(size: p.fs - 2, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _c(key),
              keyboardType: lines > 1 ? TextInputType.multiline : type,
              maxLines: lines,
              minLines: 1,
              style: p.text(),
              decoration: InputDecoration(hintText: hint),
            ),
          ]),
        );

    Widget chips(Set<String> set, Map<String, String> options) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in options.entries)
              ChipBtn(e.value, active: set.contains(e.key), onTap: () => setState(() => set.contains(e.key) ? set.remove(e.key) : set.add(e.key))),
          ]),
        );

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text, style: p.text(size: p.fs - 2, weight: FontWeight.w700)),
        );

    Widget img(String? url) => NetImg(url);
    String? u(int? id) => id == null ? null : '/images/$id';

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: t('Editar perfil', 'Edit profile')),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
              SectionTitle(t('Mis datos', 'My details')),
              Row(children: [
                SizedBox(
                  width: 96,
                  child: PhotoSlot(
                    url: u(photoId),
                    height: 96,
                    label: t('Foto', 'Photo'),
                    preview: img,
                    onTap: () async {
                      final id = await pickAndUpload(context);
                      if (id != null) setState(() => photoId = id);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(children: [
                    field('name', t('Nombre', 'Name')),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              field('phone', t('Celular', 'Phone'), type: TextInputType.phone),
              label(t('Idioma de la app', 'App language')),
              Segmented(options: const {'es': '🇪🇸 Español', 'en': '🇺🇸 English'}, value: lang, onChanged: (v) => setState(() => lang = v)),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  t('Escribe tus textos en este idioma; se traducen solos al otro.', 'Write your texts in this language; they are translated automatically.'),
                  style: p.muted(size: 13),
                ),
              ),
              SectionTitle(farmer ? t('Mi finca', 'My farm') : t('Mi empresa', 'My company')),
              label(t('Foto de portada', 'Cover photo')),
              PhotoSlot(
                url: u(coverId),
                label: t('Agregar foto de portada', 'Add cover photo'),
                preview: img,
                onTap: () async {
                  final id = await pickAndUpload(context);
                  if (id != null) setState(() => coverId = id);
                },
                onRemove: coverId == null ? null : () => setState(() => coverId = null),
              ),
              const SizedBox(height: 14),
              if (farmer) ...[
                field('farmName', t('Nombre de la finca', 'Farm name')),
                label(t('Departamento', 'Region')),
                DropdownButtonFormField<String>(
                  initialValue: regions.contains(region) ? region : null,
                  hint: Text(t('Elige…', 'Choose…')),
                  items: [for (final r in regions) DropdownMenuItem(value: r, child: Text(r, style: p.text()))],
                  onChanged: (v) => setState(() => region = v ?? region),
                ),
                const SizedBox(height: 14),
                field('municipality', t('Municipio', 'Municipality')),
                Row(children: [
                  Expanded(child: field('altitude', t('Altitud (m)', 'Altitude (m)'), type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: field('hectares', t('Hectáreas', 'Hectares'), type: const TextInputType.numberWithOptions(decimal: true))),
                ]),
                Row(children: [
                  Expanded(child: field('sca', t('Puntaje SCA', 'SCA score'), type: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(child: field('since', t('Cultivando desde (año)', 'Growing since (year)'), type: TextInputType.number)),
                ]),
                label(t('Variedades', 'Varieties')),
                chips(vars, {for (final v in varieties) v: v}),
                label(t('Procesos', 'Processes')),
                chips(procs, {for (final e in processes.entries) e.key: '${e.value.icon} ${e.value.of(app.lang)}'}),
                label(t('Notas de catación', 'Cupping notes')),
                chips(notes, {for (final e in notesCatalog.entries) e.key: e.value.of(app.lang)}),
                field('story', t('Nuestra historia', 'Our story'), lines: 6,
                    hint: t('Cuenta quiénes son, cómo cultivan y qué hace especial su café.', 'Tell who you are and what makes your coffee special.')),
                field('quote', t('Una frase que los represente', 'A short quote'), lines: 2),
                field('certifications', t('Certificaciones (una por línea)', 'Certifications (one per line)'), lines: 3,
                    hint: 'Denominación de Origen · Café de Huila'),
                label(t('Galería de fotos (hasta 8)', 'Photo gallery (up to 8)')),
                SizedBox(
                  height: 100,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (var i = 0; i < gallery.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 120,
                          child: PhotoSlot(
                            url: u(gallery[i]),
                            height: 100,
                            label: '',
                            preview: img,
                            onTap: () {},
                            onRemove: () => setState(() => gallery.removeAt(i)),
                          ),
                        ),
                      ),
                    if (gallery.length < 8)
                      SizedBox(
                        width: 120,
                        child: PhotoSlot(
                          url: null,
                          height: 100,
                          label: t('Agregar', 'Add'),
                          preview: img,
                          onTap: () async {
                            final id = await pickAndUpload(context);
                            if (id != null) setState(() => gallery.add(id));
                          },
                        ),
                      ),
                  ]),
                ),
              ] else ...[
                field('company', t('Empresa', 'Company')),
                Row(children: [
                  Expanded(child: field('city', t('Ciudad', 'City'))),
                  const SizedBox(width: 10),
                  Expanded(child: field('country', t('País', 'Country'))),
                ]),
                field('type', t('Tipo de comprador', 'Buyer type'), hint: t('Tostador, cafetería, importador…', 'Roaster, café, importer…')),
                BuyerTypeChips(controller: _c('type'), lang: app.lang),
                Row(children: [
                  Expanded(child: field('volume', t('Volumen (sacos/año)', 'Volume (bags/year)'))),
                  const SizedBox(width: 10),
                  Expanded(child: field('since', t('Comprando desde', 'Buying since'), type: TextInputType.number)),
                ]),
                field('about', t('Sobre nosotros', 'About us'), lines: 5),
                field('looking', t('Qué buscamos', 'What we look for'), lines: 3),
              ],
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: ScreenFooter(children: [
        Expanded(child: Btn(_busy ? t('Guardando…', 'Saving…') : t('Guardar', 'Save'), icon: Icons.check_rounded, large: true, block: true, onPressed: _busy ? null : _save)),
      ]),
    );
  }
}
