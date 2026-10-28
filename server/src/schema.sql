

CREATE TABLE IF NOT EXISTS images (
  id          SERIAL PRIMARY KEY,
  owner_id    INTEGER,
  mime        TEXT NOT NULL,
  data        BYTEA NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS users (
  id             SERIAL PRIMARY KEY,
  email          TEXT NOT NULL UNIQUE,
  password_hash  TEXT NOT NULL,
  role           TEXT NOT NULL CHECK (role IN ('farmer','buyer')),
  name           TEXT NOT NULL,
  phone          TEXT,
  lang           TEXT NOT NULL DEFAULT 'es' CHECK (lang IN ('es','en')),
  photo_id       INTEGER REFERENCES images(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Perfil de finca (caficultor). Los textos largos se guardan en los dos idiomas.
CREATE TABLE IF NOT EXISTS farms (
  user_id       INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL DEFAULT '',
  region        TEXT NOT NULL DEFAULT '',
  municipality  TEXT NOT NULL DEFAULT '',
  altitude      INTEGER NOT NULL DEFAULT 0,
  hectares      NUMERIC NOT NULL DEFAULT 0,
  varieties     TEXT[] NOT NULL DEFAULT '{}',
  processes     TEXT[] NOT NULL DEFAULT '{}',
  sca           NUMERIC NOT NULL DEFAULT 0,
  notes         TEXT[] NOT NULL DEFAULT '{}',
  since         INTEGER,
  story_es      TEXT NOT NULL DEFAULT '',
  story_en      TEXT NOT NULL DEFAULT '',
  quote_es      TEXT NOT NULL DEFAULT '',
  quote_en      TEXT NOT NULL DEFAULT '',
  certifications TEXT NOT NULL DEFAULT '',
  cover_id      INTEGER REFERENCES images(id) ON DELETE SET NULL,
  gallery       INTEGER[] NOT NULL DEFAULT '{}'
);

-- Perfil de comprador.
CREATE TABLE IF NOT EXISTS buyers (
  user_id     INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  company     TEXT NOT NULL DEFAULT '',
  city        TEXT NOT NULL DEFAULT '',
  country     TEXT NOT NULL DEFAULT '',
  type        TEXT NOT NULL DEFAULT '',
  volume      TEXT NOT NULL DEFAULT '',
  since       INTEGER,
  about_es    TEXT NOT NULL DEFAULT '',
  about_en    TEXT NOT NULL DEFAULT '',
  looking_es  TEXT NOT NULL DEFAULT '',
  looking_en  TEXT NOT NULL DEFAULT '',
  cover_id    INTEGER REFERENCES images(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS lots (
  id          SERIAL PRIMARY KEY,
  farmer_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  variety     TEXT NOT NULL,
  process     TEXT NOT NULL,
  sacks       INTEGER NOT NULL CHECK (sacks >= 0),
  sca         NUMERIC NOT NULL,
  price_lb    NUMERIC NOT NULL,
  price_carga INTEGER,
  notes       TEXT[] NOT NULL DEFAULT '{}',
  harvest     TEXT NOT NULL DEFAULT '',
  photo_id    INTEGER REFERENCES images(id) ON DELETE SET NULL,
  active      BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS conversations (
  id               SERIAL PRIMARY KEY,
  farmer_id        INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  buyer_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lot_id           INTEGER REFERENCES lots(id) ON DELETE SET NULL,
  farmer_last_read INTEGER NOT NULL DEFAULT 0,
  buyer_last_read  INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (farmer_id, buyer_id)
);

CREATE TABLE IF NOT EXISTS agreements (
  id               SERIAL PRIMARY KEY,
  code             TEXT NOT NULL UNIQUE,
  conversation_id  INTEGER REFERENCES conversations(id) ON DELETE SET NULL,
  farmer_id        INTEGER NOT NULL REFERENCES users(id),
  buyer_id         INTEGER NOT NULL REFERENCES users(id),
  lot_id           INTEGER REFERENCES lots(id) ON DELETE SET NULL,
  lot_name         TEXT NOT NULL,
  variety          TEXT NOT NULL,
  process          TEXT NOT NULL,
  sca              NUMERIC NOT NULL,
  price_lb         NUMERIC NOT NULL,
  sacks            INTEGER NOT NULL,
  incoterm         TEXT NOT NULL,
  status           INTEGER NOT NULL DEFAULT 1,
  history          JSONB NOT NULL DEFAULT '[]',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- type: text | photo | quote | agreement | system
CREATE TABLE IF NOT EXISTS messages (
  id               SERIAL PRIMARY KEY,
  conversation_id  INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id        INTEGER REFERENCES users(id) ON DELETE SET NULL,
  type             TEXT NOT NULL,
  text             TEXT,
  lang             TEXT,
  translation      TEXT,
  translated_to    TEXT,
  via_voice        BOOLEAN NOT NULL DEFAULT false,
  photo_id         INTEGER REFERENCES images(id) ON DELETE SET NULL,
  quote            JSONB,
  agreement_id     INTEGER REFERENCES agreements(id) ON DELETE SET NULL,
  sys_es           TEXT,
  sys_en           TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS messages_conv_idx ON messages (conversation_id, id);

CREATE TABLE IF NOT EXISTS ratings (
  agreement_id  INTEGER NOT NULL REFERENCES agreements(id) ON DELETE CASCADE,
  by_user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stars         INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
  tags          TEXT[] NOT NULL DEFAULT '{}',
  comment_es    TEXT,
  comment_en    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (agreement_id, by_user_id)
);

-- Reporte de calidad que emite el comprador después de la entrega — RF-22.
CREATE TABLE IF NOT EXISTS quality_reports (
  agreement_id    INTEGER PRIMARY KEY REFERENCES agreements(id) ON DELETE CASCADE,
  by_user_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sca             NUMERIC NOT NULL CHECK (sca BETWEEN 0 AND 100),
  moisture        NUMERIC CHECK (moisture BETWEEN 0 AND 100),
  defects         INTEGER CHECK (defects >= 0),
  matches_sample  BOOLEAN NOT NULL DEFAULT true,
  notes           TEXT[] NOT NULL DEFAULT '{}',
  comment_es      TEXT,
  comment_en      TEXT,
  photo_id        INTEGER REFERENCES images(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Disputas sobre un acuerdo — RF-19.
-- events: [{ by, kind: 'open'|'comment'|'resolve', es, en, photo, at }]
CREATE TABLE IF NOT EXISTS disputes (
  id            SERIAL PRIMARY KEY,
  agreement_id  INTEGER NOT NULL REFERENCES agreements(id) ON DELETE CASCADE,
  opened_by     INTEGER REFERENCES users(id) ON DELETE SET NULL,
  reason        TEXT NOT NULL CHECK (reason IN ('quality','quantity','delay','payment','other')),
  status        TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','resolved')),
  events        JSONB NOT NULL DEFAULT '[]',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at   TIMESTAMPTZ
);
-- Solo una disputa abierta por acuerdo
CREATE UNIQUE INDEX IF NOT EXISTS disputes_open_idx ON disputes (agreement_id) WHERE status = 'open';

-- ── v1.3: seguridad de cuentas ────────────────────────────────────
-- Cuenta eliminada: se borran sus datos personales y queda solo lo necesario
-- para los acuerdos que la otra parte ya tiene registrados.
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
-- Sube al cambiar la contraseña; invalida las sesiones abiertas.
ALTER TABLE users ADD COLUMN IF NOT EXISTS token_version INTEGER NOT NULL DEFAULT 0;

-- Código de recuperación de contraseña (uno vigente por usuario, guardado con hash).
CREATE TABLE IF NOT EXISTS password_resets (
  user_id     INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  code_hash   TEXT NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  attempts    INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── v2: subastas, notificaciones, interés en lotes y mercado ──────
-- Subasta de un lote con fecha de cierre. Solo una abierta por lote.
CREATE TABLE IF NOT EXISTS auctions (
  id                SERIAL PRIMARY KEY,
  lot_id            INTEGER NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  farmer_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  base_price_lb     NUMERIC NOT NULL CHECK (base_price_lb > 0),
  min_increment_lb  NUMERIC NOT NULL DEFAULT 0.05 CHECK (min_increment_lb > 0),
  sacks             INTEGER NOT NULL CHECK (sacks > 0),
  incoterm          TEXT NOT NULL DEFAULT 'FOB Buenaventura',
  ends_at           TIMESTAMPTZ NOT NULL,
  status            TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','awarded','cancelled','expired')),
  winning_bid_id    INTEGER,
  agreement_id      INTEGER REFERENCES agreements(id) ON DELETE SET NULL,
  ended_notified    BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at         TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS auctions_open_lot_idx ON auctions (lot_id) WHERE status = 'open';

-- Ofertas (pujas). Cada oferta queda registrada; al cerrar se marcan como ganadora o perdedora.
CREATE TABLE IF NOT EXISTS bids (
  id          SERIAL PRIMARY KEY,
  auction_id  INTEGER NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  buyer_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  price_lb    NUMERIC NOT NULL CHECK (price_lb > 0),
  status      TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','won','lost')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS bids_auction_idx ON bids (auction_id, price_lb DESC);

-- Notificaciones de la campanita.
CREATE TABLE IF NOT EXISTS notifications (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL,
  title_es    TEXT NOT NULL,
  body_es     TEXT NOT NULL DEFAULT '',
  title_en    TEXT NOT NULL,
  body_en     TEXT NOT NULL DEFAULT '',
  data        JSONB NOT NULL DEFAULT '{}',
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS notifications_user_idx ON notifications (user_id, id DESC);

-- Compradores que vieron un lote (para avisar al caficultor que hay interés).
CREATE TABLE IF NOT EXISTS lot_views (
  lot_id       INTEGER NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  buyer_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  views        INTEGER NOT NULL DEFAULT 1,
  first_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  notified_at  TIMESTAMPTZ,
  PRIMARY KEY (lot_id, buyer_id)
);

-- Registro diario de precios (para el histórico del precio interno).
CREATE TABLE IF NOT EXISTS market_snapshots (
  day            DATE PRIMARY KEY,
  fnc_cop_carga  INTEGER,
  ny_usd_cents   NUMERIC,
  trm            NUMERIC,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── v3 (auditoría): índices para las consultas frecuentes ─────────
-- Llaves foráneas sin índice hacen lentos los filtros y los borrados en cascada.
CREATE INDEX IF NOT EXISTS lots_farmer_idx          ON lots (farmer_id) WHERE active;
CREATE INDEX IF NOT EXISTS lots_active_created_idx  ON lots (created_at DESC) WHERE active AND sacks > 0;
CREATE INDEX IF NOT EXISTS conversations_buyer_idx  ON conversations (buyer_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS conversations_farmer_idx ON conversations (farmer_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS agreements_farmer_idx    ON agreements (farmer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS agreements_buyer_idx     ON agreements (buyer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ratings_by_user_idx      ON ratings (by_user_id);
CREATE INDEX IF NOT EXISTS lot_views_buyer_idx      ON lot_views (buyer_id);
CREATE INDEX IF NOT EXISTS bids_buyer_idx           ON bids (buyer_id);
CREATE INDEX IF NOT EXISTS auctions_farmer_idx      ON auctions (farmer_id, id DESC);
CREATE INDEX IF NOT EXISTS auctions_open_ends_idx   ON auctions (ends_at) WHERE status = 'open';
CREATE INDEX IF NOT EXISTS notifications_unread_idx ON notifications (user_id) WHERE read_at IS NULL;
CREATE INDEX IF NOT EXISTS images_owner_idx         ON images (owner_id);

-- ── v3 (auditoría): reglas de integridad ──────────────────────────
-- NOT VALID: se aplican a los datos nuevos sin revisar los viejos, así nunca bloquean el arranque.
DO $$
DECLARE c RECORD;
BEGIN
  FOR c IN SELECT * FROM (VALUES
    ('lots',          'lots_process_chk',        'CHECK (process IN (''lavado'',''honey'',''natural''))'),
    ('lots',          'lots_price_chk',          'CHECK (price_lb > 0 AND price_lb <= 100)'),
    ('lots',          'lots_sca_chk',            'CHECK (sca BETWEEN 0 AND 100)'),
    ('farms',         'farms_altitude_chk',      'CHECK (altitude BETWEEN 0 AND 6000)'),
    ('farms',         'farms_sca_chk',           'CHECK (sca BETWEEN 0 AND 100)'),
    ('agreements',    'agreements_status_chk',   'CHECK (status BETWEEN 1 AND 3)'),
    ('agreements',    'agreements_price_chk',    'CHECK (price_lb > 0 AND sacks > 0)'),
    ('messages',      'messages_type_chk',       'CHECK (type IN (''text'',''photo'',''quote'',''agreement'',''system''))'),
    ('messages',      'messages_lang_chk',       'CHECK (lang IS NULL OR lang IN (''es'',''en''))'),
    ('notifications', 'notifications_type_chk',  'CHECK (length(type) BETWEEN 1 AND 40)'),
    ('lot_views',     'lot_views_views_chk',     'CHECK (views >= 1)')
  ) AS t(tbl, name, def)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = c.name) THEN
      EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I %s NOT VALID', c.tbl, c.name, c.def);
    END IF;
  END LOOP;
END $$;
