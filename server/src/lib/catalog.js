// Catálogos que la app descarga al abrirse (así un cambio aquí se ve sin reinstalar la app).
//
// Regiones cafeteras: la lista base está aquí. Para agregar una sin tocar el código,
// en Railway → Variables crea REGIONS con los nombres separados por comas, por ejemplo:
//     REGIONS=Antioquia,Caldas,Santander
// y se suman a la lista (sin repetir). "Sierra Nevada" es la Sierra Nevada de Santa Marta.
const BASE_REGIONS = ['Huila', 'Nariño', 'Cauca', 'Quindío', 'Tolima', 'Cesar', 'Sierra Nevada'];

function regions(extra = process.env.REGIONS) {
  const more = String(extra || '').split(',').map((s) => s.trim()).filter(Boolean);
  const out = [];
  const seen = new Set();
  for (const r of [...BASE_REGIONS, ...more]) {
    const key = r.toLowerCase();
    if (!seen.has(key) && r.length <= 60) {
      seen.add(key);
      out.push(r);
    }
  }
  return out;
}

module.exports = { regions, BASE_REGIONS };
