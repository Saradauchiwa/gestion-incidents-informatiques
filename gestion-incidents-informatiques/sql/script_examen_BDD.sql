--
-- PostgreSQL database dump
--

\restrict 6cePvubg8bYZMae47WN6n1AIWAS07qhvbg3fQBuw0lDy7KUcm9IkKL93i4Su0Wc

-- Dumped from database version 16.14 (Debian 16.14-1.pgdg13+1)
-- Dumped by pg_dump version 18.4

-- Started on 2026-07-04 01:57:34

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 3553 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- TOC entry 236 (class 1255 OID 24821)
-- Name: affecter_technicien(integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.affecter_technicien(p_technicien integer, p_incident integer, p_commentaire text) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN


INSERT INTO affectation
(
id_utilisateur,
id_incident,
commentaire
)

VALUES
(
p_technicien,
p_incident,
p_commentaire
);


END;

$$;


ALTER FUNCTION public.affecter_technicien(p_technicien integer, p_incident integer, p_commentaire text) OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 24991)
-- Name: ajouter_commentaire(text, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.ajouter_commentaire(IN p_contenu text, IN p_utilisateur integer, IN p_incident integer)
    LANGUAGE plpgsql
    AS $$

BEGIN

    INSERT INTO commentaire
    (
        contenu,
        id_utilisateur,
        id_incident
    )

    VALUES
    (
        p_contenu,
        p_utilisateur,
        p_incident
    );

END;

$$;


ALTER PROCEDURE public.ajouter_commentaire(IN p_contenu text, IN p_utilisateur integer, IN p_incident integer) OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 24992)
-- Name: ajouter_intervention(text, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.ajouter_intervention(IN p_description text, IN p_duree integer, IN p_incident integer, IN p_statut integer)
    LANGUAGE plpgsql
    AS $$

BEGIN

    INSERT INTO intervention
    (
        description,
        duree_minutes,
        id_incident,
        id_statut
    )

    VALUES
    (
        p_description,
        p_duree,
        p_incident,
        p_statut
    );

END;

$$;


ALTER PROCEDURE public.ajouter_intervention(IN p_description text, IN p_duree integer, IN p_incident integer, IN p_statut integer) OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 24822)
-- Name: changer_statut_incident(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.changer_statut_incident(p_incident integer, p_nouveau_statut integer) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN


UPDATE incident

SET id_statut = p_nouveau_statut

WHERE id_incident = p_incident;


END;

$$;


ALTER FUNCTION public.changer_statut_incident(p_incident integer, p_nouveau_statut integer) OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 24990)
-- Name: cloturer_incident(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.cloturer_incident(IN p_id_incident integer)
    LANGUAGE plpgsql
    AS $$

BEGIN

    UPDATE incident

    SET
        id_statut = (
            SELECT id_statut
            FROM statut
            WHERE nom = 'FERME'
        ),
        date_cloture = CURRENT_TIMESTAMP

    WHERE id_incident = p_id_incident;

END;

$$;


ALTER PROCEDURE public.cloturer_incident(IN p_id_incident integer) OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 24823)
-- Name: creer_incident(character varying, character varying, text, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.creer_incident(p_reference character varying, p_titre character varying, p_description text, p_utilisateur integer, p_priorite integer, p_statut integer, p_categorie integer) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN


INSERT INTO incident
(
reference,
titre,
description,
id_utilisateur,
id_priorite,
id_statut,
id_categorie
)

VALUES
(
p_reference,
p_titre,
p_description,
p_utilisateur,
p_priorite,
p_statut,
p_categorie
);


END;

$$;


ALTER FUNCTION public.creer_incident(p_reference character varying, p_titre character varying, p_description text, p_utilisateur integer, p_priorite integer, p_statut integer, p_categorie integer) OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 24981)
-- Name: fn_audit_incident(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_audit_incident() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit(operation, table_nom, nouvelle_valeur, utilisateur)
        VALUES ('INSERT', 'incident', row_to_json(NEW)::text, current_user);
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit(operation, table_nom, ancienne_valeur, nouvelle_valeur, utilisateur)
        VALUES ('UPDATE', 'incident', row_to_json(OLD)::text, row_to_json(NEW)::text, current_user);
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit(operation, table_nom, ancienne_valeur, utilisateur)
        VALUES ('DELETE', 'incident', row_to_json(OLD)::text, current_user);
        RETURN OLD;

    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_audit_incident() OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 24983)
