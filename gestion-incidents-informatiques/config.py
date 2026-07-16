import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    SECRET_KEY = os.environ.get("FLASK_SECRET_KEY", "dev-key-a-changer")

    DB_HOST = os.environ.get("DB_HOST", "localhost")
    DB_PORT = os.environ.get("DB_PORT", "5432")
    DB_NAME = os.environ.get("DB_NAME", "gestion_des_incidents_informatiques")
    DB_USER = os.environ.get("DB_USER", "app_login")
    DB_PASSWORD = os.environ.get("DB_PASSWORD", "app_login")

    # Correspondance role applicatif (table utilisateurs.role) -> role PostgreSQL
    ROLE_MAP = {
        "ADMIN": "admin_role",
        "TECHNICIEN": "technicien_role",
        "UTILISATEUR": "utilisateur_role",
    }
