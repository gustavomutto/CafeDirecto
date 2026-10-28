// Elegir una foto (galería o cámara), reducirla y subirla al servidor.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/repositories/media_repository.dart';
import '../providers/app_context.dart';

final _picker = ImagePicker();

/// Pregunta si usar cámara o galería y devuelve la imagen elegida (o null).
Future<XFile?> chooseImage(BuildContext context) async {
  final app = context.session;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(app.tr('Elegir de la galería', 'Choose from gallery')),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: Text(app.tr('Tomar una foto', 'Take a photo')),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
      ]),
    ),
  );
  if (source == null) return null;
  try {
    return await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
  } catch (_) {
    app.showToast(app.tr('No se pudo abrir la cámara o la galería', 'Could not open camera or gallery'), '⚠️');
    return null;
  }
}

/// Sube una imagen y devuelve su id en el servidor (o null si falló).
Future<int?> uploadImage(BuildContext context, XFile file) async {
  final app = context.session;
  final media = context.repo<MediaRepository>();
  try {
    final bytes = await file.readAsBytes();
    return await media.upload(bytes, file.name.isEmpty ? 'foto.jpg' : file.name);
  } catch (e) {
    app.showError(e);
    return null;
  }
}

/// Elige y sube en un solo paso. Devuelve el id de la imagen.
Future<int?> pickAndUpload(BuildContext context) async {
  final app = context.session;
  final f = await chooseImage(context);
  if (f == null) return null;
  app.showToast(app.tr('Subiendo foto…', 'Uploading photo…'), '⏫');
  if (!context.mounted) return null;
  final id = await uploadImage(context, f);
  if (id != null) app.showToast(app.tr('Foto lista', 'Photo ready'), '📷');
  return id;
}

/// Recuadro para elegir/cambiar una foto, mostrando la actual.
class PhotoSlot extends StatelessWidget {
  final String? url; // ruta actual en el servidor (/images/…)
  final String label;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final Widget Function(String? url) preview;
  const PhotoSlot({
    super.key,
    required this.url,
    required this.label,
    required this.onTap,
    required this.preview,
    this.onRemove,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(p.radiusSm),
          border: Border.all(color: p.line),
        ),
        child: url == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_outlined, size: 30, color: p.ink2),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center, style: p.muted(size: 13, weight: FontWeight.w700)),
              ])
            : Stack(fit: StackFit.expand, children: [
                preview(url),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(99)),
                    child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ]),
      ),
    );
  }
}