-- Name: fn_cloture_incident(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_cloture_incident() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF NEW.id_statut IS NOT NULL THEN

        IF EXISTS (
            SELECT 1 FROM statut
            WHERE id_statut = NEW.id_statut
            AND est_final = true
        ) THEN
            NEW.date_cloture = CURRENT_TIMESTAMP;
        END IF;

    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_cloture_incident() OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 24985)
-- Name: fn_verif_incident(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_verif_incident() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF NEW.id_priorite IS NULL THEN
        RAISE EXCEPTION 'Priorité obligatoire pour créer un incident';
    END IF;

    IF NEW.id_statut IS NULL THEN
        RAISE EXCEPTION 'Statut obligatoire pour créer un incident';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_verif_incident() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 24824)
-- Name: affectation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.affectation (
    id_affectation integer NOT NULL,
    date_affectation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    date_fin timestamp without time zone,
    actif boolean DEFAULT true,
    commentaire text,
    id_utilisateur integer,
    id_incident integer
);


ALTER TABLE public.affectation OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 24831)
-- Name: affectation_id_affectation_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.affectation_id_affectation_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.affectation_id_affectation_seq OWNER TO postgres;

--
-- TOC entry 3562 (class 0 OID 0)
-- Dependencies: 216
-- Name: affectation_id_affectation_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.affectation_id_affectation_seq OWNED BY public.affectation.id_affectation;


--
-- TOC entry 217 (class 1259 OID 24832)
-- Name: audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit (
    id_audit integer NOT NULL,
    operation character varying(20),
    table_nom character varying(50),
    ancienne_valeur text,
    nouvelle_valeur text,
    date_action timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    utilisateur character varying(100)
);


ALTER TABLE public.audit OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 24838)
-- Name: audit_id_audit_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_id_audit_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_id_audit_seq OWNER TO postgres;

--
-- TOC entry 3565 (class 0 OID 0)
-- Dependencies: 218
-- Name: audit_id_audit_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_id_audit_seq OWNED BY public.audit.id_audit;


--
-- TOC entry 219 (class 1259 OID 24839)
-- Name: categorie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorie (
    id_categorie integer NOT NULL,
    nom character varying(50) NOT NULL,
    description text
);


ALTER TABLE public.categorie OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 24844)
-- Name: categorie_id_categorie_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categorie_id_categorie_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categorie_id_categorie_seq OWNER TO postgres;

--
-- TOC entry 3568 (class 0 OID 0)
-- Dependencies: 220
-- Name: categorie_id_categorie_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categorie_id_categorie_seq OWNED BY public.categorie.id_categorie;


--
-- TOC entry 221 (class 1259 OID 24845)
-- Name: commentaire; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.commentaire (
    id_commentaire integer NOT NULL,
    contenu text NOT NULL,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_utilisateur integer,
    id_incident integer
);


ALTER TABLE public.commentaire OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 24851)
-- Name: commentaire_id_commentaire_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.commentaire_id_commentaire_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.commentaire_id_commentaire_seq OWNER TO postgres;

--
-- TOC entry 3571 (class 0 OID 0)
-- Dependencies: 222
-- Name: commentaire_id_commentaire_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.commentaire_id_commentaire_seq OWNED BY public.commentaire.id_commentaire;


--
-- TOC entry 223 (class 1259 OID 24852)
-- Name: incident; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.incident (
    id_incident integer NOT NULL,
    reference character varying(30) NOT NULL,
    titre character varying(200) NOT NULL,
    description text,
    date_ouverture timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    date_limite_resolution timestamp without time zone,
    date_cloture timestamp without time zone,
    id_utilisateur integer NOT NULL,
    id_priorite integer,
    id_statut integer,
    id_categorie integer
);


ALTER TABLE public.incident OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 24858)
-- Name: incident_id_incident_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.incident_id_incident_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.incident_id_incident_seq OWNER TO postgres;

--
-- TOC entry 3574 (class 0 OID 0)
-- Dependencies: 224
-- Name: incident_id_incident_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.incident_id_incident_seq OWNED BY public.incident.id_incident;


--
-- TOC entry 225 (class 1259 OID 24859)
-- Name: priorite; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.priorite (
    id_priorite integer NOT NULL,
    nom character varying(50) NOT NULL,
    niveau integer NOT NULL,
    delai_resolution_heures integer NOT NULL
);


ALTER TABLE public.priorite OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 24862)
-- Name: statut; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.statut (
    id_statut integer NOT NULL,
    nom character varying(50) NOT NULL,
    ordre integer,
    est_final boolean DEFAULT false
);


