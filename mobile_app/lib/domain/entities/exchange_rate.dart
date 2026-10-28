// Tasas de cambio frente al dólar.

class ExchangeRateSnapshot {
  final Map<String, double> rates;
  final DateTime updatedAt;

  const ExchangeRateSnapshot({required this.rates, required this.updatedAt});
}

class LatinAmericanCountry {
  final String code;
  final String currency;
  final String currencySpanish;
  final String currencyEnglish;
  final String spanish;
  final String english;

  const LatinAmericanCountry({
    required this.code,
    required this.currency,
    required this.currencySpanish,
    required this.currencyEnglish,
    required this.spanish,
    required this.english,
  });

  String name(String lang) => lang == 'es' ? spanish : english;
  String currencyName(String lang) => lang == 'es' ? currencySpanish : currencyEnglish;
}
