-- =============================================================
-- 00 · Créer la base dans DB Browser for SQLite, sans Python
--
-- Étape A : DB Browser > Nouvelle base de données > sephora.db
-- Étape B : exécuter le CREATE TABLE ci-dessous (onglet Exécuter le SQL)
-- Étape C : Fichier > Importer > Table depuis un fichier CSV
--           > data/product_info.csv, cocher « Noms des colonnes en première ligne »,
--           nom de la table : produits, et accepter l'import dans la table existante
-- Étape D : exécuter les UPDATE et les contrôles de la fin de ce fichier
-- =============================================================

-- B. La table, avec un type pour chaque colonne.
-- Sans types, les prix et les notes seraient du texte : '9.0' > '25.0'
-- serait vrai (comparaison lettre par lettre) et tous les calculs seraient faux.
-- Les colonnes sont dans le même ordre que dans le fichier CSV.
DROP TABLE IF EXISTS produits;

CREATE TABLE produits (
  product_id         TEXT PRIMARY KEY,
  product_name       TEXT,
  brand_id           INTEGER,
  brand_name         TEXT,
  loves_count        INTEGER,
  rating             REAL,
  reviews            INTEGER,
  size               TEXT,
  variation_type     TEXT,
  variation_value    TEXT,
  variation_desc     TEXT,
  ingredients        TEXT,
  price_usd          REAL,
  value_price_usd    REAL,
  sale_price_usd     REAL,
  limited_edition    INTEGER,
  new                INTEGER,
  online_only        INTEGER,
  out_of_stock       INTEGER,
  sephora_exclusive  INTEGER,
  highlights         TEXT,
  primary_category   TEXT,
  secondary_category TEXT,
  tertiary_category  TEXT,
  child_count        INTEGER,
  child_max_price    REAL,
  child_min_price    REAL
);

-- D1. Les cases vides du CSV arrivent comme du texte vide '' et non comme NULL.
-- NULLIF(x, '') renvoie NULL si x vaut '', sinon x : on remet les vrais NULL.
UPDATE produits SET
  rating             = NULLIF(rating, ''),
  reviews            = NULLIF(reviews, ''),
  size               = NULLIF(size, ''),
  variation_type     = NULLIF(variation_type, ''),
  variation_value    = NULLIF(variation_value, ''),
  variation_desc     = NULLIF(variation_desc, ''),
  ingredients        = NULLIF(ingredients, ''),
  value_price_usd    = NULLIF(value_price_usd, ''),
  sale_price_usd     = NULLIF(sale_price_usd, ''),
  highlights         = NULLIF(highlights, ''),
  secondary_category = NULLIF(secondary_category, ''),
  tertiary_category  = NULLIF(tertiary_category, ''),
  child_max_price    = NULLIF(child_max_price, ''),
  child_min_price    = NULLIF(child_min_price, '');

-- D2. Contrôles
SELECT COUNT(*) AS nb_produits FROM produits;            -- attendu : 8 494

SELECT typeof(price_usd) AS type_prix, typeof(rating) AS type_note, COUNT(*) AS nb
FROM produits
GROUP BY type_prix, type_note;
-- attendu : real / real pour les produits notés, real / null pour ceux sans note.
-- Si tu vois 'text', le type n'a pas été appliqué : recommence l'étape B.

SELECT COUNT(*) - COUNT(rating) AS sans_note
FROM produits
WHERE primary_category = 'Skincare';                     -- attendu : 69
