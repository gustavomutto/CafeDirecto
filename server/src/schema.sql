

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
