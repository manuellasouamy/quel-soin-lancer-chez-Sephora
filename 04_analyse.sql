-- =============================================================
-- 04 · Analyse : les requêtes qui produisent les fichiers de results/
--
-- SQLite n'a pas de fonction MEDIAN. Chaque médiane est calculée avec
-- des fonctions de fenêtre : on numérote les valeurs dans l'ordre (rn)
-- dans chaque groupe de taille n, puis on fait la moyenne de la ou des
-- valeurs du milieu, aux rangs (n+1)/2 et (n+2)/2 (division entière).
--
-- Note pondérée = SUM(rating * reviews) / SUM(reviews) :
-- un produit à 3 000 avis pèse plus qu'un produit à 10 avis.
-- Nécessite SQLite 3.25+ (fonctions de fenêtre) et 3.35+ pour SQRT.
-- =============================================================

-- Note moyenne pondérée de tout le périmètre (référence : 4,303)
SELECT ROUND(SUM(rating * reviews) / SUM(reviews), 3) AS note_globale
FROM skincare
WHERE rating IS NOT NULL;


-- -------------------------------------------------------------
-- Q1 · Le marché par type de soin -> results/01_prix_par_type.csv
-- -------------------------------------------------------------
WITH r AS (
  SELECT secondary_category AS type_de_soin, price_usd, rating, reviews,
         ROW_NUMBER() OVER (PARTITION BY secondary_category ORDER BY price_usd) AS rn,
         COUNT(*)     OVER (PARTITION BY secondary_category)                    AS n
  FROM skincare
  WHERE rating IS NOT NULL
)
SELECT type_de_soin,
       COUNT(*)                                                   AS nb_produits,
       AVG(CASE WHEN rn IN ((n + 1) / 2, (n + 2) / 2) THEN price_usd END) AS prix_median,
       ROUND(SUM(rating * reviews) / SUM(reviews), 2)             AS note_ponderee
FROM r
GROUP BY type_de_soin
ORDER BY prix_median DESC, nb_produits DESC;


-- -------------------------------------------------------------
-- Note fiable (moyenne bayésienne) : le top 10 des produits
-- On tire la note de chaque produit vers la moyenne générale C,
-- d'autant plus fort qu'il a peu d'avis (100 avis "moyens" fictifs).
-- -------------------------------------------------------------
WITH t AS (
  SELECT product_name, brand_name, secondary_category, price_usd, rating, reviews,
         SUM(rating * reviews) OVER () / SUM(reviews) OVER () AS C
  FROM skincare
  WHERE rating IS NOT NULL
)
SELECT product_name, brand_name, secondary_category, price_usd, rating, reviews,
       ROUND((reviews * rating + 100 * C) / (reviews + 100), 3) AS note_fiable
FROM t
ORDER BY note_fiable DESC
LIMIT 10;
-- Le n°1 est Facial Cotton (Shiseido), un accessoire : exclu de la recommandation.


-- -------------------------------------------------------------
-- Q2 · Plus cher, mieux noté ? -> results/02_note_par_tranche_prix.csv
-- -------------------------------------------------------------
WITH t AS (
  SELECT CASE WHEN price_usd < 25  THEN '1. Moins de 25$'
              WHEN price_usd < 50  THEN '2. 25-50$'
              WHEN price_usd < 100 THEN '3. 50-100$'
              ELSE '4. 100$ et plus' END AS tranche_prix,
         rating, reviews, loves_count
  FROM skincare
  WHERE rating IS NOT NULL
), r AS (
  SELECT t.*,
         ROW_NUMBER() OVER (PARTITION BY tranche_prix ORDER BY loves_count) AS rn,
         COUNT(*)     OVER (PARTITION BY tranche_prix)                      AS n
  FROM t
)
SELECT tranche_prix,
       COUNT(*)                                                     AS nb_produits,
       ROUND(SUM(rating * reviews) / SUM(reviews), 2)               AS note_ponderee,
       AVG(CASE WHEN rn IN ((n + 1) / 2, (n + 2) / 2) THEN loves_count END) AS favoris_median
FROM r
GROUP BY tranche_prix
ORDER BY tranche_prix;

