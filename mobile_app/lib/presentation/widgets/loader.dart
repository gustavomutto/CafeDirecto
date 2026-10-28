// Carga datos de la API y muestra carga / error / contenido.
import 'package:flutter/material.dart';

import 'common.dart';

class Loader<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  /// Cuando cambia, se vuelve a cargar (por ejemplo `app.dataVersion`).
  final Object? reloadKey;

  /// Si se da, se envuelve la pantalla de error/carga con esto (por ejemplo un Scaffold con barra superior).
  final Widget Function(Widget child)? frame;

  const Loader({super.key, required this.load, required this.builder, this.reloadKey, this.frame});

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant Loader<T> old) {
    super.didUpdateWidget(old);
    if (old.reloadKey != widget.reloadKey) _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frame ?? (Widget c) => c;
    if (_data != null) return widget.builder(context, _data as T, _reload);
    if (_loading) return frame(const LoadingView());
    return frame(ErrorRetry(error: _error ?? 'Error', onRetry: _reload));
  }
}
