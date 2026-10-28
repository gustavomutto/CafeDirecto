// Reglas sobre fotos que usan varias rutas.
const { many } = require('../db');
const { bad } = require('../lib/http');

/**
 * Verifica que las fotos existan y sean de quien las usa. Así nadie puede poner en su perfil,
 * su lote o un mensaje la foto privada de otra persona (por ejemplo, una del chat ajeno).
 */
async function assertOwnImages(userId, ids) {
  const list = [...new Set((ids || []).filter((x) => Number.isInteger(x) && x > 0))];
  if (!list.length) return;
  const rows = await many('SELECT id FROM images WHERE id = ANY($1) AND owner_id = $2', [list, userId]);
  if (rows.length !== list.length) throw bad('Una de las fotos no existe o no es tuya. Vuelve a subirla.');
}

module.exports = { assertOwnImages };
