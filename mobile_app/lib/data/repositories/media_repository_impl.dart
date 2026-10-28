import 'dart:typed_data';

import '../../domain/repositories/media_repository.dart';
import '../datasources/remote/media_remote_datasource.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaRemoteDataSource _remote;
  MediaRepositoryImpl(this._remote);

  @override
  Future<int> upload(Uint8List bytes, String filename) => _remote.upload(bytes, filename);
}