-- Corrélation de Pearson entre prix et note (SQLite n'a pas de CORR)
WITH s AS (
  SELECT AVG(price_usd) AS mx, AVG(rating) AS my,
         AVG(price_usd * rating)   AS mxy,
         AVG(price_usd * price_usd) AS mxx,
         AVG(rating * rating)       AS myy
  FROM skincare
  WHERE rating IS NOT NULL
)
SELECT ROUND((mxy - mx * my) / (SQRT(mxx - mx * mx) * SQRT(myy - my * my)), 3) AS corr_prix_note
FROM s;   -- 0,042 : le prix n'explique presque pas la note


-- -------------------------------------------------------------
-- Q3 · Zoom sur les sérums -> results/03_serums_par_tranche.csv
-- -------------------------------------------------------------
WITH t AS (
  SELECT CASE WHEN price_usd < 30  THEN '1. Moins de 30$'
              WHEN price_usd < 60  THEN '2. 30-60$'
              WHEN price_usd < 100 THEN '3. 60-100$'
              ELSE '4. 100$ et plus' END AS tranche_prix,
         rating, reviews, loves_count
  FROM skincare
  WHERE tertiary_category = 'Face Serums' AND rating IS NOT NULL
), r AS (
  SELECT t.*,
         ROW_NUMBER() OVER (PARTITION BY tranche_prix ORDER BY loves_count) AS rn,
         COUNT(*)     OVER (PARTITION BY tranche_prix)                      AS n
  FROM t
)
SELECT tranche_prix,
       COUNT(*)                                                     AS nb_serums,
       ROUND(SUM(rating * reviews) / SUM(reviews), 2)               AS note_ponderee,
       AVG(CASE WHEN rn IN ((n + 1) / 2, (n + 2) / 2) THEN loves_count END) AS favoris_median
FROM r
GROUP BY tranche_prix
ORDER BY tranche_prix;


-- -------------------------------------------------------------
-- Q4 · Quels actifs ? -> results/04_actifs.csv
-- Jointure sur un motif (LIKE) avec une petite table d'actifs.
-- Un produit qui contient plusieurs actifs compte dans plusieurs lignes.
-- -------------------------------------------------------------
WITH actifs(actif, motif) AS (VALUES
   ('Niacinamide', '%niacinamide%'), ('Rétinol', '%retinol%'),
   ('Acide hyaluronique', '%hyalur%'), ('Vitamine C', '%ascorb%'),
   ('Acide salicylique', '%salicylic%'), ('Céramides', '%ceramide%'),
   ('Peptides', '%peptide%'), ('Squalane', '%squalane%'),
   ('Parfum', '%fragrance%')
), j AS (
  SELECT a.actif, s.price_usd, s.rating, s.reviews
  FROM skincare s
  JOIN actifs a ON s.ingredients LIKE a.motif
  WHERE s.rating IS NOT NULL
), r AS (
  SELECT j.*,
         ROW_NUMBER() OVER (PARTITION BY actif ORDER BY price_usd) AS rn,
         COUNT(*)     OVER (PARTITION BY actif)                    AS n
  FROM j
)
SELECT actif,
       COUNT(*)                                                     AS nb_produits,
       ROUND(100.0 * COUNT(*) /
             (SELECT COUNT(*) FROM skincare WHERE ingredients IS NOT NULL), 1) AS part_des_soins_pct,
       AVG(CASE WHEN rn IN ((n + 1) / 2, (n + 2) / 2) THEN price_usd END) AS prix_median,
       ROUND(SUM(rating * reviews) / SUM(reviews), 2)               AS note_ponderee
FROM r
GROUP BY actif
ORDER BY note_ponderee DESC;


-- -------------------------------------------------------------
-- Q5 · Les marques à surveiller -> results/05_marques.csv
-- Seuil de 10 soins notés minimum, sinon une marque à 1 produit gagne.
-- -------------------------------------------------------------
WITH r AS (
  SELECT brand_name, price_usd, rating, reviews, loves_count,
         ROW_NUMBER() OVER (PARTITION BY brand_name ORDER BY price_usd)   AS rn_p,
         ROW_NUMBER() OVER (PARTITION BY brand_name ORDER BY loves_count) AS rn_l,
         COUNT(*)     OVER (PARTITION BY brand_name)                      AS n
  FROM skincare
  WHERE rating IS NOT NULL
)
SELECT brand_name                                                     AS marque,
       COUNT(*)                                                       AS nb_produits,
       AVG(CASE WHEN rn_p IN ((n + 1) / 2, (n + 2) / 2) THEN price_usd END)   AS prix_median,
       ROUND(SUM(rating * reviews) / SUM(reviews), 2)                 AS note_ponderee,
       SUM(reviews)                                                   AS nb_avis,
       AVG(CASE WHEN rn_l IN ((n + 1) / 2, (n + 2) / 2) THEN loves_count END) AS favoris_median
FROM r
WHERE n >= 10
GROUP BY brand_name
ORDER BY note_ponderee DESC, nb_avis DESC
LIMIT 10;


-- -------------------------------------------------------------
-- Q6 · Populaire ou bien noté ? Nouveautés et exclusivités
-- -------------------------------------------------------------
-- Les 6 produits les plus mis en favori
SELECT product_name, brand_name, loves_count, rating, reviews
FROM skincare
ORDER BY loves_count DESC
LIMIT 6;

-- Exclusivités Sephora : prix et favoris médians
WITH r AS (
  SELECT sephora_exclusive, price_usd, loves_count, rating,
         ROW_NUMBER() OVER (PARTITION BY sephora_exclusive ORDER BY price_usd)   AS rn_p,
         ROW_NUMBER() OVER (PARTITION BY sephora_exclusive ORDER BY loves_count) AS rn_l,
         COUNT(*)     OVER (PARTITION BY sephora_exclusive)                      AS n
  FROM skincare
)
SELECT sephora_exclusive,
       COUNT(*)                                                       AS nb,
       ROUND(AVG(rating), 2)                                          AS note_moyenne,
       AVG(CASE WHEN rn_p IN ((n + 1) / 2, (n + 2) / 2) THEN price_usd END)   AS prix_median,
       AVG(CASE WHEN rn_l IN ((n + 1) / 2, (n + 2) / 2) THEN loves_count END) AS favoris_median
FROM r
GROUP BY sephora_exclusive;

-- Nouveautés : note moyenne et nombre médian d'avis
WITH r AS (
  SELECT new, rating, reviews,
         ROW_NUMBER() OVER (PARTITION BY new ORDER BY reviews) AS rn,
         COUNT(*)     OVER (PARTITION BY new)                  AS n
  FROM skincare
  WHERE reviews IS NOT NULL
)
SELECT new,
       COUNT(*)                                                     AS nb,
       ROUND(AVG(rating), 2)                                        AS note_moyenne,
       AVG(CASE WHEN rn IN ((n + 1) / 2, (n + 2) / 2) THEN reviews END) AS avis_median
FROM r
GROUP BY new;
-- Les nouveautés ont de meilleures notes mais peu d'avis : biais des premiers avis.