ALTER TABLE public.statut OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 24866)
-- Name: incidents_ouverts; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.incidents_ouverts AS
 SELECT i.id_incident,
    i.reference,
    i.titre,
    i.description,
    i.date_ouverture,
    s.nom AS statut,
    p.nom AS priorite
   FROM ((public.incident i
     JOIN public.statut s ON ((i.id_statut = s.id_statut)))
     JOIN public.priorite p ON ((i.id_priorite = p.id_priorite)))
  WHERE ((s.nom)::text = 'OUVERT'::text);


ALTER VIEW public.incidents_ouverts OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 24871)
-- Name: intervention; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.intervention (
    id_intervention integer NOT NULL,
    description text,
    date_intervention timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    duree_minutes integer,
    id_incident integer,
    id_statut integer
);


ALTER TABLE public.intervention OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 24877)
-- Name: intervention_id_intervention_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.intervention_id_intervention_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.intervention_id_intervention_seq OWNER TO postgres;

--
-- TOC entry 3580 (class 0 OID 0)
-- Dependencies: 229
-- Name: intervention_id_intervention_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.intervention_id_intervention_seq OWNED BY public.intervention.id_intervention;


--
-- TOC entry 230 (class 1259 OID 24878)
-- Name: priorite_id_priorite_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.priorite_id_priorite_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.priorite_id_priorite_seq OWNER TO postgres;

--
-- TOC entry 3582 (class 0 OID 0)
-- Dependencies: 230
-- Name: priorite_id_priorite_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.priorite_id_priorite_seq OWNED BY public.priorite.id_priorite;


--
-- TOC entry 231 (class 1259 OID 24879)
-- Name: statistiques_incidents; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.statistiques_incidents AS
 SELECT s.nom AS statut,
    count(i.id_incident) AS nombre_incidents
   FROM (public.incident i
     JOIN public.statut s ON ((i.id_statut = s.id_statut)))
  GROUP BY s.nom;


ALTER VIEW public.statistiques_incidents OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 24883)
-- Name: statut_id_statut_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.statut_id_statut_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.statut_id_statut_seq OWNER TO postgres;

--
-- TOC entry 3585 (class 0 OID 0)
-- Dependencies: 232
-- Name: statut_id_statut_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.statut_id_statut_seq OWNED BY public.statut.id_statut;


--
-- TOC entry 233 (class 1259 OID 24884)
-- Name: utilisateurs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.utilisateurs (
    id_utilisateur integer NOT NULL,
    nom character varying(50) NOT NULL,
    prenom character varying(50),
    email character varying(100) NOT NULL,
    mot_de_passe_hash text NOT NULL,
    role character varying(20),
    telephone character varying(20),
    service character varying(100),
    actif boolean DEFAULT true,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT utilisateurs_role_check CHECK (((role)::text = ANY (ARRAY[('ADMIN'::character varying)::text, ('TECHNICIEN'::character varying)::text, ('UTILISATEUR'::character varying)::text])))
);


ALTER TABLE public.utilisateurs OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 24892)
-- Name: suivi_incidents; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.suivi_incidents AS
 SELECT i.reference,
    i.titre,
    i.description,
    (((u.nom)::text || ' '::text) || (u.prenom)::text) AS utilisateur,
    c.nom AS categorie,
    p.nom AS priorite,
    s.nom AS statut,
    i.date_ouverture
   FROM ((((public.incident i
     JOIN public.utilisateurs u ON ((i.id_utilisateur = u.id_utilisateur)))
     JOIN public.categorie c ON ((i.id_categorie = c.id_categorie)))
     JOIN public.priorite p ON ((i.id_priorite = p.id_priorite)))
     JOIN public.statut s ON ((i.id_statut = s.id_statut)));


ALTER VIEW public.suivi_incidents OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 24897)
-- Name: utilisateurs_id_utilisateur_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.utilisateurs_id_utilisateur_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.utilisateurs_id_utilisateur_seq OWNER TO postgres;

--
-- TOC entry 3589 (class 0 OID 0)
-- Dependencies: 235
-- Name: utilisateurs_id_utilisateur_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.utilisateurs_id_utilisateur_seq OWNED BY public.utilisateurs.id_utilisateur;


--
-- TOC entry 3328 (class 2604 OID 24898)
-- Name: affectation id_affectation; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation ALTER COLUMN id_affectation SET DEFAULT nextval('public.affectation_id_affectation_seq'::regclass);


--
-- TOC entry 3331 (class 2604 OID 24899)
-- Name: audit id_audit; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit ALTER COLUMN id_audit SET DEFAULT nextval('public.audit_id_audit_seq'::regclass);


