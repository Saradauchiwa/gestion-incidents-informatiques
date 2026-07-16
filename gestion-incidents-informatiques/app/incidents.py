"""
Blueprint metier : tableau de bord + gestion des incidents.
Emplacement : app/incidents.py
Nom du blueprint : "incidents"  (url_for("incidents.dashboard"), etc.)
"""
from flask import (
    Blueprint, render_template, request, redirect,
    url_for, session, flash, abort
)

from app.db import get_db, dict_cursor
from app.helpers import login_required, roles_required

bp = Blueprint("incidents", __name__)


# ------------------------------------------------------------------
# TABLEAU DE BORD
# ------------------------------------------------------------------
@bp.route("/dashboard")
@login_required
def dashboard():
    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute("SELECT * FROM statistiques_incidents")
        stats = cur.fetchall()

        cur.execute(
            """
            SELECT reference, titre, priorite, date_ouverture
            FROM incidents_ouverts
            ORDER BY date_ouverture DESC
            LIMIT 10
            """
        )
        derniers_ouverts = cur.fetchall()

    return render_template(
        "dashboard.html", stats=stats, derniers_ouverts=derniers_ouverts
    )


# ------------------------------------------------------------------
# LISTE DES INCIDENTS
# ------------------------------------------------------------------
@bp.route("/incidents")
@login_required
def liste_incidents():
    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute(
            """
            SELECT i.id_incident, i.reference, i.titre,
                   s.nom AS statut, p.nom AS priorite,
                   i.date_ouverture
            FROM incident i
            JOIN statut s   ON s.id_statut = i.id_statut
            JOIN priorite p ON p.id_priorite = i.id_priorite
            ORDER BY i.date_ouverture DESC
            """
        )
        incidents = cur.fetchall()

    return render_template("incidents/liste.html", incidents=incidents)


# ------------------------------------------------------------------
# CREATION D'UN INCIDENT
# ------------------------------------------------------------------
@bp.route("/incidents/nouveau", methods=["GET", "POST"])
@login_required
@roles_required("ADMIN", "UTILISATEUR")
def creer_incident():
    conn = get_db()

    if request.method == "POST":
        reference = request.form["reference"].strip()
        titre = request.form["titre"].strip()
        description = request.form["description"].strip()
        id_priorite = request.form["id_priorite"]
        id_categorie = request.form["id_categorie"]

        with dict_cursor(conn) as cur:
            cur.execute(
                "SELECT id_statut FROM statut ORDER BY ordre LIMIT 1"
            )
            id_statut = cur.fetchone()["id_statut"]

            cur.execute(
                "SELECT public.creer_incident(%s,%s,%s,%s,%s,%s,%s)",
                (
                    reference,
                    titre,
                    description,
                    session["id_utilisateur"],
                    id_priorite,
                    id_statut,
                    id_categorie,
                ),
            )
        conn.commit()
        flash(f"Incident {reference} cree avec succes.", "success")
        return redirect(url_for("incidents.liste_incidents"))

    with dict_cursor(conn) as cur:
        cur.execute("SELECT id_priorite, nom FROM priorite ORDER BY niveau")
        priorites = cur.fetchall()
        cur.execute("SELECT id_categorie, nom FROM categorie ORDER BY nom")
        categories = cur.fetchall()

    return render_template(
        "incidents/form.html", priorites=priorites, categories=categories
    )


