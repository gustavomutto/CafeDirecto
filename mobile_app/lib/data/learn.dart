// Contenido de la sección "Aprende" (RF-25 a RF-27). Bilingüe.
import 'package:flutter/material.dart';

import '../models/models.dart';

class LearnItem {
  final String id;
  final String section; // 'post' | 'export'
  final String icon;
  final Color color;
  final int minutes;
  final Bi title;
  final Bi summary;
  final List<Bi> steps;
  final Bi tip;
  const LearnItem({
    required this.id,
    required this.section,
    required this.icon,
    required this.color,
    required this.minutes,
    required this.title,
    required this.summary,
    required this.steps,
    required this.tip,
  });
}

const learnItems = <LearnItem>[
  LearnItem(
    id: 'fermentacion',
    section: 'post',
    icon: '🫙',
    color: Color(0xFFE9D8C4),
    minutes: 1,
    title: Bi('Fermentación controlada', 'Controlled fermentation'),
    summary: Bi('Mide el tiempo y la temperatura de cada tanda.', 'Track time and temperature for every batch.'),
    steps: [
      Bi('Despulpe el mismo día de la recolección.', 'Pulp the cherries the same day they are picked.'),
      Bi('Anote la hora de inicio y la temperatura del agua.', 'Write down the start time and water temperature.'),
      Bi('Revise cada 6 horas: el grano debe sentirse áspero, no baboso.', 'Check every 6 hours: beans should feel gritty, not slimy.'),
      Bi('Lave con agua limpia apenas termine.', 'Wash with clean water as soon as it is done.'),
    ],
    tip: Bi('Un registro simple en cuaderno aumenta la confianza del comprador.', 'A simple notebook log builds buyer confidence.'),
  ),
  LearnItem(
    id: 'secado',
    section: 'post',
    icon: '☀️',
    color: Color(0xFFF4E2B8),
    minutes: 1,
    title: Bi('Secado lento y parejo', 'Slow, even drying'),
    summary: Bi('Entre 10 % y 12 % de humedad es la meta.', 'Target 10–12% moisture content.'),
    steps: [
      Bi('Extienda el café en capas delgadas (2–3 cm).', 'Spread coffee in thin layers (2–3 cm).'),
      Bi('Revuélvalo varias veces al día.', 'Turn it several times a day.'),
      Bi('Cúbralo en la noche y con lluvia.', 'Cover it at night and when it rains.'),
      Bi('Mida la humedad antes de empacar.', 'Measure moisture before packing.'),
    ],
    tip: Bi('Secar muy rápido apaga los sabores dulces.', 'Drying too fast mutes sweet flavors.'),
  ),
  LearnItem(
    id: 'almacenamiento',
    section: 'post',
    icon: '📦',
    color: Color(0xFFDCE8D5),
    minutes: 1,
    title: Bi('Almacenamiento', 'Storage'),
    summary: Bi('Bolsas herméticas y bodega sin olores.', 'Hermetic bags and an odor-free warehouse.'),
    steps: [
      Bi('Use bolsas herméticas dentro del saco de fique.', 'Use hermetic liners inside the jute/fique bag.'),
      Bi('Ponga los sacos sobre estibas, no en el piso.', 'Place bags on pallets, never on the floor.'),
      Bi('Aleje el café de gasolina, abonos y humo.', 'Keep coffee away from fuel, fertilizer and smoke.'),
    ],
    tip: Bi('La muestra que envía debe ser igual al lote guardado.', 'The sample you send must match the stored lot.'),
  ),
  LearnItem(
    id: 'exportar',
    section: 'export',
    icon: '🚢',
    color: Color(0xFFD6E4EA),
    minutes: 2,
    title: Bi('Exportar paso a paso', 'Exporting step by step'),
    summary: Bi('De la muestra al barco en 6 pasos.', 'From sample to ship in 6 steps.'),
    steps: [
      Bi('Envíe muestra de 300 g y espere la catación del comprador.', 'Ship a 300 g sample and wait for the buyer’s cupping.'),
      Bi('Acuerde precio, cantidad y condiciones en CaféDirecto.', 'Agree on price, quantity and terms in CaféDirecto.'),
      Bi('Trille el café y empáquelo en sacos de 70 kg.', 'Mill the coffee and pack it in 70 kg bags.'),
      Bi('Su exportador aliado tramita los documentos de origen y fitosanitarios.', 'Your partner exporter handles origin and phytosanitary documents.'),
      Bi('El café sale del puerto (FOB) hacia el país del comprador.', 'Coffee leaves the port (FOB) for the buyer’s country.'),
      Bi('Al llegar, ambos se califican en la app.', 'On arrival, both parties rate each other in the app.'),
    ],
    tip: Bi('CaféDirecto no maneja pagos ni envíos: solo conecta y registra el acuerdo.',
        'CaféDirecto does not handle payments or shipping: it connects and records the agreement.'),
  ),
  LearnItem(
    id: 'precio',
    section: 'export',
    icon: '💲',
    color: Color(0xFFEADCF0),
    minutes: 1,
    title: Bi('Cómo poner su precio', 'How to set your price'),
    summary: Bi('Precio por libra vs. precio por carga.', 'Price per pound vs. price per carga.'),
    steps: [
      Bi('Los compradores internacionales piensan en dólares por libra (USD/lb).', 'International buyers think in US dollars per pound (USD/lb).'),
      Bi('Una carga son 125 kg de café pergamino seco.', 'One carga equals 125 kg of dry parchment coffee.'),
      Bi('La app convierte su precio por carga a USD/lb de forma aproximada.', 'The app converts your carga price to USD/lb approximately.'),
    ],
    tip: Bi('Su puntaje SCA y su historia justifican un mejor precio.', 'Your SCA score and your story justify a better price.'),
  ),
];

LearnItem? learnById(String id) {
  for (final l in learnItems) {
    if (l.id == id) return l;
  }
  return null;
}
