import 'dart:typed_data';

abstract class MediaRepository {
  /// Sube una foto y devuelve su id.
  Future<int> upload(Uint8List bytes, String filename);
}