# ------------------------------------------------------------------
# DETAIL D'UN INCIDENT (+ historique complet)
# ------------------------------------------------------------------
@bp.route("/incidents/<int:id_incident>")
@login_required
def detail_incident(id_incident):
    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute(
            """
            SELECT i.*, s.nom AS statut_nom, p.nom AS priorite_nom,
                   c.nom AS categorie_nom,
                   u.nom AS declarant_nom, u.prenom AS declarant_prenom
            FROM incident i
            JOIN statut s     ON s.id_statut = i.id_statut
            JOIN priorite p   ON p.id_priorite = i.id_priorite
            JOIN categorie c  ON c.id_categorie = i.id_categorie
            JOIN utilisateurs u ON u.id_utilisateur = i.id_utilisateur
            WHERE i.id_incident = %s
            """,
            (id_incident,),
        )
        incident = cur.fetchone()
        if incident is None:
            abort(404)

        cur.execute(
            """
            SELECT c.contenu, c.date_creation, u.nom, u.prenom
            FROM commentaire c
            JOIN utilisateurs u ON u.id_utilisateur = c.id_utilisateur
            WHERE c.id_incident = %s
            ORDER BY c.date_creation
            """,
            (id_incident,),
        )
        commentaires = cur.fetchall()

        cur.execute(
            """
            SELECT description, date_intervention, duree_minutes
            FROM intervention
            WHERE id_incident = %s
            ORDER BY date_intervention
            """,
            (id_incident,),
        )
        interventions = cur.fetchall()

        cur.execute(
            """
            SELECT a.date_affectation, a.actif, a.commentaire,
                   u.nom, u.prenom
            FROM affectation a
            JOIN utilisateurs u ON u.id_utilisateur = a.id_utilisateur
            WHERE a.id_incident = %s
            ORDER BY a.date_affectation DESC
            """,
            (id_incident,),
        )
        affectations = cur.fetchall()

        techniciens = []
        if session.get("role") in ("ADMIN", "TECHNICIEN"):
            cur.execute(
                "SELECT id_utilisateur, nom, prenom FROM utilisateurs "
                "WHERE role = 'TECHNICIEN' AND actif = true ORDER BY nom"
            )
            techniciens = cur.fetchall()

        statuts = []
        if session.get("role") in ("ADMIN", "TECHNICIEN"):
            cur.execute("SELECT id_statut, nom FROM statut ORDER BY ordre")
            statuts = cur.fetchall()

    return render_template(
        "incidents/detail.html",
        incident=incident,
        commentaires=commentaires,
        interventions=interventions,
        affectations=affectations,
        techniciens=techniciens,
        statuts=statuts,
    )


# ------------------------------------------------------------------
# ACTIONS SUR UN INCIDENT (reservees ADMIN / TECHNICIEN sauf commentaire)
# ------------------------------------------------------------------
@bp.route("/incidents/<int:id_incident>/affecter", methods=["POST"])
@login_required
@roles_required("ADMIN", "TECHNICIEN")
def affecter(id_incident):
    id_technicien = request.form["id_technicien"]
    commentaire = request.form.get("commentaire", "")

    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute(
            "SELECT public.affecter_technicien(%s,%s,%s)",
            (id_technicien, id_incident, commentaire),
        )
    conn.commit()
    flash("Technicien affecte a l'incident.", "success")
    return redirect(url_for("incidents.detail_incident", id_incident=id_incident))


@bp.route("/incidents/<int:id_incident>/commentaire", methods=["POST"])
@login_required
def commenter(id_incident):
    contenu = request.form["contenu"].strip()

    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute(
            "CALL public.ajouter_commentaire(%s,%s,%s)",
            (contenu, session["id_utilisateur"], id_incident),
        )
    conn.commit()
    flash("Commentaire ajoute.", "success")
    return redirect(url_for("incidents.detail_incident", id_incident=id_incident))


@bp.route("/incidents/<int:id_incident>/intervention", methods=["POST"])
@login_required
@roles_required("ADMIN", "TECHNICIEN")
def intervenir(id_incident):
    description = request.form["description"].strip()
    duree = request.form["duree_minutes"]
    id_statut = request.form["id_statut"]

    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute(
            "CALL public.ajouter_intervention(%s,%s,%s,%s)",
            (description, duree, id_incident, id_statut),
        )
    conn.commit()
    flash("Intervention enregistree.", "success")
    return redirect(url_for("incidents.detail_incident", id_incident=id_incident))


@bp.route("/incidents/<int:id_incident>/statut", methods=["POST"])
@login_required
@roles_required("ADMIN", "TECHNICIEN")
def changer_statut(id_incident):
    id_statut = request.form["id_statut"]

    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute(
            "SELECT public.changer_statut_incident(%s,%s)",
            (id_incident, id_statut),
        )
    conn.commit()
    flash("Statut mis a jour.", "success")
    return redirect(url_for("incidents.detail_incident", id_incident=id_incident))


@bp.route("/incidents/<int:id_incident>/cloturer", methods=["POST"])
@login_required
@roles_required("ADMIN", "TECHNICIEN")
def cloturer(id_incident):
    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute("CALL public.cloturer_incident(%s)", (id_incident,))
    conn.commit()
    flash("Incident cloture.", "success")
    return redirect(url_for("incidents.detail_incident", id_incident=id_incident))


# ------------------------------------------------------------------
# JOURNAL D'AUDIT (reserve ADMIN, seul role ayant SELECT sur audit)
# ------------------------------------------------------------------
@bp.route("/audit")
@login_required
@roles_required("ADMIN")
def journal_audit():
    conn = get_db()
    with dict_cursor(conn) as cur:
        cur.execute(
            """
            SELECT id_audit, operation, table_nom, ancienne_valeur,
                   nouvelle_valeur, date_action, utilisateur
            FROM audit
            ORDER BY date_action DESC
            LIMIT 200
            """
        )
        entrees = cur.fetchall()

    return render_template("audit.html", entrees=entrees)
