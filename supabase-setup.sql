-- ══════════════════════════════════════════════════════
--  PHYTOCLEAN — Setup Base de Données Supabase
--  Colle ce code dans : Supabase > SQL Editor > New query
-- ══════════════════════════════════════════════════════


-- ─────────────────────────────────────
--  TABLE 1 : contacts
--  Stocke les messages du formulaire contact
-- ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS contacts (
  id          BIGSERIAL PRIMARY KEY,
  nom         TEXT NOT NULL,
  prenom      TEXT,
  email       TEXT NOT NULL,
  sujet       TEXT,
  message     TEXT NOT NULL,
  lu          BOOLEAN DEFAULT FALSE,          -- pour marquer "lu" dans ton dashboard
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour trier par date rapidement
CREATE INDEX IF NOT EXISTS contacts_created_idx ON contacts (created_at DESC);


-- ─────────────────────────────────────
--  TABLE 2 : avis
--  Stocke les avis clients (note + commentaire)
-- ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS avis (
  id           BIGSERIAL PRIMARY KEY,
  nom          TEXT NOT NULL,
  note         SMALLINT NOT NULL CHECK (note BETWEEN 1 AND 5),
  commentaire  TEXT NOT NULL,
  approuve     BOOLEAN DEFAULT FALSE,         -- modération : l'avis s'affiche seulement si TRUE
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour trier par date
CREATE INDEX IF NOT EXISTS avis_created_idx ON avis (created_at DESC);


-- ══════════════════════════════════════════════════════
--  SÉCURITÉ — Row Level Security (RLS)
--  Permet d'écrire sans authentification (formulaire public)
--  mais empêche de lire les contacts sans être admin
-- ══════════════════════════════════════════════════════

-- Activer RLS sur les deux tables
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE avis     ENABLE ROW LEVEL SECURITY;


-- TABLE CONTACTS : tout le monde peut insérer, personne ne peut lire sans auth
CREATE POLICY "insert_contact_public"
  ON contacts FOR INSERT
  TO anon
  WITH CHECK (true);

-- Lecture contacts réservée aux utilisateurs authentifiés (toi en admin)
CREATE POLICY "read_contacts_admin"
  ON contacts FOR SELECT
  TO authenticated
  USING (true);


-- TABLE AVIS : tout le monde peut insérer
CREATE POLICY "insert_avis_public"
  ON avis FOR INSERT
  TO anon
  WITH CHECK (true);

-- Lecture avis : tout le monde voit les avis approuvés
CREATE POLICY "read_avis_approuves"
  ON avis FOR SELECT
  TO anon
  USING (approuve = TRUE);

-- Admin voit tous les avis
CREATE POLICY "read_avis_admin"
  ON avis FOR SELECT
  TO authenticated
  USING (true);

-- Admin peut approuver/supprimer
CREATE POLICY "update_avis_admin"
  ON avis FOR UPDATE
  TO authenticated
  USING (true);


-- ══════════════════════════════════════════════════════
--  VUE UTILE : score moyen des avis approuvés
-- ══════════════════════════════════════════════════════
CREATE OR REPLACE VIEW stats_avis AS
SELECT
  COUNT(*)                        AS total_avis,
  ROUND(AVG(note)::NUMERIC, 1)   AS note_moyenne,
  COUNT(*) FILTER (WHERE note = 5) AS cinq_etoiles,
  COUNT(*) FILTER (WHERE note = 4) AS quatre_etoiles,
  COUNT(*) FILTER (WHERE note = 3) AS trois_etoiles,
  COUNT(*) FILTER (WHERE note = 2) AS deux_etoiles,
  COUNT(*) FILTER (WHERE note = 1) AS une_etoile
FROM avis
WHERE approuve = TRUE;


-- ══════════════════════════════════════════════════════
--  DONNÉES DE TEST (optionnel — supprime si pas besoin)
-- ══════════════════════════════════════════════════════
INSERT INTO avis (nom, note, commentaire, approuve) VALUES
  ('Salma B.',  5, 'Produit vraiment impressionnant. Ma bouche se sent propre bien plus longtemps qu''avec un bain de bouche classique.', TRUE),
  ('Karim M.',  5, 'Enfin un soin bucco-dentaire 100% naturel qui fonctionne vraiment. Différence visible en 3 semaines.', TRUE),
  ('Nadia H.',  5, 'Concept innovant et efficace. Packaging soigné et professionnel.', TRUE);

INSERT INTO contacts (nom, prenom, email, sujet, message) VALUES
  ('Test', 'Admin', 'admin@phytoclean.dz', 'Informations produit', 'Message de test.');
