// Estado de una subasta abierta en pantalla: la carga, la actualiza cada 5 s mientras está en vivo
// y ejecuta las acciones (pujar, adjudicar, cancelar).
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/auction.dart';
import '../../domain/repositories/auction_repository.dart';

class AuctionDetailController extends ChangeNotifier {
  AuctionDetailController(this._repo, this.auctionId);

  final AuctionRepository _repo;
  final int auctionId;

  Auction? auction;
  Object? error;
  bool busy = false;
  Timer? _timer;
  bool _disposed = false;

  Future<void> load() async {
    try {
      auction = await _repo.get(auctionId);
      error = null;
      _schedule();
    } catch (e) {
      error = e;
    }
    _notify();
  }

  void _schedule() {
    _timer?.cancel();
    if (auction?.isOpen ?? false) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    if (busy) return;
    try {
      final a = await _repo.get(auctionId);
      final changed = a.bids.length != auction?.bids.length || a.phase != auction?.phase || a.endsAt != auction?.endsAt;
      auction = a;
      if (!a.isOpen) _timer?.cancel();
      if (changed) _notify();
    } catch (_) {
      // sin conexión momentánea: se reintenta en el siguiente ciclo
    }
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    busy = true;
    _notify();
    try {
      return await action();
    } finally {
      busy = false;
      _notify();
    }
  }

  /// Oferta en US$/lb. Lanza ApiException si el servidor la rechaza (por ejemplo, la superaron antes).
  Future<void> bid(double priceLb) => _run(() async {
        auction = await _repo.bid(auctionId, priceLb);
        AppLogger.i('Oferta enviada: $priceLb US\$/lb en la subasta $auctionId', tag: 'Subasta');
        _schedule();
      });

  /// Elige la oferta ganadora. Devuelve el id del acuerdo creado.
  Future<int> award(int bidId) => _run(() async {
        final agreementId = await _repo.award(auctionId, bidId);
        auction = await _repo.get(auctionId);
        _timer?.cancel();
        AppLogger.i('Subasta $auctionId adjudicada → acuerdo $agreementId', tag: 'Subasta');
        return agreementId;
      });

  Future<void> cancel() => _run(() async {
        auction = await _repo.cancel(auctionId);
        _timer?.cancel();
      });

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
