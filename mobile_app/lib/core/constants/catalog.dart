// Catálogos compartidos: regiones, variedades, procesos, notas de catación,
// condiciones de entrega, estados del pedido y etiquetas de calificación.
import 'package:flutter/material.dart';

import '../../domain/entities/bi.dart';

const regions = ['Huila', 'Nariño', 'Cauca', 'Quindío', 'Tolima', 'Sierra Nevada'];

const varieties = ['Castillo', 'Caturra', 'Geisha', 'Pink Bourbon', 'Colombia'];

class Process {
  final String key;
  final String es;
  final String en;
  final String icon;
  const Process(this.key, this.es, this.en, this.icon);
  String of(String lang) => lang == 'es' ? es : en;
}

const processes = <String, Process>{
  'lavado': Process('lavado', 'Lavado', 'Washed', '💧'),
  'honey': Process('honey', 'Honey', 'Honey', '🍯'),
  'natural': Process('natural', 'Natural', 'Natural', '🍒'),
};

const notesCatalog = <String, Bi>{
  'panela': Bi('Panela', 'Panela'),
  'mandarina': Bi('Mandarina', 'Tangerine'),
  'cacao': Bi('Cacao', 'Cacao'),
  'chocolate': Bi('Chocolate', 'Chocolate'),
  'caramelo': Bi('Caramelo', 'Caramel'),
  'floral': Bi('Floral', 'Floral'),
  'citrico': Bi('Cítrico', 'Citrus'),
  'durazno': Bi('Durazno', 'Peach'),
  'miel': Bi('Miel', 'Honey'),
  'jazmin': Bi('Jazmín', 'Jasmine'),
  'bergamota': Bi('Bergamota', 'Bergamot'),
  'frutosrojos': Bi('Frutos rojos', 'Red berries'),
  'vino': Bi('Vino', 'Winey'),
  'nuez': Bi('Nuez', 'Walnut'),
  'manzana': Bi('Manzana verde', 'Green apple'),
};

const incoterms = <String, Bi>{
  'FOB Buenaventura': Bi('FOB Buenaventura', 'FOB Buenaventura'),
  'FOB Cartagena': Bi('FOB Cartagena', 'FOB Cartagena'),
  'EXW Finca': Bi('En la finca (EXW)', 'Ex-farm (EXW)'),
};

class StatusStep {
  final String key;
  final String es;
  final String en;
  final IconData icon;
  const StatusStep(this.key, this.es, this.en, this.icon);
  String of(String lang) => lang == 'es' ? es : en;
}

const statusSteps = [
  StatusStep('quoted', 'Cotizado', 'Quoted', Icons.sell_outlined),
  StatusStep('confirmed', 'Confirmado', 'Confirmed', Icons.handshake_outlined),
  StatusStep('shipped', 'Enviado', 'Shipped', Icons.local_shipping_outlined),
  StatusStep('delivered', 'Entregado', 'Delivered', Icons.check_rounded),
];

const ratingTags = <String, Bi>{
  'quality': Bi('Calidad igual a la muestra', 'Matched the sample'),
  'communication': Bi('Buena comunicación', 'Great communication'),
  'payment': Bi('Pagó a tiempo', 'Paid on time'),
  'punctual': Bi('Cumplió los tiempos', 'On time'),
  'transparent': Bi('Transparente', 'Transparent'),
  'packaging': Bi('Buen empaque', 'Good packaging'),
};

/// Etiquetas que ve cada rol al calificar a la otra parte.
const tagsFor = <String, List<String>>{
  'farmer': ['payment', 'communication', 'transparent', 'punctual'], // el caficultor califica al comprador
  'buyer': ['quality', 'communication', 'packaging', 'punctual'], // el comprador califica al caficultor
};

/// Modelo de comisiones (ajustable).
const feeFarmer = 0.02;
const feeBuyer = 0.04;

/// Tipos de comprador. El campo es texto libre (versiones anteriores guardaban lo que la persona
/// escribía), así que [buyerTypeLabel] reconoce la clave o el nombre en cualquiera de los dos idiomas.
const buyerTypes = <String, Bi>{
  'roaster': Bi('Tostador', 'Roaster'),
  'roasting_plant': Bi('Planta de tostado', 'Roasting plant'),
  'cafe': Bi('Cafetería', 'Coffee shop'),
  'importer': Bi('Importador', 'Importer'),
  'exporter': Bi('Exportador', 'Exporter'),
  'distributor': Bi('Distribuidor', 'Distributor'),
  'retail': Bi('Tienda de café', 'Coffee retailer'),
  'trader': Bi('Comercializador', 'Trader'),
};

String _norm(String s) => s
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[áà]'), 'a')
    .replaceAll(RegExp('[éè]'), 'e')
    .replaceAll(RegExp('[íì]'), 'i')
    .replaceAll(RegExp('[óò]'), 'o')
    .replaceAll(RegExp('[úù]'), 'u');

/// Clave del catálogo para un tipo escrito a mano (o null si no es uno conocido).
String? buyerTypeKey(String raw) {
  final n = _norm(raw);
  if (n.isEmpty) return null;
  for (final e in buyerTypes.entries) {
    if (n == e.key || n == _norm(e.value.es) || n == _norm(e.value.en)) return e.key;
  }
  return null;
}

/// El tipo de comprador en el idioma pedido; si es un texto propio, se muestra tal cual.
String buyerTypeLabel(String raw, String lang) {
  final k = buyerTypeKey(raw);
  return k == null ? raw : buyerTypes[k]!.of(lang);
}
