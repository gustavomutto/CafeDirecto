/// Texto bilingüe (español / inglés). Si falta un idioma se muestra el otro.
class Bi {
  final String es;
  final String en;
  const Bi(this.es, this.en);

  static const empty = Bi('', '');

  String of(String lang) {
    final v = lang == 'es' ? es : en;
    return v.isNotEmpty ? v : (lang == 'es' ? en : es);
  }

  bool get isEmpty => es.isEmpty && en.isEmpty;
}
