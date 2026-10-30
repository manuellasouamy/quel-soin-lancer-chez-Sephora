# Quel soin lancer chez Sephora ? Analyse de 1 952 produits de soin

Projet d'analyse de données de bout en bout : **SQL (SQLite)** pour explorer, nettoyer et analyser, **Power BI** pour la visualisation.

## Le contexte

Une marque de soins prépare son premier lancement chez Sephora. La directrice produit pose quatre questions :

1. Quel **type de produit** lancer ?
2. À quel **prix** ?
3. Avec quels **actifs** ?
4. Quelles **marques** surveiller ?

Ce dépôt contient l'analyse qui répond à ces questions à partir des données publiques du site Sephora.

## La recommandation en bref

> Lancer un **sérum entre 30 et 60 $**, en **exclusivité Sephora**, avec le **rétinol**, les **céramides** ou l'**acide salicylique** comme actif phare.
> Surveiller **Dermalogica** et **Shiseido** (très bien notées sur un gros volume d'avis), **Paula's Choice** (bien notée à un prix proche du nôtre), ainsi que **The Ordinary** et **LANEIGE** (les produits les plus mis en favori).

## Les données

- Source : [Sephora Products and Skincare Reviews](https://www.kaggle.com/datasets/nadyinky/sephora-products-and-skincare-reviews) (Kaggle), fichier `product_info.csv`.
- 8 494 produits, 27 colonnes : marque, prix, note moyenne, nombre d'avis, nombre de mises en favori (`loves_count`), liste d'ingrédients, catégories, exclusivité Sephora, nouveauté…
- **Une ligne = un produit**, sans doublon.
- Ce que les données ne contiennent pas : les ventes, les dates et la dose des ingrédients.

Le fichier de données n'est pas inclus dans ce dépôt : voir [data/README.md](data/README.md).

## La démarche

| Étape | Fichier | Ce qui est fait |
|---|---|---|
| 1. Explorer | [sql/01_exploration.sql](sql/01_exploration.sql) | Taille de la base, grain, colonnes, catégories |
| 2. Contrôler la qualité | [sql/02_qualite_donnees.sql](sql/02_qualite_donnees.sql) | Valeurs manquantes, valeurs extrêmes, format du texte des ingrédients |
| 3. Définir le périmètre | [sql/03_perimetre.sql](sql/03_perimetre.sql) | Vue `skincare` : 1 952 soins |
| 4. Analyser | [sql/04_analyse.sql](sql/04_analyse.sql) | Les requêtes qui produisent les tableaux de [results/](results/) |
| 5. Visualiser | Power BI | Les graphiques ci-dessous |

**Décisions de nettoyage**

- Sur 2 420 produits Skincare, j'ai retiré les coffrets, les minis, les appareils (LED, microcourant), les compléments alimentaires et une catégorie à un seul produit. Les coffrets additionnent les prix de plusieurs produits et les appareils coûtent jusqu'à 1 900 $ : les garder aurait faussé les comparaisons. **Périmètre final : 1 952 soins.**
- Les 69 produits sans note (aucun avis) sont exclus des calculs de note : ce n'est pas une note de 0.
- L'absence de prix promotionnel (2 375 produits) n'est pas une donnée manquante : elle signifie « pas en promotion ». Aucune ligne n'est supprimée pour ça.

**Choix de méthode**

- **Prix médian** plutôt que moyen : quelques produits de luxe tirent la moyenne vers le haut.
- **Note pondérée par le nombre d'avis** (`SUM(rating * reviews) / SUM(reviews)`) : une note de 5/5 sur 8 avis ne doit pas peser autant qu'une note de 4,8 sur 2 800 avis.
- **Note fiable** (moyenne bayésienne) pour classer les produits : chaque note est rapprochée de la moyenne générale (4,30), d'autant plus que le produit a peu d'avis.
- SQLite n'a ni `MEDIAN` ni `CORR` : les médianes sont calculées avec des **fonctions de fenêtre** (`ROW_NUMBER() OVER (PARTITION BY …)`) et la corrélation avec sa formule.

## Les résultats

### 1. Un soin coûte typiquement 58 $

![Prix médian par type de soin](figures/1_prix_par_type.png)

Les crèmes (538 produits) et les traitements, surtout des sérums (452), dominent le marché, avec un prix médian de 58 $. Le contour des yeux, la protection solaire et l'autobronzant sont les types de soin les moins bien notés.

### 2. Le prix n'explique presque pas la note

![Note pondérée par tranche de prix](figures/2_note_par_prix.png)

La corrélation entre prix et note est de **0,04**, soit quasiment nulle. Les notes vont de 4,25 (moins de 25 $) à 4,34 (50-100 $) : un produit plus cher n'est pas mieux noté. Les produits à moins de 25 $ sont en revanche les plus mis en favori.

### 3. Pour un sérum, la tranche 30-60 $ est la plus intéressante

![Sérums par tranche de prix](figures/3_serums.png)

| Tranche | Sérums | Note pondérée | Favoris (médiane) |
|---|---:|---:|---:|
| Moins de 30 $ | 79 | 4,13 | 41 475 |
| **30-60 $** | **94** | **4,34** | **20 620** |
| 60-100 $ | 132 | 4,36 | 10 360 |
| 100 $ et plus | 63 | 4,27 | 3 942 |

Entre 30 et 60 $, les sérums sont presque aussi bien notés qu'entre 60 et 100 $ (4,34 contre 4,36), avec **deux fois plus de favoris** et **moins de concurrents** (94 contre 132).

### 4. Rétinol, céramides et acide salicylique : au-dessus de la moyenne

![Écart de note à la moyenne par actif](figures/4_actifs.png)

Les soins qui contiennent du rétinol (4,42), des céramides (4,39) ou de l'acide salicylique (4,37) sont mieux notés que la moyenne (4,30), et ces actifs sont présents dans peu de produits (4 à 10 %). À l'inverse, l'acide hyaluronique est dans 45 % des soins : ce n'est plus un argument différenciant.

### 5. Les marques à surveiller

![Marques : prix, note et nombre d'avis](figures/5_marques.png)

Parmi les marques qui ont au moins 10 soins notés :

- **Dermalogica** (40 produits, 16 969 avis, 4,60) et **Shiseido** (47 produits, 19 866 avis, 4,50) combinent très bonne note et gros volume d'avis.
- **Paula's Choice** (prix médian 37 $) et **innisfree** (22 $) montrent qu'on peut être bien noté sans être cher.
- **The Ordinary** et **LANEIGE** ont les produits les plus mis en favori du site, avec des notes dans la moyenne (4,2 à 4,35) : **populaire ne veut pas dire mieux noté**.

### 6. Exclusivités et nouveautés

- Les exclusivités Sephora sont **moins chères** (34 $ contre 50 $ en médiane) et **plus mises en favori** (15 822 contre 9 606) : un argument pour négocier un lancement en exclusivité.
- Les nouveautés ont une note moyenne de 4,57 contre 4,23, mais seulement 62 avis en médiane. Les premiers avis sont souvent plus enthousiastes : c'est un **biais**, pas la preuve que les nouveautés sont meilleures.

## Les limites

- **Pas de ventes ni de dates** : l'analyse parle de satisfaction (notes) et d'intérêt (favoris), pas de chiffre d'affaires ni d'évolution dans le temps.
- **Présence, pas dose** : on sait si un actif figure dans la liste d'ingrédients, pas en quelle quantité. Un produit qui contient plusieurs actifs compte pour chacun.
- **Corrélation, pas causalité** : un actif associé à de bonnes notes n'est pas forcément la cause de ces notes.
- **Associer des actifs** dans une même formule (par exemple rétinol et acide salicylique) est une décision de formulation : les données ne disent pas si c'est compatible.
- Le classement par note fiable place en premier un **accessoire** (le coton Facial Cotton de Shiseido). Il est exclu de la recommandation.

## Reproduire l'analyse

1. Télécharger `product_info.csv` (voir [data/README.md](data/README.md)) et le placer dans `data/`.
2. Créer la base : `python build_db.py` (nécessite pandas). Cela crée `sephora.db` avec une table `produits` typée.
3. Ouvrir `sephora.db` dans [DB Browser for SQLite](https://sqlitebrowser.org/) et exécuter les fichiers de `sql/` dans l'ordre.
4. Les résultats exportés sont dans `results/` et ont servi à construire le rapport Power BI.

## Structure du dépôt

```
sephora-skincare-sql/
├── README.md               ce rapport
├── build_db.py             crée la base SQLite à partir du CSV
├── data/README.md          où télécharger les données
├── sql/                    les requêtes, dans l'ordre de la démarche
├── results/                les tableaux de résultats (CSV)
└── figures/                les graphiques Power BI
```

## Outils

SQLite (DB Browser for SQLite) · SQL : CTE, fonctions de fenêtre, jointures sur motif, `CASE WHEN`, `HAVING`, vues · Power BI Desktop · Python (pandas) pour charger les données.

## Autrice

[Ton prénom Nom] · [lien LinkedIn]
