"""
Script a lancer UNE SEULE FOIS pour hacher les mots de passe de test
inseres en clair par script_examen_BDD.sql (motdepasse123, etc.).

Emplacement : scripts/migrer_mots_de_passe.py
Lancement (depuis la racine du projet, avec le venv active) :
    python scripts/migrer_mots_de_passe.py
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
import psycopg2.extras
from werkzeug.security import generate_password_hash
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(
    host=os.environ.get("DB_HOST", "localhost"),
    port=os.environ.get("DB_PORT", "5432"),
    dbname=os.environ.get("DB_NAME", "gestion_des_incidents_informatique"),
    user=os.environ.get("DB_USER", "app_login"),
    password=os.environ.get("DB_PASSWORD", ""),
)

with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
    cur.execute("SELECT id_utilisateur, email, mot_de_passe_hash FROM utilisateurs")
    utilisateurs = cur.fetchall()

    for u in utilisateurs:
        # Un hash werkzeug commence toujours par "scrypt:" ou "pbkdf2:".
        # On ne touche pas aux comptes deja migres.
        if u["mot_de_passe_hash"].startswith(("scrypt:", "pbkdf2:")):
            print(f"  - {u['email']} deja hache, ignore")
            continue

        nouveau_hash = generate_password_hash(u["mot_de_passe_hash"])
        cur.execute(
            "UPDATE utilisateurs SET mot_de_passe_hash = %s WHERE id_utilisateur = %s",
            (nouveau_hash, u["id_utilisateur"]),
        )
        print(f"  - {u['email']} : mot de passe hache")

conn.commit()
conn.close()
print("Migration terminee.")