--
-- TOC entry 3333 (class 2604 OID 24900)
-- Name: categorie id_categorie; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie ALTER COLUMN id_categorie SET DEFAULT nextval('public.categorie_id_categorie_seq'::regclass);


--
-- TOC entry 3334 (class 2604 OID 24901)
-- Name: commentaire id_commentaire; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commentaire ALTER COLUMN id_commentaire SET DEFAULT nextval('public.commentaire_id_commentaire_seq'::regclass);


--
-- TOC entry 3336 (class 2604 OID 24902)
-- Name: incident id_incident; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident ALTER COLUMN id_incident SET DEFAULT nextval('public.incident_id_incident_seq'::regclass);


--
-- TOC entry 3341 (class 2604 OID 24903)
-- Name: intervention id_intervention; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention ALTER COLUMN id_intervention SET DEFAULT nextval('public.intervention_id_intervention_seq'::regclass);


--
-- TOC entry 3338 (class 2604 OID 24904)
-- Name: priorite id_priorite; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.priorite ALTER COLUMN id_priorite SET DEFAULT nextval('public.priorite_id_priorite_seq'::regclass);


--
-- TOC entry 3339 (class 2604 OID 24905)
-- Name: statut id_statut; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut ALTER COLUMN id_statut SET DEFAULT nextval('public.statut_id_statut_seq'::regclass);


--
-- TOC entry 3343 (class 2604 OID 24906)
-- Name: utilisateurs id_utilisateur; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateurs ALTER COLUMN id_utilisateur SET DEFAULT nextval('public.utilisateurs_id_utilisateur_seq'::regclass);


--
-- TOC entry 3530 (class 0 OID 24824)
-- Dependencies: 215
-- Data for Name: affectation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.affectation (id_affectation, date_affectation, date_fin, actif, commentaire, id_utilisateur, id_incident) FROM stdin;
7	2026-07-04 01:02:18.333608	\N	t	Affectation automatique a la creation	2	15
\.


--
-- TOC entry 3532 (class 0 OID 24832)
-- Dependencies: 217
-- Data for Name: audit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit (id_audit, operation, table_nom, ancienne_valeur, nouvelle_valeur, date_action, utilisateur) FROM stdin;
1	INSERT	incident	\N	{"id_incident":11,"reference":"INC001","titre":"Panne réseau","description":"Internet indisponible","date_ouverture":"2026-07-02T17:53:04.214036","date_limite_resolution":null,"date_cloture":null,"id_utilisateur":2,"id_priorite":1,"id_statut":1,"id_categorie":2}	2026-07-02 17:53:04.214036	postgres
2	UPDATE	incident	{"id_incident":11,"reference":"INC001","titre":"Panne réseau","description":"Internet indisponible","date_ouverture":"2026-07-02T17:53:04.214036","date_limite_resolution":null,"date_cloture":null,"id_utilisateur":2,"id_priorite":1,"id_statut":1,"id_categorie":2}	{"id_incident":11,"reference":"INC001","titre":"Panne réseau corrigée","description":"Internet indisponible","date_ouverture":"2026-07-02T17:53:04.214036","date_limite_resolution":null,"date_cloture":null,"id_utilisateur":2,"id_priorite":1,"id_statut":1,"id_categorie":2}	2026-07-02 18:38:24.849966	postgres
5	INSERT	incident	\N	{"id_incident":15,"reference":"INC-DEMO-001","titre":"Imprimante RH hors service","description":"Aucune impression possible depuis ce matin","date_ouverture":"2026-07-04T01:02:18.333608","date_limite_resolution":null,"date_cloture":null,"id_utilisateur":3,"id_priorite":1,"id_statut":1,"id_categorie":2}	2026-07-04 01:02:18.333608	postgres
6	UPDATE	incident	{"id_incident":15,"reference":"INC-DEMO-001","titre":"Imprimante RH hors service","description":"Aucune impression possible depuis ce matin","date_ouverture":"2026-07-04T01:02:18.333608","date_limite_resolution":null,"date_cloture":null,"id_utilisateur":3,"id_priorite":1,"id_statut":1,"id_categorie":2}	{"id_incident":15,"reference":"INC-DEMO-001","titre":"Imprimante RH hors service","description":"Aucune impression possible depuis ce matin","date_ouverture":"2026-07-04T01:02:18.333608","date_limite_resolution":null,"date_cloture":"2026-07-04T01:17:32.537882","id_utilisateur":3,"id_priorite":1,"id_statut":null,"id_categorie":2}	2026-07-04 01:17:32.537882	postgres
\.


