// Fotos de Unsplash usadas como placeholders. Si alguna no carga,
// el componente <Img> muestra un fondo de color con un ícono.
const u = (id, w = 900) =>
  `https://images.unsplash.com/photo-${id}?auto=format&fit=crop&w=${w}&q=70`;

export const PHOTOS = {
  // Paisajes / fincas
  mountains1: u('1464822759023-fed622ff2c3b'),
  mountains2: u('1506905925346-21bda4d32df4'),
  valley: u('1500530855697-b586d89ba3ee'),
  greenHills: u('1470071459604-3b5ec3a7fe05'),
  forest: u('1441974231531-c6227db76b6e'),
  lake: u('1501785888041-af3ef285b470'),
  nature: u('1469474968028-56623f02e42e'),
  // Café
  beans1: u('1447933601403-0c6688de566e'),
  beans2: u('1524350876685-274059332603'),
  beans3: u('1559056199-641a0ac8b55e'),
  roast: u('1442512595331-e89e73853f31'),
  cup1: u('1495474472287-4d71bcdd2085'),
  cup2: u('1509042239860-f550ce710b93'),
  cup3: u('1514432324607-a09d9b4aefdd'),
  // Cafeterías / tostadores
  shop1: u('1501339847302-ac426a4a7cbb'),
  shop2: u('1453614512568-c4024d13c247'),
  shop3: u('1554118811-1e0d58224f24'),
  shop4: u('1497935586351-b67a49e012bf'),
  // Personas (retratos)
  woman1: u('1494790108377-be9c29b29330', 300),
  woman2: u('1438761681033-6461ffad8d80', 300),
  woman3: u('1544005313-94ddf0286df2', 300),
  woman4: u('1534528741775-53994a69daeb', 300),
  man1: u('1507003211169-0a1dd7228f2d', 300),
  man2: u('1500648767791-00dcc994a43e', 300),
  man3: u('1472099645785-5658abf4ff4e', 300),
  man4: u('1506794778202-cad84cf45f1d', 300),
};

// Fotos que el caficultor puede "enviar" en el chat o adjuntar al publicar un lote
export const SHAREABLE_PHOTOS = [
  { src: PHOTOS.beans2, caption: { es: 'Café verde listo en bodega', en: 'Green coffee ready in storage' } },
  { src: PHOTOS.greenHills, caption: { es: 'Así se ve el cafetal hoy', en: 'This is the coffee plot today' } },
  { src: PHOTOS.beans1, caption: { es: 'Muestra tostada para catar', en: 'Roasted sample for cupping' } },
  { src: PHOTOS.roast, caption: { es: 'Secado lento en marquesina', en: 'Slow drying in the solar dryer' } },
];
