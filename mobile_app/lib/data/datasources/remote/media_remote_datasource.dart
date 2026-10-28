// Subida de fotos.
import 'dart:typed_data';

import '../../../core/network/api_client.dart';

class MediaRemoteDataSource {
  final ApiClient _api;
  MediaRemoteDataSource(this._api);

  Future<int> upload(Uint8List bytes, String filename) => _api.uploadImage(bytes, filename);
}