--
-- TOC entry 3534 (class 0 OID 24839)
-- Dependencies: 219
-- Data for Name: categorie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categorie (id_categorie, nom, description) FROM stdin;
2	Réseau	Incidents liés au réseau
3	Logiciel	Problèmes logiciels
4	Matériel	Pannes matérielles
\.


--
-- TOC entry 3536 (class 0 OID 24845)
-- Dependencies: 221
-- Data for Name: commentaire; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.commentaire (id_commentaire, contenu, date_creation, id_utilisateur, id_incident) FROM stdin;
1	Ticket cree et affecte, prise en charge en cours.	2026-07-04 01:02:18.333608	2	15
\.


--
-- TOC entry 3538 (class 0 OID 24852)
-- Dependencies: 223
-- Data for Name: incident; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.incident (id_incident, reference, titre, description, date_ouverture, date_limite_resolution, date_cloture, id_utilisateur, id_priorite, id_statut, id_categorie) FROM stdin;
11	INC001	Panne réseau corrigée	Internet indisponible	2026-07-02 17:53:04.214036	\N	\N	2	1	1	2
15	INC-DEMO-001	Imprimante RH hors service	Aucune impression possible depuis ce matin	2026-07-04 01:02:18.333608	\N	2026-07-04 01:17:32.537882	3	1	\N	2
\.


--
-- TOC entry 3542 (class 0 OID 24871)
-- Dependencies: 228
-- Data for Name: intervention; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.intervention (id_intervention, description, date_intervention, duree_minutes, id_incident, id_statut) FROM stdin;
2	Problème résolu après remplacement du routeur	2026-07-02 18:06:45.672286	45	11	3
3	Redemarrage du service impression	2026-07-04 01:17:32.537882	30	15	1
\.


--
-- TOC entry 3540 (class 0 OID 24859)
-- Dependencies: 225
-- Data for Name: priorite; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.priorite (id_priorite, nom, niveau, delai_resolution_heures) FROM stdin;
1	Faible	1	72
2	Moyenne	2	24
3	Haute	3	8
\.


--
-- TOC entry 3541 (class 0 OID 24862)
-- Dependencies: 226
-- Data for Name: statut; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.statut (id_statut, nom, ordre, est_final) FROM stdin;
1	OUVERT	1	f
2	EN COURS	2	f
3	CLOTURE	3	t
\.


--
-- TOC entry 3546 (class 0 OID 24884)
-- Dependencies: 233
-- Data for Name: utilisateurs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.utilisateurs (id_utilisateur, nom, prenom, email, mot_de_passe_hash, role, telephone, service, actif, date_creation) FROM stdin;
1	Diop	Ali	ali.diop@example.com	motdepasse123	ADMIN	\N	\N	t	2026-07-02 16:54:58.045229
2	Ndiaye	Fatou	fatou.ndiaye@example.com	motdepasse456	TECHNICIEN	\N	\N	t	2026-07-02 16:54:58.045229
3	Fall	Moussa	moussa.fall@example.com	motdepasse789	UTILISATEUR	\N	\N	t	2026-07-02 16:54:58.045229
\.


--
-- TOC entry 3591 (class 0 OID 0)
-- Dependencies: 216
-- Name: affectation_id_affectation_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.affectation_id_affectation_seq', 7, true);


--
-- TOC entry 3592 (class 0 OID 0)
-- Dependencies: 218
-- Name: audit_id_audit_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_id_audit_seq', 6, true);


--
-- TOC entry 3593 (class 0 OID 0)
-- Dependencies: 220
-- Name: categorie_id_categorie_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categorie_id_categorie_seq', 4, true);


--
-- TOC entry 3594 (class 0 OID 0)
-- Dependencies: 222
-- Name: commentaire_id_commentaire_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.commentaire_id_commentaire_seq', 1, true);


--
-- TOC entry 3595 (class 0 OID 0)
-- Dependencies: 224
-- Name: incident_id_incident_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.incident_id_incident_seq', 17, true);


--
-- TOC entry 3596 (class 0 OID 0)
-- Dependencies: 229
-- Name: intervention_id_intervention_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.intervention_id_intervention_seq', 4, true);


--
-- TOC entry 3597 (class 0 OID 0)
-- Dependencies: 230
-- Name: priorite_id_priorite_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.priorite_id_priorite_seq', 4, true);


--
-- TOC entry 3598 (class 0 OID 0)
-- Dependencies: 232
-- Name: statut_id_statut_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.statut_id_statut_seq', 3, true);


