-- =============================================================
-- 01 · Exploration : taille, grain et catégories de la base
-- Base : table produits (8 494 produits Sephora, voir data/README.md)
-- =============================================================

-- Taille et grain : une ligne = un produit ?
SELECT COUNT(*)                   AS nb_lignes,
       COUNT(DISTINCT product_id) AS nb_produits,
       COUNT(DISTINCT brand_name) AS nb_marques
FROM produits;
-- Résultat : autant de lignes que de product_id -> une ligne = un produit, sans doublon.

-- Structure de la table et 5 lignes au hasard
PRAGMA table_info(produits);

SELECT * FROM produits ORDER BY RANDOM() LIMIT 5;

-- Nombre de produits par grande catégorie
SELECT primary_category, COUNT(*) AS nb
FROM produits
GROUP BY primary_category
ORDER BY nb DESC;
-- Résultat : le soin (Skincare) est la première catégorie, avec 2 420 produits.
