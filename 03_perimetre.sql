-- =============================================================
-- 03 · Périmètre : la vue skincare (1 952 soins)
-- On retire ce qui fausserait les comparaisons de prix et de notes :
--   coffrets (prix et notes de plusieurs produits), minis, appareils,
--   compléments alimentaires (Wellness) et 'Shop by Concern' (1 produit).
-- =============================================================

DROP VIEW IF EXISTS skincare;

CREATE VIEW skincare AS
SELECT *
FROM produits
WHERE primary_category = 'Skincare'
  AND secondary_category NOT IN ('Value & Gift Sets', 'Mini Size',
                                 'High Tech Tools', 'Wellness', 'Shop by Concern');

SELECT COUNT(*) AS nb FROM skincare;   -- 1 952