--
-- TOC entry 3599 (class 0 OID 0)
-- Dependencies: 235
-- Name: utilisateurs_id_utilisateur_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.utilisateurs_id_utilisateur_seq', 3, true);


--
-- TOC entry 3348 (class 2606 OID 24908)
-- Name: affectation affectation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation
    ADD CONSTRAINT affectation_pkey PRIMARY KEY (id_affectation);


--
-- TOC entry 3350 (class 2606 OID 24910)
-- Name: audit audit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit
    ADD CONSTRAINT audit_pkey PRIMARY KEY (id_audit);


--
-- TOC entry 3352 (class 2606 OID 24912)
-- Name: categorie categorie_nom_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_nom_key UNIQUE (nom);


--
-- TOC entry 3354 (class 2606 OID 24914)
-- Name: categorie categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_pkey PRIMARY KEY (id_categorie);


--
-- TOC entry 3356 (class 2606 OID 24916)
-- Name: commentaire commentaire_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commentaire
    ADD CONSTRAINT commentaire_pkey PRIMARY KEY (id_commentaire);


--
-- TOC entry 3358 (class 2606 OID 24918)
-- Name: incident incident_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT incident_pkey PRIMARY KEY (id_incident);


--
-- TOC entry 3360 (class 2606 OID 24920)
-- Name: incident incident_reference_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT incident_reference_key UNIQUE (reference);


--
-- TOC entry 3366 (class 2606 OID 24922)
-- Name: intervention intervention_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention
    ADD CONSTRAINT intervention_pkey PRIMARY KEY (id_intervention);


--
-- TOC entry 3362 (class 2606 OID 24924)
-- Name: priorite priorite_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.priorite
    ADD CONSTRAINT priorite_pkey PRIMARY KEY (id_priorite);


--
-- TOC entry 3364 (class 2606 OID 24926)
-- Name: statut statut_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut
    ADD CONSTRAINT statut_pkey PRIMARY KEY (id_statut);


--
-- TOC entry 3368 (class 2606 OID 24928)
-- Name: utilisateurs utilisateurs_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateurs
    ADD CONSTRAINT utilisateurs_email_key UNIQUE (email);


--
-- TOC entry 3370 (class 2606 OID 24930)
-- Name: utilisateurs utilisateurs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateurs
    ADD CONSTRAINT utilisateurs_pkey PRIMARY KEY (id_utilisateur);


--
-- TOC entry 3381 (class 2620 OID 24982)
-- Name: incident trg_audit_incident; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_incident AFTER INSERT OR DELETE OR UPDATE ON public.incident FOR EACH ROW EXECUTE FUNCTION public.fn_audit_incident();


--
-- TOC entry 3382 (class 2620 OID 24984)
-- Name: incident trg_cloture_incident; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cloture_incident BEFORE UPDATE ON public.incident FOR EACH ROW EXECUTE FUNCTION public.fn_cloture_incident();


--
-- TOC entry 3383 (class 2620 OID 24986)
-- Name: incident trg_verif_incident; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_verif_incident BEFORE INSERT ON public.incident FOR EACH ROW EXECUTE FUNCTION public.fn_verif_incident();


--
-- TOC entry 3371 (class 2606 OID 24931)
-- Name: affectation affectation_id_incident_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation
    ADD CONSTRAINT affectation_id_incident_fkey FOREIGN KEY (id_incident) REFERENCES public.incident(id_incident);


--
-- TOC entry 3372 (class 2606 OID 24936)
-- Name: affectation affectation_id_utilisateur_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation
    ADD CONSTRAINT affectation_id_utilisateur_fkey FOREIGN KEY (id_utilisateur) REFERENCES public.utilisateurs(id_utilisateur);


--
-- TOC entry 3373 (class 2606 OID 24941)
-- Name: commentaire commentaire_id_incident_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commentaire
    ADD CONSTRAINT commentaire_id_incident_fkey FOREIGN KEY (id_incident) REFERENCES public.incident(id_incident);


--
-- TOC entry 3374 (class 2606 OID 24946)
-- Name: commentaire commentaire_id_utilisateur_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commentaire
    ADD CONSTRAINT commentaire_id_utilisateur_fkey FOREIGN KEY (id_utilisateur) REFERENCES public.utilisateurs(id_utilisateur);


--
-- TOC entry 3375 (class 2606 OID 24951)
-- Name: incident fk_incident_categorie; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT fk_incident_categorie FOREIGN KEY (id_categorie) REFERENCES public.categorie(id_categorie);


--
-- TOC entry 3376 (class 2606 OID 24956)
-- Name: incident fk_incident_priorite; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT fk_incident_priorite FOREIGN KEY (id_priorite) REFERENCES public.priorite(id_priorite);


