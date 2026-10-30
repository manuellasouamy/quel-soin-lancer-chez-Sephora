"""Crée la base SQLite sephora.db à partir de data/product_info.csv.

Usage : python build_db.py
Il faut pandas (pip install pandas). Les types de colonnes sont fixés
à la main pour que les comparaisons de prix et de notes soient numériques.
"""
import os
import sqlite3

import pandas as pd

CSV = os.path.join("data", "product_info.csv")
DB = "sephora.db"

TYPES = {
    "product_id": "TEXT", "product_name": "TEXT", "brand_id": "INTEGER",
    "brand_name": "TEXT", "loves_count": "INTEGER", "rating": "REAL",
    "reviews": "INTEGER", "size": "TEXT", "variation_type": "TEXT",
    "variation_value": "TEXT", "variation_desc": "TEXT", "ingredients": "TEXT",
    "price_usd": "REAL", "value_price_usd": "REAL", "sale_price_usd": "REAL",
    "limited_edition": "INTEGER", "new": "INTEGER", "online_only": "INTEGER",
    "out_of_stock": "INTEGER", "sephora_exclusive": "INTEGER", "highlights": "TEXT",
    "primary_category": "TEXT", "secondary_category": "TEXT",
    "tertiary_category": "TEXT", "child_count": "INTEGER",
    "child_max_price": "REAL", "child_min_price": "REAL",
}

df = pd.read_csv(CSV)[list(TYPES)]
df["reviews"] = df["reviews"].astype("Int64")   # le CSV le lit en décimal

if os.path.exists(DB):
    os.remove(DB)
con = sqlite3.connect(DB)
cols = ",\n  ".join(f"{k} {v}" for k, v in TYPES.items())
con.execute(f"CREATE TABLE produits (\n  {cols},\n  PRIMARY KEY (product_id)\n)")

rows = [tuple(None if pd.isna(v) else (int(v) if isinstance(v, (int,)) else v) for v in r)
        for r in df.astype(object).itertuples(index=False)]
con.executemany(f"INSERT INTO produits VALUES ({', '.join('?' * len(TYPES))})", rows)
con.commit()
n = con.execute("SELECT COUNT(*) FROM produits").fetchone()[0]
con.close()
print(f"{DB} créée : {n} produits")
