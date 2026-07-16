import psycopg2
import psycopg2.extras
from flask import current_app, g, session


def get_db():
    """
    Retourne une connexion psycopg2 pour la requete en cours.
    Si l'utilisateur est connecte, la connexion bascule automatiquement
    sur son role PostgreSQL via SET ROLE.
    """
    if "db" not in g:
        cfg = current_app.config
        g.db = psycopg2.connect(
            host=cfg["DB_HOST"],
            port=cfg["DB_PORT"],
            dbname=cfg["DB_NAME"],
            user=cfg["DB_USER"],
            password=cfg["DB_PASSWORD"],
        )
        g.db.autocommit = False

        role_pg = session.get("role_pg")
        if role_pg:
            with g.db.cursor() as cur:
                cur.execute(f"SET ROLE {role_pg};")
            g.db.commit()

    return g.db


def close_db(e=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def dict_cursor(conn):
    """Cursor qui renvoie des dictionnaires plutot que des tuples."""
    return conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)


def init_app(app):
    app.teardown_appcontext(close_db)