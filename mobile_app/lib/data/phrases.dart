// Frases rápidas bilingües para el chat. Se envían en el idioma de quien escribe
// y el servidor las traduce para la otra persona.
class Template {
  final String id;
  final String icon;
  final String es;
  final String en;
  const Template(this.id, this.icon, this.es, this.en);
  String of(String lang) => lang == 'es' ? es : en;
}

const templates = <String, List<Template>>{
  'farmer': [
    Template('t1', '📦', 'Tengo muestra disponible', 'I have a sample available'),
    Template('t2', '⚖️', '¿Cuál es su volumen?', 'What volume are you looking for?'),
    Template('t3', '📷', 'Le envío fotos del lote', "I'm sending you photos of the lot"),
    Template('t4', '🚚', 'Puedo enviar la muestra esta semana', 'I can ship the sample this week'),
    Template('t5', '✅', 'El café está listo para despacho', 'The coffee is ready to ship'),
    Template('t6', '🙏', 'Gracias por su interés en mi café', 'Thank you for your interest in my coffee'),
  ],
  'buyer': [
    Template('b1', '👋', '¡Hola! Me encanta el perfil de su café.', 'Hi! I love your coffee profile.'),
    Template('b2', '📦', '¿Podría enviar una muestra de 300 g?', 'Could you send a 300 g sample?'),
    Template('b3', '💲', '¿Cuál es su precio por libra?', 'What is your price per pound?'),
    Template('b4', '⚖️', '¿Cuántos sacos puede ofrecer?', 'How many bags can you offer?'),
    Template('b5', '🚢', '¿Cuándo podría despacharse?', 'When could it ship?'),
    Template('b6', '⭐', '¡La muestra salió hermosa en taza!', 'The sample cupped beautifully!'),
    Template('b7', '🤝', 'Trabajemos juntos también la próxima cosecha.', "Let's work together next harvest too."),
  ],
};
