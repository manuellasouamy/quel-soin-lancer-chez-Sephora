-- =============================================================
-- 02 · Qualité des données : valeurs manquantes, extrêmes, texte
-- =============================================================

-- Valeurs manquantes sur le Skincare (COUNT(colonne) ignore les NULL)
SELECT COUNT(*) - COUNT(rating)         AS sans_note,
       COUNT(*) - COUNT(ingredients)    AS sans_ingredients,
       COUNT(*) - COUNT(sale_price_usd) AS sans_prix_promo,
       COUNT(*) - COUNT(size)           AS sans_taille
FROM produits
WHERE primary_category = 'Skincare';
-- Décisions :
--   sans_note (69)          : produits sans avis, exclus des calculs de note (pas une note de 0).
--   sans_prix_promo (2 375) : absence normale = pas en promotion. On ne supprime rien.
--   sans_ingredients (134)  : vraie information manquante, exclus de l'analyse des actifs.

-- Valeurs extrêmes : les produits les plus chers sont-ils des soins ?
SELECT product_name, brand_name, price_usd, secondary_category
FROM produits
WHERE primary_category = 'Skincare'
ORDER BY price_usd DESC
LIMIT 8;
-- Résultat : ce sont des appareils (High Tech Tools). Question de périmètre, voir 03.

-- Format de la colonne ingredients
SELECT product_name, ingredients
FROM produits
WHERE primary_category = 'Skincare' AND ingredients IS NOT NULL
LIMIT 3;
-- Texte libre en forme de liste : on cherchera un actif avec LIKE '%motif%'.
-- Limite : on sait si un actif est présent, pas à quelle dose.
