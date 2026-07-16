------------------------------------------------------------
-- 🔵 TRANSACTION 1 : Création incident + affectation + commentaire
------------------------------------------------------------

BEGIN;

-- Création de l'incident
SELECT public.creer_incident(
    'INC-DEMO-001',
    'Imprimante RH hors service',
    'Aucune impression possible depuis ce matin',
    (SELECT id_utilisateur FROM utilisateurs WHERE role = 'UTILISATEUR' LIMIT 1),
    (SELECT id_priorite FROM priorite ORDER BY niveau LIMIT 1),
    (SELECT id_statut FROM statut ORDER BY ordre LIMIT 1),
    (SELECT id_categorie FROM categorie LIMIT 1)
);

-- Affectation du technicien
SELECT public.affecter_technicien(
    (SELECT id_utilisateur FROM utilisateurs WHERE role = 'TECHNICIEN' LIMIT 1),
    (SELECT id_incident FROM incident WHERE reference = 'INC-DEMO-001'),
    'Affectation automatique a la creation'
);

-- Ajout commentaire via procédure (CALL)
DO $$
DECLARE
    v_id_technicien INTEGER;
    v_id_incident INTEGER;
BEGIN
    SELECT id_utilisateur INTO v_id_technicien
    FROM utilisateurs
    WHERE role = 'TECHNICIEN'
    LIMIT 1;

    SELECT id_incident INTO v_id_incident
    FROM incident
    WHERE reference = 'INC-DEMO-001';

    CALL public.ajouter_commentaire(
        'Ticket cree et affecte, prise en charge en cours.',
        v_id_technicien,
        v_id_incident
    );
END $$;

COMMIT;


------------------------------------------------------------
-- 🟡 TRANSACTION 2 : Intervention + clôture + SAVEPOINT
------------------------------------------------------------

BEGIN;

-- Intervention initiale
DO $$
DECLARE
    v_id_incident INTEGER;
    v_id_statut INTEGER;
BEGIN
    SELECT id_incident INTO v_id_incident
    FROM incident
    WHERE reference = 'INC-DEMO-001';

    SELECT id_statut INTO v_id_statut
    FROM statut
    ORDER BY ordre
    LIMIT 1;

    CALL public.ajouter_intervention(
        'Redemarrage du service impression',
        30,
        v_id_incident,
        v_id_statut
    );
END $$;

SAVEPOINT avant_cloture;

-- Clôture incident
DO $$
DECLARE
    v_id_incident INTEGER;
BEGIN
    SELECT id_incident INTO v_id_incident
    FROM incident
    WHERE reference = 'INC-DEMO-001';

    CALL public.cloturer_incident(v_id_incident);
END $$;

SAVEPOINT apres_cloture;

-- Intervention de test (sera annulée)
DO $$
DECLARE
    v_id_incident INTEGER;
    v_id_statut INTEGER;
BEGIN
    SELECT id_incident INTO v_id_incident
    FROM incident
    WHERE reference = 'INC-DEMO-001';

    SELECT id_statut INTO v_id_statut
    FROM statut
    ORDER BY ordre
    LIMIT 1;

    CALL public.ajouter_intervention(
        'Intervention de test',
        15,
        v_id_incident,
        v_id_statut
    );
END $$;

-- Annulation uniquement de la dernière opération
ROLLBACK TO SAVEPOINT apres_cloture;

COMMIT;


------------------------------------------------------------
-- 🔴 TRANSACTION 3 : Test de rollback (erreur volontaire FK)
------------------------------------------------------------

BEGIN;

-- Test d'erreur volontaire (clé étrangère invalide)
SELECT public.creer_incident(
    'INC-DEMO-ERREUR',
    'Test de rollback complet',
    'Ne doit jamais apparaitre en base',
    (SELECT id_utilisateur FROM utilisateurs WHERE role = 'UTILISATEUR' LIMIT 1),
    999999,   -- ❌ ID invalide pour provoquer une erreur FK
    (SELECT id_statut FROM statut ORDER BY ordre LIMIT 1),
    (SELECT id_categorie FROM categorie LIMIT 1)
);

-- Transaction annulée automatiquement après erreur
ROLLBACK;