--
-- TOC entry 3377 (class 2606 OID 24961)
-- Name: incident fk_incident_statut; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT fk_incident_statut FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);


--
-- TOC entry 3378 (class 2606 OID 24966)
-- Name: incident fk_incident_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT fk_incident_user FOREIGN KEY (id_utilisateur) REFERENCES public.utilisateurs(id_utilisateur);


--
-- TOC entry 3379 (class 2606 OID 24971)
-- Name: intervention intervention_id_incident_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention
    ADD CONSTRAINT intervention_id_incident_fkey FOREIGN KEY (id_incident) REFERENCES public.incident(id_incident);


--
-- TOC entry 3380 (class 2606 OID 24976)
-- Name: intervention intervention_id_statut_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention
    ADD CONSTRAINT intervention_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);


--
-- TOC entry 3554 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 3555 (class 0 OID 0)
-- Dependencies: 236
-- Name: FUNCTION affecter_technicien(p_technicien integer, p_incident integer, p_commentaire text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.affecter_technicien(p_technicien integer, p_incident integer, p_commentaire text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.affecter_technicien(p_technicien integer, p_incident integer, p_commentaire text) TO admin_role;


--
-- TOC entry 3556 (class 0 OID 0)
-- Dependencies: 255
-- Name: PROCEDURE ajouter_commentaire(IN p_contenu text, IN p_utilisateur integer, IN p_incident integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.ajouter_commentaire(IN p_contenu text, IN p_utilisateur integer, IN p_incident integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.ajouter_commentaire(IN p_contenu text, IN p_utilisateur integer, IN p_incident integer) TO admin_role;
GRANT ALL ON PROCEDURE public.ajouter_commentaire(IN p_contenu text, IN p_utilisateur integer, IN p_incident integer) TO utilisateur_role;


--
-- TOC entry 3557 (class 0 OID 0)
-- Dependencies: 246
-- Name: PROCEDURE ajouter_intervention(IN p_description text, IN p_duree integer, IN p_incident integer, IN p_statut integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.ajouter_intervention(IN p_description text, IN p_duree integer, IN p_incident integer, IN p_statut integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.ajouter_intervention(IN p_description text, IN p_duree integer, IN p_incident integer, IN p_statut integer) TO admin_role;


--
-- TOC entry 3558 (class 0 OID 0)
-- Dependencies: 241
-- Name: FUNCTION changer_statut_incident(p_incident integer, p_nouveau_statut integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.changer_statut_incident(p_incident integer, p_nouveau_statut integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.changer_statut_incident(p_incident integer, p_nouveau_statut integer) TO admin_role;


--
-- TOC entry 3559 (class 0 OID 0)
-- Dependencies: 253
-- Name: PROCEDURE cloturer_incident(IN p_id_incident integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.cloturer_incident(IN p_id_incident integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.cloturer_incident(IN p_id_incident integer) TO admin_role;
GRANT ALL ON PROCEDURE public.cloturer_incident(IN p_id_incident integer) TO technicien_role;


--
-- TOC entry 3560 (class 0 OID 0)
-- Dependencies: 237
-- Name: FUNCTION creer_incident(p_reference character varying, p_titre character varying, p_description text, p_utilisateur integer, p_priorite integer, p_statut integer, p_categorie integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.creer_incident(p_reference character varying, p_titre character varying, p_description text, p_utilisateur integer, p_priorite integer, p_statut integer, p_categorie integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.creer_incident(p_reference character varying, p_titre character varying, p_description text, p_utilisateur integer, p_priorite integer, p_statut integer, p_categorie integer) TO admin_role;
GRANT ALL ON FUNCTION public.creer_incident(p_reference character varying, p_titre character varying, p_description text, p_utilisateur integer, p_priorite integer, p_statut integer, p_categorie integer) TO utilisateur_role;


--
-- TOC entry 3561 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE affectation; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.affectation TO admin_role;
GRANT SELECT,INSERT ON TABLE public.affectation TO technicien_role;
GRANT SELECT ON TABLE public.affectation TO utilisateur_role;


--
-- TOC entry 3563 (class 0 OID 0)
-- Dependencies: 216
-- Name: SEQUENCE affectation_id_affectation_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.affectation_id_affectation_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE public.affectation_id_affectation_seq TO technicien_role;


--
-- TOC entry 3564 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE audit; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.audit TO admin_role;


--
-- TOC entry 3566 (class 0 OID 0)
-- Dependencies: 218
-- Name: SEQUENCE audit_id_audit_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.audit_id_audit_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE public.audit_id_audit_seq TO technicien_role;


--
-- TOC entry 3567 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE categorie; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.categorie TO admin_role;
GRANT SELECT ON TABLE public.categorie TO technicien_role;
GRANT SELECT ON TABLE public.categorie TO utilisateur_role;


--
-- TOC entry 3569 (class 0 OID 0)
-- Dependencies: 220
-- Name: SEQUENCE categorie_id_categorie_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.categorie_id_categorie_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE public.categorie_id_categorie_seq TO technicien_role;


--
-- TOC entry 3570 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE commentaire; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.commentaire TO admin_role;
GRANT SELECT,INSERT ON TABLE public.commentaire TO technicien_role;
GRANT SELECT ON TABLE public.commentaire TO utilisateur_role;


--
-- TOC entry 3572 (class 0 OID 0)
-- Dependencies: 222
-- Name: SEQUENCE commentaire_id_commentaire_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.commentaire_id_commentaire_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE public.commentaire_id_commentaire_seq TO technicien_role;


--
-- TOC entry 3573 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE incident; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.incident TO admin_role;
GRANT SELECT,UPDATE ON TABLE public.incident TO technicien_role;
GRANT SELECT,INSERT ON TABLE public.incident TO utilisateur_role;


--
-- TOC entry 3575 (class 0 OID 0)
-- Dependencies: 224
-- Name: SEQUENCE incident_id_incident_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.incident_id_incident_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE public.incident_id_incident_seq TO technicien_role;
GRANT SELECT,USAGE ON SEQUENCE public.incident_id_incident_seq TO utilisateur_role;


--
-- TOC entry 3576 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE priorite; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.priorite TO admin_role;
GRANT SELECT ON TABLE public.priorite TO technicien_role;
GRANT SELECT ON TABLE public.priorite TO utilisateur_role;


--
-- TOC entry 3577 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE statut; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.statut TO admin_role;
GRANT SELECT ON TABLE public.statut TO technicien_role;
GRANT SELECT ON TABLE public.statut TO utilisateur_role;


--
-- TOC entry 3578 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE incidents_ouverts; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.incidents_ouverts TO admin_role;
GRANT SELECT ON TABLE public.incidents_ouverts TO technicien_role;
GRANT SELECT ON TABLE public.incidents_ouverts TO utilisateur_role;


--
-- TOC entry 3579 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE intervention; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.intervention TO admin_role;
GRANT SELECT,INSERT ON TABLE public.intervention TO technicien_role;
GRANT SELECT ON TABLE public.intervention TO utilisateur_role;


--
-- TOC entry 3581 (class 0 OID 0)
-- Dependencies: 229
-- Name: SEQUENCE intervention_id_intervention_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.intervention_id_intervention_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE public.intervention_id_intervention_seq TO technicien_role;


--
-- TOC entry 3583 (class 0 OID 0)
-- Dependencies: 230
-- Name: SEQUENCE priorite_id_priorite_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.priorite_id_priorite_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE public.priorite_id_priorite_seq TO technicien_role;


--
-- TOC entry 3584 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE statistiques_incidents; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.statistiques_incidents TO admin_role;
GRANT SELECT ON TABLE public.statistiques_incidents TO technicien_role;
GRANT SELECT ON TABLE public.statistiques_incidents TO utilisateur_role;


--
-- TOC entry 3586 (class 0 OID 0)
-- Dependencies: 232
-- Name: SEQUENCE statut_id_statut_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.statut_id_statut_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE public.statut_id_statut_seq TO technicien_role;


--
-- TOC entry 3587 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE utilisateurs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.utilisateurs TO admin_role;
GRANT SELECT ON TABLE public.utilisateurs TO technicien_role;
GRANT SELECT ON TABLE public.utilisateurs TO app_login;


--
-- TOC entry 3588 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE suivi_incidents; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.suivi_incidents TO admin_role;
GRANT SELECT ON TABLE public.suivi_incidents TO technicien_role;


--
-- TOC entry 3590 (class 0 OID 0)
-- Dependencies: 235
-- Name: SEQUENCE utilisateurs_id_utilisateur_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.utilisateurs_id_utilisateur_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE public.utilisateurs_id_utilisateur_seq TO technicien_role;


-- Completed on 2026-07-04 01:57:34

--
-- PostgreSQL database dump complete
--

\unrestrict 6cePvubg8bYZMae47WN6n1AIWAS07qhvbg3fQBuw0lDy7KUcm9IkKL93i4Su0Wc

