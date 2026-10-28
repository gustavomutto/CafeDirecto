// Validaciones que la app hace antes de enviar (las mismas reglas que aplica el servidor).

const minPasswordLength = 8;

/// null si la contraseña es válida; si no, el motivo en español e inglés.
String? passwordProblem(String p) {
  if (p.length < minPasswordLength || !RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) {
    return 'Mínimo $minPasswordLength caracteres, con letras y números · At least $minPasswordLength characters, letters and numbers';
  }
  return null;
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
bool isValidEmail(String e) => _email.hasMatch(e.trim());
