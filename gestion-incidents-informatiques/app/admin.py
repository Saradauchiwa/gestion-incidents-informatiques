"""
Blueprint d'administration : gestion des utilisateurs et des roles.
Emplacement : app/admin.py
Nom du blueprint : "admin", prefixe "/admin"
Reserve au role ADMIN (seul role_pg ayant les droits complets sur
la table utilisateurs, voir GRANT ... TO admin_role dans le dump).
"""
from flask import Blueprint, render_template, request, redirect, url_for, flash, abort
from werkzeug.security import generate_password_hash

from app.db import get_db, dict_cursor
from app.helpers import login_required, roles_required

bp = Blueprint("admin", __name__, url_prefix="/admin")


@bp.route("/utilisateurs")
@login_required
@roles_required("ADMIN")
def liste_utilisateurs():
    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute(
            """
            SELECT id_utilisateur, nom, prenom, email, role,
                   service, actif, date_creation
            FROM utilisateurs
            ORDER BY nom, prenom
            """
        )
        utilisateurs = cur.fetchall()

    return render_template("admin/utilisateurs.html", utilisateurs=utilisateurs)


@bp.route("/utilisateurs/nouveau", methods=["GET", "POST"])
@login_required
@roles_required("ADMIN")
def creer_utilisateur():
    if request.method == "POST":
        nom = request.form["nom"].strip()
        prenom = request.form["prenom"].strip()
        email = request.form["email"].strip().lower()
        role = request.form["role"]
        service = request.form.get("service", "").strip()
        mot_de_passe = request.form["mot_de_passe"]

        hash_mdp = generate_password_hash(mot_de_passe)

        conn = get_db()
        with dict_cursor(conn) as cur:
            cur.execute(
                """
                INSERT INTO utilisateurs
                    (nom, prenom, email, mot_de_passe_hash, role, service, actif)
                VALUES (%s,%s,%s,%s,%s,%s, true)
                """,
                (nom, prenom, email, hash_mdp, role, service),
            )
        conn.commit()
        flash(f"Utilisateur {prenom} {nom} cree.", "success")
        return redirect(url_for("admin.liste_utilisateurs"))

    return render_template("admin/form_utilisateur.html", utilisateur=None)


@bp.route("/utilisateurs/<int:id_utilisateur>/modifier", methods=["GET", "POST"])
@login_required
@roles_required("ADMIN")
def modifier_utilisateur(id_utilisateur):
    conn = get_db()

    if request.method == "POST":
        nom = request.form["nom"].strip()
        prenom = request.form["prenom"].strip()
        email = request.form["email"].strip().lower()
        role = request.form["role"]
        service = request.form.get("service", "").strip()
        nouveau_mdp = request.form.get("mot_de_passe", "").strip()

        with dict_cursor(conn) as cur:
            if nouveau_mdp:
                cur.execute(
                    """
                    UPDATE utilisateurs
                    SET nom=%s, prenom=%s, email=%s, role=%s,
                        service=%s, mot_de_passe_hash=%s
                    WHERE id_utilisateur=%s
                    """,
                    (nom, prenom, email, role, service,
                     generate_password_hash(nouveau_mdp), id_utilisateur),
                )
            else:
                cur.execute(
                    """
                    UPDATE utilisateurs
                    SET nom=%s, prenom=%s, email=%s, role=%s, service=%s
                    WHERE id_utilisateur=%s
                    """,
                    (nom, prenom, email, role, service, id_utilisateur),
                )
        conn.commit()
        flash("Utilisateur mis a jour.", "success")
        return redirect(url_for("admin.liste_utilisateurs"))

    with dict_cursor(conn) as cur:
        cur.execute(
            "SELECT * FROM utilisateurs WHERE id_utilisateur = %s",
            (id_utilisateur,),
        )
        utilisateur = cur.fetchone()
        if utilisateur is None:
            abort(404)

    return render_template("admin/form_utilisateur.html", utilisateur=utilisateur)


@bp.route("/utilisateurs/<int:id_utilisateur>/basculer-actif", methods=["POST"])
@login_required
@roles_required("ADMIN")
def basculer_actif(id_utilisateur):
    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute(
            "UPDATE utilisateurs SET actif = NOT actif WHERE id_utilisateur = %s",
            (id_utilisateur,),
        )
    conn.commit()
    flash("Statut du compte modifie.", "info")
    return redirect(url_for("admin.liste_utilisateurs"))
