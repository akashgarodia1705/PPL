-- ============================================================
--  PATNI PINNACLE LEAGUE — Season 8
--  Paste this entire script into the Supabase SQL Editor
--  and click "Run". Safe to re-run — uses IF NOT EXISTS.
-- ============================================================


-- ── 1. TABLES ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ppl_users (
  id           SERIAL PRIMARY KEY,
  username     TEXT UNIQUE NOT NULL,
  password     TEXT NOT NULL,
  role         TEXT NOT NULL DEFAULT 'viewer',
  first_login  BOOLEAN DEFAULT true,
  season_id    INTEGER DEFAULT 1,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ppl_seasons (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  current     BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ppl_teams (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  colour      TEXT DEFAULT '#1565c0',
  player1_id  INTEGER,
  player2_id  INTEGER,
  season_id   INTEGER DEFAULT 1,
  sort_order  INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS ppl_players (
  id         SERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  season_id  INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS ppl_fixtures (
  id          SERIAL PRIMARY KEY,
  team1_id    INTEGER,
  team2_id    INTEGER,
  match_type  TEXT DEFAULT 'league',
  round_num   INTEGER DEFAULT 0,
  rounds_data JSONB DEFAULT '[]',
  total1      INTEGER DEFAULT 0,
  total2      INTEGER DEFAULT 0,
  played      BOOLEAN DEFAULT false,
  match_date  DATE,
  match_time  TEXT,
  sort_order  INTEGER DEFAULT 0,
  season_id   INTEGER DEFAULT 1,
  created_by  TEXT,
  created_at  TIMESTAMPTZ,
  edited_by   TEXT,
  edited_at   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS ppl_awards (
  id           SERIAL PRIMARY KEY,
  title        TEXT,
  trophy       TEXT DEFAULT '🏆',
  winner_name  TEXT,
  sub_text     TEXT,
  photo_url    TEXT,
  season_id    INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS ppl_rules (
  id         SERIAL PRIMARY KEY,
  content    TEXT DEFAULT '',
  season_id  INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS ppl_audit (
  id           SERIAL PRIMARY KEY,
  username     TEXT,
  action       TEXT,
  match_info   TEXT,
  before_data  JSONB,
  after_data   JSONB,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  season_id    INTEGER DEFAULT 1
);


-- ── 2. SEED DATA ─────────────────────────────────────────────

-- Users (admin, scorer, 7 viewers)
INSERT INTO ppl_users (username, password, role, first_login) VALUES
  ('admin',    'admin',    'admin',  false),
  ('scorer',   'scorer',   'scorer', false),
  ('vaibhav',  'vaibhav',  'viewer', false),
  ('dinesh',   'dinesh',   'viewer', false),
  ('sarvesh',  'sarvesh',  'viewer', false),
  ('akhilesh', 'akhilesh', 'viewer', false),
  ('akash',    'akash',    'viewer', false),
  ('akshay',   'akshay',   'viewer', false),
  ('aman',     'aman',     'viewer', false)
ON CONFLICT (username) DO UPDATE
  SET password    = EXCLUDED.password,
      role        = EXCLUDED.role,
      first_login = EXCLUDED.first_login;

-- Season
INSERT INTO ppl_seasons (name, current)
  VALUES ('Season 8', true)
ON CONFLICT DO NOTHING;

-- Default rules
INSERT INTO ppl_rules (content, season_id)
  VALUES (
    'League Rules

Each match consists of 3 rounds (league) or 5 rounds (Semi-finals & Final).
Win = 2 pts, Draw = 1 pt each, Loss = 0 pts.
Ranking: Points → NSD (Net Score Difference) as tiebreaker.
Top 4 teams qualify for knockouts.
Knockouts: #1 vs #4 (SF1), #2 vs #3 (SF2). Winners to Final.
No third-place playoff.',
    1
  )
ON CONFLICT DO NOTHING;


-- ── 3. ROW LEVEL SECURITY ────────────────────────────────────
--  Enable RLS on all tables and allow full access via the
--  anon / service key used by the app.

ALTER TABLE ppl_users    ENABLE ROW LEVEL SECURITY;
ALTER TABLE ppl_seasons  ENABLE ROW LEVEL SECURITY;
ALTER TABLE ppl_teams    ENABLE ROW LEVEL SECURITY;
ALTER TABLE ppl_players  ENABLE ROW LEVEL SECURITY;
ALTER TABLE ppl_fixtures ENABLE ROW LEVEL SECURITY;
ALTER TABLE ppl_awards   ENABLE ROW LEVEL SECURITY;
ALTER TABLE ppl_rules    ENABLE ROW LEVEL SECURITY;
ALTER TABLE ppl_audit    ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if re-running
DO $$ DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT policyname, tablename FROM pg_policies
    WHERE tablename IN (
      'ppl_users','ppl_seasons','ppl_teams','ppl_players',
      'ppl_fixtures','ppl_awards','ppl_rules','ppl_audit'
    )
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- Allow all operations for anon role (app uses the publishable/anon key)
CREATE POLICY "ppl_users_all"    ON ppl_users    FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "ppl_seasons_all"  ON ppl_seasons  FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "ppl_teams_all"    ON ppl_teams    FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "ppl_players_all"  ON ppl_players  FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "ppl_fixtures_all" ON ppl_fixtures FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "ppl_awards_all"   ON ppl_awards   FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "ppl_rules_all"    ON ppl_rules    FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "ppl_audit_all"    ON ppl_audit    FOR ALL TO anon USING (true) WITH CHECK (true);


-- ── 4. REALTIME ──────────────────────────────────────────────
--  Enable Realtime publication for live score updates.

DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE ppl_fixtures;


-- ── DONE ─────────────────────────────────────────────────────
--  All 8 tables created, users seeded, RLS open, Realtime on.
--  Open the app and log in with admin / admin to get started.
-- ─────────────────────────────────────────────────────────────
