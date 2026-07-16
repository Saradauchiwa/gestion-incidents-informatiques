"""
Blueprint d'authentification.
Emplacement : app/auth.py
Nom du blueprint : "auth"  (utilisé partout comme url_for("auth.login"))
"""
from flask import (
    Blueprint, render_template, request, redirect,
    url_for, session, flash, current_app
)
from werkzeug.security import check_password_hash

from app.db import get_db, dict_cursor

bp = Blueprint("auth", __name__)


@bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form["email"].strip().lower()
        mot_de_passe = request.form["mot_de_passe"]

        conn = get_db()
        with dict_cursor(conn) as cur:
            cur.execute(
                """
                SELECT id_utilisateur, nom, prenom, email,
                       mot_de_passe_hash, role, actif
                FROM utilisateurs
                WHERE lower(email) = %s
                """,
                (email,),
            )
            user = cur.fetchone()

        # ⚠️ Vérification du mot de passe avec hachage (werkzeug).
        # Les mots de passe ne sont JAMAIS comparés en clair.
        mot_de_passe_ok = (
            user is not None
            and user["mot_de_passe_hash"] is not None
            and check_password_hash(user["mot_de_passe_hash"], mot_de_passe)
        )

        if user and user["actif"] and mot_de_passe_ok:
            role_pg = current_app.config["ROLE_MAP"].get(user["role"])

            session.clear()
            session["id_utilisateur"] = user["id_utilisateur"]
            session["nom"] = f'{user["prenom"]} {user["nom"]}'
            session["role"] = user["role"]
            session["role_pg"] = role_pg

            flash(f"Connecte en tant que {user['role']}", "success")
            return redirect(url_for("incidents.dashboard"))

        flash("Email ou mot de passe incorrect.", "danger")

    return render_template("login.html")


@bp.route("/logout")
def logout():
    session.clear()
    flash("Deconnecte.", "info")
    return redirect(url_for("auth.login"))
