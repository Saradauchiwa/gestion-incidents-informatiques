-- ============================================================
-- roles_privileges.sql
-- A exécuter UNE SEULE FOIS, en tant que superuser (postgres),
-- APRES avoir importé script_examen_BDD.sql
-- Emplacement : sql/roles_privileges.sql
-- ============================================================

-- 1. Rôle de connexion utilisé par l'application Flask (DB_USER dans .env)
--    Il ne possède aucun privilège en propre : il "devient" l'un des
--    3 rôles métier via SET ROLE (voir app/db.py), selon le rôle
--    applicatif de la personne connectée.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_login') THEN
        CREATE ROLE app_login LOGIN PASSWORD 'app_login';
    END IF;
END
$$;

-- 2. Les 3 rôles métier demandés par le cahier des charges.
--    NOLOGIN car on ne s'y connecte jamais directement : on y bascule
--    depuis app_login avec SET ROLE.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_role') THEN
        CREATE ROLE admin_role NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'technicien_role') THEN
        CREATE ROLE technicien_role NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'utilisateur_role') THEN
        CREATE ROLE utilisateur_role NOLOGIN;
    END IF;
END
$$;

-- 3. app_login a le droit de SET ROLE vers les 3 rôles métier
GRANT admin_role       TO app_login;
GRANT technicien_role  TO app_login;
GRANT utilisateur_role TO app_login;

-- 4. Les GRANT sur les TABLES/VUES/SEQUENCES sont déjà dans
--    script_examen_BDD.sql (lignes GRANT ... TO admin_role / technicien_role
--    / utilisateur_role). Ici on complète ce qui manquait : les
--    privilèges d'EXECUTE sur les fonctions et procédures PL/pgSQL.

-- Par défaut PostgreSQL donne EXECUTE à PUBLIC : on ferme d'abord.
REVOKE EXECUTE ON FUNCTION public.affecter_technicien(integer, integer, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.changer_statut_incident(integer, integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.creer_incident(character varying, character varying, text, integer, integer, integer, integer) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE public.ajouter_commentaire(text, integer, integer) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE public.ajouter_intervention(text, integer, integer, integer) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE public.cloturer_incident(integer) FROM PUBLIC;

-- ADMIN : accès total à toutes les opérations métier
GRANT EXECUTE ON FUNCTION public.affecter_technicien(integer, integer, text) TO admin_role;
GRANT EXECUTE ON FUNCTION public.changer_statut_incident(integer, integer) TO admin_role;
GRANT EXECUTE ON FUNCTION public.creer_incident(character varying, character varying, text, integer, integer, integer, integer) TO admin_role;
GRANT EXECUTE ON PROCEDURE public.ajouter_commentaire(text, integer, integer) TO admin_role;
GRANT EXECUTE ON PROCEDURE public.ajouter_intervention(text, integer, integer, integer) TO admin_role;
GRANT EXECUTE ON PROCEDURE public.cloturer_incident(integer) TO admin_role;

-- TECHNICIEN : peut traiter les incidents (affecter, intervenir,
-- commenter, changer le statut, clôturer) mais pas en créer un nouveau
-- pour un tiers ni gérer les comptes.
GRANT EXECUTE ON FUNCTION public.affecter_technicien(integer, integer, text) TO technicien_role;
GRANT EXECUTE ON FUNCTION public.changer_statut_incident(integer, integer) TO technicien_role;
GRANT EXECUTE ON PROCEDURE public.ajouter_commentaire(text, integer, integer) TO technicien_role;
GRANT EXECUTE ON PROCEDURE public.ajouter_intervention(text, integer, integer, integer) TO technicien_role;
GRANT EXECUTE ON PROCEDURE public.cloturer_incident(integer) TO technicien_role;

-- UTILISATEUR : peut seulement créer un incident et commenter le sien
GRANT EXECUTE ON FUNCTION public.creer_incident(character varying, character varying, text, integer, integer, integer, integer) TO utilisateur_role;
GRANT EXECUTE ON PROCEDURE public.ajouter_commentaire(text, integer, integer) TO utilisateur_role;

-- 5. CORRECTION D'UN TROU DE SECURITE DU DUMP D'ORIGINE :
--    script_examen_BDD.sql ne donne AUCUN droit SELECT sur
--    affectation / commentaire / intervention aux rôles technicien_role
--    et utilisateur_role (ils peuvent seulement y faire des INSERT).
--    Résultat : impossible d'afficher l'historique d'un incident dans
--    l'appli pour ces 2 rôles. On corrige ici.
GRANT SELECT ON public.affectation  TO technicien_role, utilisateur_role;
GRANT SELECT ON public.commentaire  TO technicien_role, utilisateur_role;
GRANT SELECT ON public.intervention TO technicien_role, utilisateur_role;

--    Idem pour les 3 vues (incidents_ouverts, statistiques_incidents,
--    suivi_incidents) : le dump ne les GRANT qu'à admin_role, alors
--    que le dashboard doit être visible par tous les rôles connectés.
GRANT SELECT ON public.incidents_ouverts      TO technicien_role, utilisateur_role;
GRANT SELECT ON public.statistiques_incidents TO technicien_role, utilisateur_role;
GRANT SELECT ON public.suivi_incidents        TO technicien_role;

-- 6. Vérification rapide (à lancer manuellement) :
-- \du            -> liste les rôles et confirme leur création
-- \z incident    -> liste les privilèges sur la table incident


GRANT SELECT ON public.utilisateurs TO utilisateur_role;