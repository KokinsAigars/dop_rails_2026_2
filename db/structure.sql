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
-- Name: sc_01_abbreviations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sc_01_abbreviations;


--
-- Name: sc_02_bibliography; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sc_02_bibliography;


--
-- Name: sc_03_dictionary; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sc_03_dictionary;


--
-- Name: sc_04_language; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sc_04_language;


--
-- Name: sc_05_audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sc_05_audit;


--
-- Name: sc_06_ocr; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sc_06_ocr;


--
-- Name: sc_07_hash; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sc_07_hash;


--
-- Name: sc_08_analytics; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sc_08_analytics;


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: dic_lang; Type: TYPE; Schema: sc_03_dictionary; Owner: -
--

CREATE TYPE sc_03_dictionary.dic_lang AS ENUM (
    'pi',
    'en',
    'lv'
);


--
-- Name: fn_vocab_normalize(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_vocab_normalize() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.term_norm := lower(unaccent(trim(NEW.term)));
  RETURN NEW;
END;
$$;


--
-- Name: uuid_generate_v7(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.uuid_generate_v7() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
      DECLARE
        timestamp    timestamptz := clock_timestamp();
        microseconds int8        := (extract(epoch from timestamp) * 1000000);
      BEGIN
        RETURN encode(
          set_byte(
            set_byte(
              decode(lpad(to_hex(microseconds), 12, '0') || '0000000000000000', 'hex'),
              6, (get_byte(decode(lpad(to_hex(microseconds), 12, '0') || '0000000000000000', 'hex'), 6) & 15) | 112
            ),
            8, (get_byte(decode(lpad(to_hex(microseconds), 12, '0') || '0000000000000000', 'hex'), 8) & 63) | 128
          ),
          'hex'
        )::uuid;
      END;
      $$;


--
-- Name: fn_log_audit_event(); Type: FUNCTION; Schema: sc_05_audit; Owner: -
--

CREATE FUNCTION sc_05_audit.fn_log_audit_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
  v_audit_table regclass := TG_ARGV[0]::regclass; 
  v_action text := TG_OP;

  v_session_id text := current_setting('app.session_id', true);
  v_user_id text := current_setting('app.user_id', true);
  v_oauth_app_id text := current_setting('app.oauth_application_id', true);
  v_request_id text := current_setting('app.request_id', true);
  v_ip text := current_setting('app.ip', true);
  v_user_agent text := current_setting('app.user_agent', true);
  v_reason text := current_setting('app.reason', true);

  v_row_id uuid;
  v_root_id uuid;
  v_version integer;
  v_diff jsonb;
  v_snapshot jsonb;

  sql text;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_row_id := OLD.id;
    v_root_id := COALESCE(OLD.root_id, OLD.id);
    v_version := OLD.version;
    v_snapshot := to_jsonb(OLD);
    v_diff := NULL;

  ELSIF TG_OP = 'INSERT' THEN
    v_row_id := NEW.id;
    v_root_id := COALESCE(NEW.root_id, NEW.id);
    v_version := NEW.version;
    v_snapshot := to_jsonb(NEW);
    v_diff := NULL;

  ELSE -- UPDATE
    v_row_id := NEW.id;
    v_root_id := COALESCE(NEW.root_id, NEW.id);
    v_version := NEW.version;
    v_snapshot := to_jsonb(NEW);
    v_diff := jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW));
  END IF;

  sql := format($f$
    INSERT INTO %s
    (
      action, table_name, row_id,
      root_id, version,
      session_id, user_id, oauth_application_id, request_id, ip, user_agent,
      reason, diff, snapshot
    )
    VALUES
    (
      lower($1), $2, $3,
      $4, $5,
      $6,
      $7::uuid,
      $8::uuid,
      $9,
      $10::inet,
      $11,
      $12,
      $13,
      $14
    )
  $f$, v_audit_table);

  EXECUTE sql
  USING
    v_action,
    TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
    v_row_id,
    v_root_id,
    v_version,
    NULLIF(v_session_id, ''),
    NULLIF(v_user_id, ''),
    NULLIF(v_oauth_app_id, ''),
    NULLIF(v_request_id, ''),
    NULLIF(v_ip, ''),
    NULLIF(v_user_agent, ''),
    NULLIF(v_reason, ''),
    v_diff,
    v_snapshot;

  RETURN NULL; -- IMPORTANT: correct for AFTER triggers
END;
$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: db_release; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.db_release (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    number character varying NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    released_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    git_sha text,
    notes text,
    CONSTRAINT chk_db_release_status CHECK ((status = ANY (ARRAY['active'::text, 'deprecated'::text, 'rolled_back'::text, 'hotfix'::text])))
);


--
-- Name: global_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.global_configs (
    id bigint NOT NULL,
    key character varying,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: global_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.global_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: global_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.global_configs_id_seq OWNED BY public.global_configs.id;


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_grants (
    id bigint NOT NULL,
    resource_owner_id bigint NOT NULL,
    application_id bigint NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone
);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_grants_id_seq OWNED BY public.oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    id bigint NOT NULL,
    resource_owner_id bigint,
    application_id bigint NOT NULL,
    token character varying NOT NULL,
    refresh_token character varying,
    expires_in integer,
    scopes character varying,
    created_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    previous_refresh_token character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_tokens_id_seq OWNED BY public.oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_applications (
    id bigint NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    confidential boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_applications_id_seq OWNED BY public.oauth_applications.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name character varying NOT NULL,
    label character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    ip_address inet,
    user_agent text,
    last_seen_at timestamp without time zone,
    expires_at timestamp without time zone,
    revoked_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email_address public.citext NOT NULL,
    username public.citext,
    password_digest character varying NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    locale character varying,
    timezone character varying,
    first_name character varying,
    last_name character varying,
    display_name character varying,
    bio text,
    verified boolean,
    verified_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    last_sign_in_ip inet,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: abbr_books_periodicals; Type: TABLE; Schema: sc_01_abbreviations; Owner: -
--

CREATE TABLE sc_01_abbreviations.abbr_books_periodicals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    abbr_letter character varying(1),
    abbr_name text NOT NULL,
    abbr_id_est text,
    abbr_lv text,
    abbr_number text,
    abbr_ref_id uuid,
    abbr_note text,
    abbr_source text,
    abbr_source_text text,
    abbr_citation text,
    abbr_citation_transl text,
    abbr_citation_2 text,
    abbr_citation_method text,
    abbr_citation_method_2 text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: abbr_docs; Type: TABLE; Schema: sc_01_abbreviations; Owner: -
--

CREATE TABLE sc_01_abbreviations.abbr_docs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    doc_title text,
    doc_license text,
    doc_reference jsonb,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: abbr_general_terms; Type: TABLE; Schema: sc_01_abbreviations; Owner: -
--

CREATE TABLE sc_01_abbreviations.abbr_general_terms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    abbr_letter character varying(1),
    abbr_name text NOT NULL,
    abbr_id_est text,
    abbr_lv text,
    abbr_ref_id uuid,
    abbr_note text,
    abbr_source text,
    abbr_source_text text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: abbr_grammatical_terms; Type: TABLE; Schema: sc_01_abbreviations; Owner: -
--

CREATE TABLE sc_01_abbreviations.abbr_grammatical_terms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    abbr_letter character varying(1),
    abbr_name text NOT NULL,
    abbr_id_est text,
    abbr_lv text,
    abbr_ref_id uuid,
    abbr_source_text text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: abbr_publication_sources; Type: TABLE; Schema: sc_01_abbreviations; Owner: -
--

CREATE TABLE sc_01_abbreviations.abbr_publication_sources (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    abbr_name text NOT NULL,
    abbr_id_est text,
    abbr_note text,
    abbr_source_text text,
    abbr_citation text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: abbr_typographicals; Type: TABLE; Schema: sc_01_abbreviations; Owner: -
--

CREATE TABLE sc_01_abbreviations.abbr_typographicals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    abbr_name text NOT NULL,
    abbr_id_est text,
    abbr_ref_id uuid,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: ref_bibliography; Type: TABLE; Schema: sc_02_bibliography; Owner: -
--

CREATE TABLE sc_02_bibliography.ref_bibliography (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ref_letter text,
    ref_abbrev text,
    ref_title text,
    ref_note text,
    ref_citation text,
    ref_footnote text,
    ref_publisher text,
    ref_place text,
    ref_volume text,
    ref_part text,
    ref_type text,
    ref_author text,
    ref_url text,
    ref_ref1 text,
    ref_ref2 text,
    ref_title_lv text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: ref_doc; Type: TABLE; Schema: sc_02_bibliography; Owner: -
--

CREATE TABLE sc_02_bibliography.ref_doc (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    doc_title text,
    doc_license text,
    doc_reference jsonb,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: ref_internet_sources; Type: TABLE; Schema: sc_02_bibliography; Owner: -
--

CREATE TABLE sc_02_bibliography.ref_internet_sources (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ref_title text,
    ref_url text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: ref_texts; Type: TABLE; Schema: sc_02_bibliography; Owner: -
--

CREATE TABLE sc_02_bibliography.ref_texts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ref_texts_no text,
    ref_texts_title text,
    ref_texts_lang text,
    ref_no text,
    ref_abbrev text,
    ref_title text,
    ref_note text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: dic_doc; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_doc (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    doc_title text,
    doc_license text,
    doc_reference jsonb DEFAULT '{}'::jsonb,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb DEFAULT '{}'::jsonb
);


--
-- Name: dic_eg; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_eg (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_index_id uuid NOT NULL,
    fk_entry_id uuid NOT NULL,
    eg_no integer,
    eg_note text,
    eg_name text,
    eg_etymology text,
    eg_compare text,
    eg_compare_sanskrit text,
    eg_opposite text,
    eg_xref text,
    bibliography_uuid uuid,
    citation_ref_src text,
    citation_abbrev text,
    citation_vol text,
    citation_part text,
    citation_p text,
    citation_pp text,
    citation_para text,
    citation_line text,
    citation_verse text,
    citation_char text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb DEFAULT '{}'::jsonb
);


--
-- Name: dic_entry; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_entry (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_index_id uuid NOT NULL,
    lang sc_03_dictionary.dic_lang NOT NULL,
    dictionary integer DEFAULT 1 NOT NULL,
    entry_version integer DEFAULT 1 NOT NULL,
    entry_no integer NOT NULL,
    letter character varying(2),
    name text,
    name_orig text,
    dic_name text,
    dic_name_orig text,
    dic_eng_tr text,
    gender text,
    grammar text,
    etymology text,
    compare text,
    compare_sanskrit text,
    sanskrit text,
    opposite text,
    vedic text,
    note text,
    xref text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb DEFAULT '{}'::jsonb
);


--
-- Name: dic_index; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_index (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    dictionary integer DEFAULT 1 NOT NULL,
    entry_no integer,
    homograph text,
    homograph_no integer,
    homograph_uuid uuid,
    source_file text NOT NULL,
    source_order integer NOT NULL,
    xml_index_id text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb DEFAULT '{}'::jsonb
);


--
-- Name: dic_note; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_note (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_index_id uuid NOT NULL,
    fk_entry_id uuid NOT NULL,
    note_no integer,
    note_note text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb DEFAULT '{}'::jsonb
);


--
-- Name: dic_quote; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_quote (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_index_id uuid NOT NULL,
    fk_entry_id uuid NOT NULL,
    quote_no integer,
    quote_note text,
    quote_name text,
    quote_etymology text,
    quote_compare text,
    quote_compare_sanskrit text,
    quote_opposite text,
    quote_xref text,
    bibliography_uuid uuid,
    citation_ref_src text,
    citation_abbrev text,
    citation_vol text,
    citation_part text,
    citation_p text,
    citation_pp text,
    citation_para text,
    citation_line text,
    citation_verse text,
    citation_char text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb DEFAULT '{}'::jsonb
);


--
-- Name: dic_ref; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_ref (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_index_id uuid NOT NULL,
    fk_entry_id uuid NOT NULL,
    ref_no integer,
    ref_note text,
    ref_name text,
    ref_etymology text,
    ref_compare text,
    ref_compare_sanskrit text,
    ref_opposite text,
    ref_xref text,
    bibliography_uuid uuid,
    citation_ref_src text,
    citation_abbrev text,
    citation_vol text,
    citation_part text,
    citation_p text,
    citation_pp text,
    citation_para text,
    citation_line text,
    citation_verse text,
    citation_char text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb DEFAULT '{}'::jsonb
);


--
-- Name: dic_scan; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_scan (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_index_id uuid NOT NULL,
    scan_version integer NOT NULL,
    scan_filename text,
    scan_note text,
    scan_text text,
    scan_text_raw text,
    scan_meta jsonb,
    scan_status text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    root_id uuid NOT NULL,
    version integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    superseded_at timestamp(6) without time zone,
    superseded_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb DEFAULT '{}'::jsonb
);


--
-- Name: dic_search_indexes; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_search_indexes (
    term character varying NOT NULL,
    term_norm character varying NOT NULL,
    lang character varying(10),
    fk_index_id uuid NOT NULL
);


--
-- Name: dic_vocab; Type: TABLE; Schema: sc_03_dictionary; Owner: -
--

CREATE TABLE sc_03_dictionary.dic_vocab (
    lang sc_03_dictionary.dic_lang NOT NULL,
    term text NOT NULL,
    term_norm text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: lang_doc; Type: TABLE; Schema: sc_04_language; Owner: -
--

CREATE TABLE sc_04_language.lang_doc (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    doc_title text,
    doc_license text,
    doc_reference jsonb,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: lang_language; Type: TABLE; Schema: sc_04_language; Owner: -
--

CREATE TABLE sc_04_language.lang_language (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lang_title text,
    lang_language text,
    lang_eng_equivalent text,
    lang_abbr text,
    lang_abbr2 text,
    lang_url text,
    lang_alphabet text,
    lang_vowels text,
    lang_consonants text,
    lang_niggahita text,
    lang_code text,
    lang_code2 text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: abbr_audit_events; Type: TABLE; Schema: sc_05_audit; Owner: -
--

CREATE TABLE sc_05_audit.abbr_audit_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    action text NOT NULL,
    table_name text NOT NULL,
    row_id uuid NOT NULL,
    root_id uuid,
    version integer,
    session_id text,
    user_id uuid,
    oauth_application_id uuid,
    request_id text,
    ip inet,
    user_agent text,
    reason text,
    diff jsonb,
    snapshot jsonb,
    CONSTRAINT chk_abbr_audit_action CHECK ((lower(action) = ANY (ARRAY['insert'::text, 'update'::text, 'delete'::text])))
);


--
-- Name: dic_entry_audit_events; Type: TABLE; Schema: sc_05_audit; Owner: -
--

CREATE TABLE sc_05_audit.dic_entry_audit_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    action text NOT NULL,
    table_name text NOT NULL,
    row_id uuid NOT NULL,
    root_id uuid,
    version integer,
    session_id text,
    user_id uuid,
    oauth_application_id uuid,
    request_id text,
    ip inet,
    user_agent text,
    reason text,
    diff jsonb,
    snapshot jsonb,
    CONSTRAINT chk_dic_entry_audit_action CHECK ((lower(action) = ANY (ARRAY['insert'::text, 'update'::text, 'delete'::text])))
);


--
-- Name: ref_audit_events; Type: TABLE; Schema: sc_05_audit; Owner: -
--

CREATE TABLE sc_05_audit.ref_audit_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    action text NOT NULL,
    table_name text NOT NULL,
    row_id uuid NOT NULL,
    root_id uuid,
    version integer,
    session_id text,
    user_id uuid,
    oauth_application_id uuid,
    request_id text,
    ip inet,
    user_agent text,
    reason text,
    diff jsonb,
    snapshot jsonb,
    CONSTRAINT chk_ref_audit_action CHECK ((lower(action) = ANY (ARRAY['insert'::text, 'update'::text, 'delete'::text])))
);


--
-- Name: ocr_link; Type: TABLE; Schema: sc_06_ocr; Owner: -
--

CREATE TABLE sc_06_ocr.ocr_link (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_page_result_id uuid NOT NULL,
    fk_index_id uuid,
    fk_entry_id uuid,
    link_kind text NOT NULL,
    link_conf numeric(5,2),
    note text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: ocr_page; Type: TABLE; Schema: sc_06_ocr; Owner: -
--

CREATE TABLE sc_06_ocr.ocr_page (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_source_doc_id uuid NOT NULL,
    page_no integer NOT NULL,
    page_sha256 bytea,
    image_width integer,
    image_height integer,
    dpi integer,
    page_meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb,
    CONSTRAINT chk_ocr_page_page_no_positive CHECK ((page_no > 0))
);


--
-- Name: ocr_page_result; Type: TABLE; Schema: sc_06_ocr; Owner: -
--

CREATE TABLE sc_06_ocr.ocr_page_result (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_run_id uuid NOT NULL,
    fk_page_id uuid NOT NULL,
    raw_text text,
    raw_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    mean_conf numeric(5,2),
    warnings text[] DEFAULT '{}'::text[] NOT NULL,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: ocr_review; Type: TABLE; Schema: sc_06_ocr; Owner: -
--

CREATE TABLE sc_06_ocr.ocr_review (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_page_result_id uuid NOT NULL,
    review_status text DEFAULT 'pending'::text NOT NULL,
    review_note text,
    approved_text text,
    reviewed_at timestamp without time zone,
    reviewed_by jsonb DEFAULT '{}'::jsonb NOT NULL,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: ocr_run; Type: TABLE; Schema: sc_06_ocr; Owner: -
--

CREATE TABLE sc_06_ocr.ocr_run (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    engine text NOT NULL,
    engine_version text,
    lang_hint text[] DEFAULT '{}'::text[] NOT NULL,
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    started_at timestamp without time zone DEFAULT now() NOT NULL,
    finished_at timestamp without time zone,
    status text DEFAULT 'ok'::text NOT NULL,
    log text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: ocr_source_doc; Type: TABLE; Schema: sc_06_ocr; Owner: -
--

CREATE TABLE sc_06_ocr.ocr_source_doc (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_kind text,
    source_uri text,
    source_sha256 bytea,
    doc_meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb
);


--
-- Name: ocr_token; Type: TABLE; Schema: sc_06_ocr; Owner: -
--

CREATE TABLE sc_06_ocr.ocr_token (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fk_page_result_id uuid NOT NULL,
    token_no integer NOT NULL,
    text text NOT NULL,
    text_norm text NOT NULL,
    bbox jsonb DEFAULT '{}'::jsonb NOT NULL,
    confidence numeric(5,2),
    kind text,
    revision boolean DEFAULT false NOT NULL,
    revision_comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by jsonb,
    CONSTRAINT chk_ocr_token_token_no_nonneg CHECK ((token_no >= 0))
);


--
-- Name: executed_sql_scripts; Type: TABLE; Schema: sc_07_hash; Owner: -
--

CREATE TABLE sc_07_hash.executed_sql_scripts (
    id bigint NOT NULL,
    file_hash text NOT NULL,
    file_path text,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: executed_sql_scripts_id_seq; Type: SEQUENCE; Schema: sc_07_hash; Owner: -
--

CREATE SEQUENCE sc_07_hash.executed_sql_scripts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: executed_sql_scripts_id_seq; Type: SEQUENCE OWNED BY; Schema: sc_07_hash; Owner: -
--

ALTER SEQUENCE sc_07_hash.executed_sql_scripts_id_seq OWNED BY sc_07_hash.executed_sql_scripts.id;


--
-- Name: temporary_hash; Type: TABLE; Schema: sc_07_hash; Owner: -
--

CREATE TABLE sc_07_hash.temporary_hash (
    id bigint NOT NULL,
    dic_index_hash bytea NOT NULL,
    fk_index_id uuid NOT NULL
);


--
-- Name: temporary_hash_id_seq; Type: SEQUENCE; Schema: sc_07_hash; Owner: -
--

CREATE SEQUENCE sc_07_hash.temporary_hash_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: temporary_hash_id_seq; Type: SEQUENCE OWNED BY; Schema: sc_07_hash; Owner: -
--

ALTER SEQUENCE sc_07_hash.temporary_hash_id_seq OWNED BY sc_07_hash.temporary_hash.id;


--
-- Name: bot_attempts; Type: TABLE; Schema: sc_08_analytics; Owner: -
--

CREATE TABLE sc_08_analytics.bot_attempts (
    id bigint NOT NULL,
    ip inet,
    note text,
    user_agent text,
    event_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: bot_attempts_id_seq; Type: SEQUENCE; Schema: sc_08_analytics; Owner: -
--

CREATE SEQUENCE sc_08_analytics.bot_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: sc_08_analytics; Owner: -
--

ALTER SEQUENCE sc_08_analytics.bot_attempts_id_seq OWNED BY sc_08_analytics.bot_attempts.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: global_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.global_configs ALTER COLUMN id SET DEFAULT nextval('public.global_configs_id_seq'::regclass);


--
-- Name: oauth_access_grants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_grants_id_seq'::regclass);


--
-- Name: oauth_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_tokens_id_seq'::regclass);


--
-- Name: oauth_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications ALTER COLUMN id SET DEFAULT nextval('public.oauth_applications_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: executed_sql_scripts id; Type: DEFAULT; Schema: sc_07_hash; Owner: -
--

ALTER TABLE ONLY sc_07_hash.executed_sql_scripts ALTER COLUMN id SET DEFAULT nextval('sc_07_hash.executed_sql_scripts_id_seq'::regclass);


--
-- Name: temporary_hash id; Type: DEFAULT; Schema: sc_07_hash; Owner: -
--

ALTER TABLE ONLY sc_07_hash.temporary_hash ALTER COLUMN id SET DEFAULT nextval('sc_07_hash.temporary_hash_id_seq'::regclass);


--
-- Name: bot_attempts id; Type: DEFAULT; Schema: sc_08_analytics; Owner: -
--

ALTER TABLE ONLY sc_08_analytics.bot_attempts ALTER COLUMN id SET DEFAULT nextval('sc_08_analytics.bot_attempts_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: db_release db_release_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_release
    ADD CONSTRAINT db_release_pkey PRIMARY KEY (id);


--
-- Name: global_configs global_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.global_configs
    ADD CONSTRAINT global_configs_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: abbr_books_periodicals abbr_books_periodicals_pkey; Type: CONSTRAINT; Schema: sc_01_abbreviations; Owner: -
--

ALTER TABLE ONLY sc_01_abbreviations.abbr_books_periodicals
    ADD CONSTRAINT abbr_books_periodicals_pkey PRIMARY KEY (id);


--
-- Name: abbr_docs abbr_docs_pkey; Type: CONSTRAINT; Schema: sc_01_abbreviations; Owner: -
--

ALTER TABLE ONLY sc_01_abbreviations.abbr_docs
    ADD CONSTRAINT abbr_docs_pkey PRIMARY KEY (id);


--
-- Name: abbr_general_terms abbr_general_terms_pkey; Type: CONSTRAINT; Schema: sc_01_abbreviations; Owner: -
--

ALTER TABLE ONLY sc_01_abbreviations.abbr_general_terms
    ADD CONSTRAINT abbr_general_terms_pkey PRIMARY KEY (id);


--
-- Name: abbr_grammatical_terms abbr_grammatical_terms_pkey; Type: CONSTRAINT; Schema: sc_01_abbreviations; Owner: -
--

ALTER TABLE ONLY sc_01_abbreviations.abbr_grammatical_terms
    ADD CONSTRAINT abbr_grammatical_terms_pkey PRIMARY KEY (id);


--
-- Name: abbr_publication_sources abbr_publication_sources_pkey; Type: CONSTRAINT; Schema: sc_01_abbreviations; Owner: -
--

ALTER TABLE ONLY sc_01_abbreviations.abbr_publication_sources
    ADD CONSTRAINT abbr_publication_sources_pkey PRIMARY KEY (id);


--
-- Name: abbr_typographicals abbr_typographicals_pkey; Type: CONSTRAINT; Schema: sc_01_abbreviations; Owner: -
--

ALTER TABLE ONLY sc_01_abbreviations.abbr_typographicals
    ADD CONSTRAINT abbr_typographicals_pkey PRIMARY KEY (id);


--
-- Name: ref_bibliography ref_bibliography_pkey; Type: CONSTRAINT; Schema: sc_02_bibliography; Owner: -
--

ALTER TABLE ONLY sc_02_bibliography.ref_bibliography
    ADD CONSTRAINT ref_bibliography_pkey PRIMARY KEY (id);


--
-- Name: ref_doc ref_doc_pkey; Type: CONSTRAINT; Schema: sc_02_bibliography; Owner: -
--

ALTER TABLE ONLY sc_02_bibliography.ref_doc
    ADD CONSTRAINT ref_doc_pkey PRIMARY KEY (id);


--
-- Name: ref_internet_sources ref_internet_sources_pkey; Type: CONSTRAINT; Schema: sc_02_bibliography; Owner: -
--

ALTER TABLE ONLY sc_02_bibliography.ref_internet_sources
    ADD CONSTRAINT ref_internet_sources_pkey PRIMARY KEY (id);


--
-- Name: ref_texts ref_texts_pkey; Type: CONSTRAINT; Schema: sc_02_bibliography; Owner: -
--

ALTER TABLE ONLY sc_02_bibliography.ref_texts
    ADD CONSTRAINT ref_texts_pkey PRIMARY KEY (id);


--
-- Name: dic_doc dic_doc_pkey; Type: CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_doc
    ADD CONSTRAINT dic_doc_pkey PRIMARY KEY (id);


--
-- Name: dic_eg dic_eg_pkey; Type: CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_eg
    ADD CONSTRAINT dic_eg_pkey PRIMARY KEY (id);


--
-- Name: dic_entry dic_entry_pkey; Type: CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_entry
    ADD CONSTRAINT dic_entry_pkey PRIMARY KEY (id);


--
-- Name: dic_index dic_index_pkey; Type: CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_index
    ADD CONSTRAINT dic_index_pkey PRIMARY KEY (id);


--
-- Name: dic_note dic_note_pkey; Type: CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_note
    ADD CONSTRAINT dic_note_pkey PRIMARY KEY (id);


--
-- Name: dic_quote dic_quote_pkey; Type: CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_quote
    ADD CONSTRAINT dic_quote_pkey PRIMARY KEY (id);


--
-- Name: dic_ref dic_ref_pkey; Type: CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_ref
    ADD CONSTRAINT dic_ref_pkey PRIMARY KEY (id);


--
-- Name: dic_scan dic_scan_pkey; Type: CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_scan
    ADD CONSTRAINT dic_scan_pkey PRIMARY KEY (id);


--
-- Name: dic_vocab dic_vocab_pkey; Type: CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_vocab
    ADD CONSTRAINT dic_vocab_pkey PRIMARY KEY (lang, term);


--
-- Name: lang_doc lang_doc_pkey; Type: CONSTRAINT; Schema: sc_04_language; Owner: -
--

ALTER TABLE ONLY sc_04_language.lang_doc
    ADD CONSTRAINT lang_doc_pkey PRIMARY KEY (id);


--
-- Name: lang_language lang_language_pkey; Type: CONSTRAINT; Schema: sc_04_language; Owner: -
--

ALTER TABLE ONLY sc_04_language.lang_language
    ADD CONSTRAINT lang_language_pkey PRIMARY KEY (id);


--
-- Name: abbr_audit_events abbr_audit_events_pkey; Type: CONSTRAINT; Schema: sc_05_audit; Owner: -
--

ALTER TABLE ONLY sc_05_audit.abbr_audit_events
    ADD CONSTRAINT abbr_audit_events_pkey PRIMARY KEY (id);


--
-- Name: dic_entry_audit_events dic_entry_audit_events_pkey; Type: CONSTRAINT; Schema: sc_05_audit; Owner: -
--

ALTER TABLE ONLY sc_05_audit.dic_entry_audit_events
    ADD CONSTRAINT dic_entry_audit_events_pkey PRIMARY KEY (id);


--
-- Name: ref_audit_events ref_audit_events_pkey; Type: CONSTRAINT; Schema: sc_05_audit; Owner: -
--

ALTER TABLE ONLY sc_05_audit.ref_audit_events
    ADD CONSTRAINT ref_audit_events_pkey PRIMARY KEY (id);


--
-- Name: ocr_link ocr_link_pkey; Type: CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_link
    ADD CONSTRAINT ocr_link_pkey PRIMARY KEY (id);


--
-- Name: ocr_page ocr_page_pkey; Type: CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_page
    ADD CONSTRAINT ocr_page_pkey PRIMARY KEY (id);


--
-- Name: ocr_page_result ocr_page_result_pkey; Type: CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_page_result
    ADD CONSTRAINT ocr_page_result_pkey PRIMARY KEY (id);


--
-- Name: ocr_review ocr_review_pkey; Type: CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_review
    ADD CONSTRAINT ocr_review_pkey PRIMARY KEY (id);


--
-- Name: ocr_run ocr_run_pkey; Type: CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_run
    ADD CONSTRAINT ocr_run_pkey PRIMARY KEY (id);


--
-- Name: ocr_source_doc ocr_source_doc_pkey; Type: CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_source_doc
    ADD CONSTRAINT ocr_source_doc_pkey PRIMARY KEY (id);


--
-- Name: ocr_token ocr_token_pkey; Type: CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_token
    ADD CONSTRAINT ocr_token_pkey PRIMARY KEY (id);


--
-- Name: executed_sql_scripts executed_sql_scripts_pkey; Type: CONSTRAINT; Schema: sc_07_hash; Owner: -
--

ALTER TABLE ONLY sc_07_hash.executed_sql_scripts
    ADD CONSTRAINT executed_sql_scripts_pkey PRIMARY KEY (id);


--
-- Name: temporary_hash temporary_hash_pkey; Type: CONSTRAINT; Schema: sc_07_hash; Owner: -
--

ALTER TABLE ONLY sc_07_hash.temporary_hash
    ADD CONSTRAINT temporary_hash_pkey PRIMARY KEY (id);


--
-- Name: bot_attempts bot_attempts_pkey; Type: CONSTRAINT; Schema: sc_08_analytics; Owner: -
--

ALTER TABLE ONLY sc_08_analytics.bot_attempts
    ADD CONSTRAINT bot_attempts_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_db_release_on_is_current; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_db_release_on_is_current ON public.db_release USING btree (is_current) WHERE is_current;


--
-- Name: index_db_release_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_db_release_on_number ON public.db_release USING btree (number);


--
-- Name: index_db_release_on_released_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_db_release_on_released_at ON public.db_release USING btree (released_at);


--
-- Name: index_global_configs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_global_configs_on_key ON public.global_configs USING btree (key);


--
-- Name: index_oauth_access_grants_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_application_id ON public.oauth_access_grants USING btree (application_id);


--
-- Name: index_oauth_access_grants_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_resource_owner_id ON public.oauth_access_grants USING btree (resource_owner_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_application_id ON public.oauth_access_tokens USING btree (application_id);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON public.oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);


--
-- Name: index_sessions_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_expires_at ON public.sessions USING btree (expires_at);


--
-- Name: index_sessions_on_last_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_last_seen_at ON public.sessions USING btree (last_seen_at);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_sessions_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id_and_created_at ON public.sessions USING btree (user_id, created_at);


--
-- Name: index_user_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_role_id ON public.user_roles USING btree (role_id);


--
-- Name: index_user_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_user_id ON public.user_roles USING btree (user_id);


--
-- Name: index_user_roles_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_roles_on_user_id_and_role_id ON public.user_roles USING btree (user_id, role_id);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_settings; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_settings ON public.users USING gin (settings);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username) WHERE (username IS NOT NULL);


--
-- Name: uq_roles_lower_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_roles_lower_name ON public.roles USING btree (lower((name)::text));


--
-- Name: idx_abbr_books_periodicals_abbr_letter; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_books_periodicals_abbr_letter ON sc_01_abbreviations.abbr_books_periodicals USING btree (abbr_letter);


--
-- Name: idx_abbr_books_periodicals_abbr_name; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_books_periodicals_abbr_name ON sc_01_abbreviations.abbr_books_periodicals USING btree (abbr_name);


--
-- Name: idx_abbr_books_periodicals_superseded_at; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_books_periodicals_superseded_at ON sc_01_abbreviations.abbr_books_periodicals USING btree (superseded_at);


--
-- Name: idx_abbr_docs_doc_title; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_docs_doc_title ON sc_01_abbreviations.abbr_docs USING btree (doc_title);


--
-- Name: idx_abbr_general_terms_letter_name; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_general_terms_letter_name ON sc_01_abbreviations.abbr_general_terms USING btree (abbr_letter, abbr_name);


--
-- Name: idx_abbr_general_terms_name; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_general_terms_name ON sc_01_abbreviations.abbr_general_terms USING btree (abbr_name);


--
-- Name: idx_abbr_gram_terms_letter_name; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_gram_terms_letter_name ON sc_01_abbreviations.abbr_grammatical_terms USING btree (abbr_letter, abbr_name);


--
-- Name: idx_abbr_gram_terms_name; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_gram_terms_name ON sc_01_abbreviations.abbr_grammatical_terms USING btree (abbr_name);


--
-- Name: idx_abbr_pub_sources_name; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_pub_sources_name ON sc_01_abbreviations.abbr_publication_sources USING btree (abbr_name);


--
-- Name: idx_abbr_typographicals_name; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE INDEX idx_abbr_typographicals_name ON sc_01_abbreviations.abbr_typographicals USING btree (abbr_name);


--
-- Name: uq_abbr_books_periodicals_root_current; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_books_periodicals_root_current ON sc_01_abbreviations.abbr_books_periodicals USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_abbr_books_periodicals_root_version; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_books_periodicals_root_version ON sc_01_abbreviations.abbr_books_periodicals USING btree (root_id, version);


--
-- Name: uq_abbr_docs_root_current; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_docs_root_current ON sc_01_abbreviations.abbr_docs USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_abbr_docs_root_version; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_docs_root_version ON sc_01_abbreviations.abbr_docs USING btree (root_id, version);


--
-- Name: uq_abbr_general_terms_root_current; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_general_terms_root_current ON sc_01_abbreviations.abbr_general_terms USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_abbr_general_terms_root_version; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_general_terms_root_version ON sc_01_abbreviations.abbr_general_terms USING btree (root_id, version);


--
-- Name: uq_abbr_gram_terms_root_current; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_gram_terms_root_current ON sc_01_abbreviations.abbr_grammatical_terms USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_abbr_gram_terms_root_version; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_gram_terms_root_version ON sc_01_abbreviations.abbr_grammatical_terms USING btree (root_id, version);


--
-- Name: uq_abbr_pub_sources_root_current; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_pub_sources_root_current ON sc_01_abbreviations.abbr_publication_sources USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_abbr_pub_sources_root_version; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_pub_sources_root_version ON sc_01_abbreviations.abbr_publication_sources USING btree (root_id, version);


--
-- Name: uq_abbr_typographicals_root_current; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_typographicals_root_current ON sc_01_abbreviations.abbr_typographicals USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_abbr_typographicals_root_version; Type: INDEX; Schema: sc_01_abbreviations; Owner: -
--

CREATE UNIQUE INDEX uq_abbr_typographicals_root_version ON sc_01_abbreviations.abbr_typographicals USING btree (root_id, version);


--
-- Name: idx_ref_bibliography_ref_abbrev; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE INDEX idx_ref_bibliography_ref_abbrev ON sc_02_bibliography.ref_bibliography USING btree (ref_abbrev);


--
-- Name: idx_ref_bibliography_ref_letter; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE INDEX idx_ref_bibliography_ref_letter ON sc_02_bibliography.ref_bibliography USING btree (ref_letter);


--
-- Name: idx_ref_bibliography_ref_type; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE INDEX idx_ref_bibliography_ref_type ON sc_02_bibliography.ref_bibliography USING btree (ref_type);


--
-- Name: idx_ref_doc_doc_title; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE INDEX idx_ref_doc_doc_title ON sc_02_bibliography.ref_doc USING btree (doc_title);


--
-- Name: idx_ref_internet_sources_ref_url; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE INDEX idx_ref_internet_sources_ref_url ON sc_02_bibliography.ref_internet_sources USING btree (ref_url);


--
-- Name: idx_ref_texts_ref_abbrev; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE INDEX idx_ref_texts_ref_abbrev ON sc_02_bibliography.ref_texts USING btree (ref_abbrev);


--
-- Name: idx_ref_texts_ref_texts_no; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE INDEX idx_ref_texts_ref_texts_no ON sc_02_bibliography.ref_texts USING btree (ref_texts_no);


--
-- Name: uq_ref_bibliography_root_current; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE UNIQUE INDEX uq_ref_bibliography_root_current ON sc_02_bibliography.ref_bibliography USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_ref_bibliography_root_version; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE UNIQUE INDEX uq_ref_bibliography_root_version ON sc_02_bibliography.ref_bibliography USING btree (root_id, version);


--
-- Name: uq_ref_doc_root_current; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE UNIQUE INDEX uq_ref_doc_root_current ON sc_02_bibliography.ref_doc USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_ref_doc_root_version; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE UNIQUE INDEX uq_ref_doc_root_version ON sc_02_bibliography.ref_doc USING btree (root_id, version);


--
-- Name: uq_ref_internet_sources_root_current; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE UNIQUE INDEX uq_ref_internet_sources_root_current ON sc_02_bibliography.ref_internet_sources USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_ref_internet_sources_root_version; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE UNIQUE INDEX uq_ref_internet_sources_root_version ON sc_02_bibliography.ref_internet_sources USING btree (root_id, version);


--
-- Name: uq_ref_texts_root_current; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE UNIQUE INDEX uq_ref_texts_root_current ON sc_02_bibliography.ref_texts USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_ref_texts_root_version; Type: INDEX; Schema: sc_02_bibliography; Owner: -
--

CREATE UNIQUE INDEX uq_ref_texts_root_version ON sc_02_bibliography.ref_texts USING btree (root_id, version);


--
-- Name: idx_dic_search_fk_index; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX idx_dic_search_fk_index ON sc_03_dictionary.dic_search_indexes USING btree (fk_index_id);


--
-- Name: idx_dic_search_term_norm_trgm; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX idx_dic_search_term_norm_trgm ON sc_03_dictionary.dic_search_indexes USING gin (term_norm public.gin_trgm_ops);


--
-- Name: idx_dic_search_term_trgm; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX idx_dic_search_term_trgm ON sc_03_dictionary.dic_search_indexes USING gin (term public.gin_trgm_ops);


--
-- Name: idx_dic_vocab_term_norm_trgm; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX idx_dic_vocab_term_norm_trgm ON sc_03_dictionary.dic_vocab USING gin (term_norm public.gin_trgm_ops);


--
-- Name: idx_dic_vocab_term_trgm; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX idx_dic_vocab_term_trgm ON sc_03_dictionary.dic_vocab USING gin (term public.gin_trgm_ops);


--
-- Name: idx_unique_search_entry; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX idx_unique_search_entry ON sc_03_dictionary.dic_search_indexes USING btree (term, lang, fk_index_id);


--
-- Name: ix_dic_eg_fk_entry; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_eg_fk_entry ON sc_03_dictionary.dic_eg USING btree (fk_entry_id);


--
-- Name: ix_dic_eg_index_entry; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_eg_index_entry ON sc_03_dictionary.dic_eg USING btree (fk_index_id, fk_entry_id);


--
-- Name: ix_dic_entry_fk_index; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_entry_fk_index ON sc_03_dictionary.dic_entry USING btree (fk_index_id);


--
-- Name: ix_dic_entry_lang_name; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_entry_lang_name ON sc_03_dictionary.dic_entry USING btree (lang, name);


--
-- Name: ix_dic_entry_revision; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_entry_revision ON sc_03_dictionary.dic_entry USING btree (revision);


--
-- Name: ix_dic_index_homograph_uuid; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_index_homograph_uuid ON sc_03_dictionary.dic_index USING btree (homograph_uuid);


--
-- Name: ix_dic_index_source_file; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_index_source_file ON sc_03_dictionary.dic_index USING btree (source_file);


--
-- Name: ix_dic_note_fk_entry; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_note_fk_entry ON sc_03_dictionary.dic_note USING btree (fk_entry_id);


--
-- Name: ix_dic_note_fk_index; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_note_fk_index ON sc_03_dictionary.dic_note USING btree (fk_index_id);


--
-- Name: ix_dic_note_index_entry; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_note_index_entry ON sc_03_dictionary.dic_note USING btree (fk_index_id, fk_entry_id);


--
-- Name: ix_dic_quote_fk_entry; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_quote_fk_entry ON sc_03_dictionary.dic_quote USING btree (fk_entry_id);


--
-- Name: ix_dic_quote_fk_index; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_quote_fk_index ON sc_03_dictionary.dic_quote USING btree (fk_index_id);


--
-- Name: ix_dic_quote_index_entry; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_quote_index_entry ON sc_03_dictionary.dic_quote USING btree (fk_index_id, fk_entry_id);


--
-- Name: ix_dic_ref_fk_entry; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_ref_fk_entry ON sc_03_dictionary.dic_ref USING btree (fk_entry_id);


--
-- Name: ix_dic_ref_fk_index; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_ref_fk_index ON sc_03_dictionary.dic_ref USING btree (fk_index_id);


--
-- Name: ix_dic_ref_index_entry; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE INDEX ix_dic_ref_index_entry ON sc_03_dictionary.dic_ref USING btree (fk_index_id, fk_entry_id);


--
-- Name: uq_dic_doc_root_current; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_doc_root_current ON sc_03_dictionary.dic_doc USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_dic_doc_root_version; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_doc_root_version ON sc_03_dictionary.dic_doc USING btree (root_id, version);


--
-- Name: uq_dic_eg_root_current; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_eg_root_current ON sc_03_dictionary.dic_eg USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_dic_eg_root_version; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_eg_root_version ON sc_03_dictionary.dic_eg USING btree (root_id, version);


--
-- Name: uq_dic_entry_per_index; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_entry_per_index ON sc_03_dictionary.dic_entry USING btree (dictionary, fk_index_id, lang, entry_no, name);


--
-- Name: uq_dic_entry_root_current; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_entry_root_current ON sc_03_dictionary.dic_entry USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_dic_entry_root_version; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_entry_root_version ON sc_03_dictionary.dic_entry USING btree (root_id, version);


--
-- Name: uq_dic_index_root_current; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_index_root_current ON sc_03_dictionary.dic_index USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_dic_index_root_version; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_index_root_version ON sc_03_dictionary.dic_index USING btree (root_id, version);


--
-- Name: uq_dic_index_source_file_order; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_index_source_file_order ON sc_03_dictionary.dic_index USING btree (source_file, source_order);


--
-- Name: uq_dic_note_root_current; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_note_root_current ON sc_03_dictionary.dic_note USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_dic_note_root_version; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_note_root_version ON sc_03_dictionary.dic_note USING btree (root_id, version);


--
-- Name: uq_dic_quote_root_current; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_quote_root_current ON sc_03_dictionary.dic_quote USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_dic_quote_root_version; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_quote_root_version ON sc_03_dictionary.dic_quote USING btree (root_id, version);


--
-- Name: uq_dic_ref_root_current; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_ref_root_current ON sc_03_dictionary.dic_ref USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_dic_ref_root_version; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_ref_root_version ON sc_03_dictionary.dic_ref USING btree (root_id, version);


--
-- Name: uq_dic_scan_per_index_version; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_scan_per_index_version ON sc_03_dictionary.dic_scan USING btree (fk_index_id, scan_version);


--
-- Name: uq_dic_scan_root_current; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_scan_root_current ON sc_03_dictionary.dic_scan USING btree (root_id) WHERE (is_current = true);


--
-- Name: uq_dic_scan_root_version; Type: INDEX; Schema: sc_03_dictionary; Owner: -
--

CREATE UNIQUE INDEX uq_dic_scan_root_version ON sc_03_dictionary.dic_scan USING btree (root_id, version);


--
-- Name: idx_lang_doc_title; Type: INDEX; Schema: sc_04_language; Owner: -
--

CREATE INDEX idx_lang_doc_title ON sc_04_language.lang_doc USING btree (doc_title);


--
-- Name: idx_lang_language_title; Type: INDEX; Schema: sc_04_language; Owner: -
--

CREATE INDEX idx_lang_language_title ON sc_04_language.lang_language USING btree (lang_title);


--
-- Name: idx_abbr_audit_event_at; Type: INDEX; Schema: sc_05_audit; Owner: -
--

CREATE INDEX idx_abbr_audit_event_at ON sc_05_audit.abbr_audit_events USING btree (event_at);


--
-- Name: idx_abbr_audit_row_time; Type: INDEX; Schema: sc_05_audit; Owner: -
--

CREATE INDEX idx_abbr_audit_row_time ON sc_05_audit.abbr_audit_events USING btree (table_name, row_id, event_at);


--
-- Name: idx_dic_entry_audit_event_at; Type: INDEX; Schema: sc_05_audit; Owner: -
--

CREATE INDEX idx_dic_entry_audit_event_at ON sc_05_audit.dic_entry_audit_events USING btree (event_at);


--
-- Name: idx_dic_entry_audit_row_time; Type: INDEX; Schema: sc_05_audit; Owner: -
--

CREATE INDEX idx_dic_entry_audit_row_time ON sc_05_audit.dic_entry_audit_events USING btree (table_name, row_id, event_at);


--
-- Name: idx_ref_audit_event_at; Type: INDEX; Schema: sc_05_audit; Owner: -
--

CREATE INDEX idx_ref_audit_event_at ON sc_05_audit.ref_audit_events USING btree (event_at);


--
-- Name: idx_ref_audit_row_time; Type: INDEX; Schema: sc_05_audit; Owner: -
--

CREATE INDEX idx_ref_audit_row_time ON sc_05_audit.ref_audit_events USING btree (table_name, row_id, event_at);


--
-- Name: ix_ocr_link_fk_entry_id; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE INDEX ix_ocr_link_fk_entry_id ON sc_06_ocr.ocr_link USING btree (fk_entry_id);


--
-- Name: ix_ocr_link_fk_index_id; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE INDEX ix_ocr_link_fk_index_id ON sc_06_ocr.ocr_link USING btree (fk_index_id);


--
-- Name: ix_ocr_link_kind; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE INDEX ix_ocr_link_kind ON sc_06_ocr.ocr_link USING btree (link_kind);


--
-- Name: ix_ocr_page_result_page; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE INDEX ix_ocr_page_result_page ON sc_06_ocr.ocr_page_result USING btree (fk_page_id);


--
-- Name: ix_ocr_review_status; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE INDEX ix_ocr_review_status ON sc_06_ocr.ocr_review USING btree (review_status);


--
-- Name: ix_ocr_run_engine_started_at; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE INDEX ix_ocr_run_engine_started_at ON sc_06_ocr.ocr_run USING btree (engine, started_at);


--
-- Name: ix_ocr_token_text_norm; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE INDEX ix_ocr_token_text_norm ON sc_06_ocr.ocr_token USING btree (text_norm);


--
-- Name: uq_ocr_page_doc_page_no; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE UNIQUE INDEX uq_ocr_page_doc_page_no ON sc_06_ocr.ocr_page USING btree (fk_source_doc_id, page_no);


--
-- Name: uq_ocr_page_result_run_page; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE UNIQUE INDEX uq_ocr_page_result_run_page ON sc_06_ocr.ocr_page_result USING btree (fk_run_id, fk_page_id);


--
-- Name: uq_ocr_review_page_result; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE UNIQUE INDEX uq_ocr_review_page_result ON sc_06_ocr.ocr_review USING btree (fk_page_result_id);


--
-- Name: uq_ocr_source_doc_sha256; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE UNIQUE INDEX uq_ocr_source_doc_sha256 ON sc_06_ocr.ocr_source_doc USING btree (source_sha256);


--
-- Name: uq_ocr_token_result_token_no; Type: INDEX; Schema: sc_06_ocr; Owner: -
--

CREATE UNIQUE INDEX uq_ocr_token_result_token_no ON sc_06_ocr.ocr_token USING btree (fk_page_result_id, token_no);


--
-- Name: ix_executed_sql_scripts_file_path; Type: INDEX; Schema: sc_07_hash; Owner: -
--

CREATE INDEX ix_executed_sql_scripts_file_path ON sc_07_hash.executed_sql_scripts USING btree (file_path);


--
-- Name: ix_temporary_hash_fk_index_id; Type: INDEX; Schema: sc_07_hash; Owner: -
--

CREATE INDEX ix_temporary_hash_fk_index_id ON sc_07_hash.temporary_hash USING btree (fk_index_id);


--
-- Name: uq_executed_sql_scripts_file_hash; Type: INDEX; Schema: sc_07_hash; Owner: -
--

CREATE UNIQUE INDEX uq_executed_sql_scripts_file_hash ON sc_07_hash.executed_sql_scripts USING btree (file_hash);


--
-- Name: uq_temporary_hash_dic_index_hash; Type: INDEX; Schema: sc_07_hash; Owner: -
--

CREATE UNIQUE INDEX uq_temporary_hash_dic_index_hash ON sc_07_hash.temporary_hash USING btree (dic_index_hash);


--
-- Name: abbr_books_periodicals trg_audit_abbr_books_periodicals; Type: TRIGGER; Schema: sc_01_abbreviations; Owner: -
--

CREATE TRIGGER trg_audit_abbr_books_periodicals AFTER INSERT OR DELETE OR UPDATE ON sc_01_abbreviations.abbr_books_periodicals FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: abbr_docs trg_audit_abbr_docs; Type: TRIGGER; Schema: sc_01_abbreviations; Owner: -
--

CREATE TRIGGER trg_audit_abbr_docs AFTER INSERT OR DELETE OR UPDATE ON sc_01_abbreviations.abbr_docs FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: abbr_general_terms trg_audit_abbr_general_terms; Type: TRIGGER; Schema: sc_01_abbreviations; Owner: -
--

CREATE TRIGGER trg_audit_abbr_general_terms AFTER INSERT OR DELETE OR UPDATE ON sc_01_abbreviations.abbr_general_terms FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: abbr_grammatical_terms trg_audit_abbr_grammatical_terms; Type: TRIGGER; Schema: sc_01_abbreviations; Owner: -
--

CREATE TRIGGER trg_audit_abbr_grammatical_terms AFTER INSERT OR DELETE OR UPDATE ON sc_01_abbreviations.abbr_grammatical_terms FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: abbr_publication_sources trg_audit_abbr_publication_sources; Type: TRIGGER; Schema: sc_01_abbreviations; Owner: -
--

CREATE TRIGGER trg_audit_abbr_publication_sources AFTER INSERT OR DELETE OR UPDATE ON sc_01_abbreviations.abbr_publication_sources FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: abbr_typographicals trg_audit_abbr_typographicals; Type: TRIGGER; Schema: sc_01_abbreviations; Owner: -
--

CREATE TRIGGER trg_audit_abbr_typographicals AFTER INSERT OR DELETE OR UPDATE ON sc_01_abbreviations.abbr_typographicals FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: ref_bibliography trg_audit_ref_bibliography; Type: TRIGGER; Schema: sc_02_bibliography; Owner: -
--

CREATE TRIGGER trg_audit_ref_bibliography AFTER INSERT OR DELETE OR UPDATE ON sc_02_bibliography.ref_bibliography FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: ref_doc trg_audit_ref_doc; Type: TRIGGER; Schema: sc_02_bibliography; Owner: -
--

CREATE TRIGGER trg_audit_ref_doc AFTER INSERT OR DELETE OR UPDATE ON sc_02_bibliography.ref_doc FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: ref_internet_sources trg_audit_ref_internet_sources; Type: TRIGGER; Schema: sc_02_bibliography; Owner: -
--

CREATE TRIGGER trg_audit_ref_internet_sources AFTER INSERT OR DELETE OR UPDATE ON sc_02_bibliography.ref_internet_sources FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: ref_texts trg_audit_ref_texts; Type: TRIGGER; Schema: sc_02_bibliography; Owner: -
--

CREATE TRIGGER trg_audit_ref_texts AFTER INSERT OR DELETE OR UPDATE ON sc_02_bibliography.ref_texts FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: dic_doc trg_audit_dic_doc; Type: TRIGGER; Schema: sc_03_dictionary; Owner: -
--

CREATE TRIGGER trg_audit_dic_doc AFTER INSERT OR DELETE OR UPDATE ON sc_03_dictionary.dic_doc FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: dic_eg trg_audit_dic_eg; Type: TRIGGER; Schema: sc_03_dictionary; Owner: -
--

CREATE TRIGGER trg_audit_dic_eg AFTER INSERT OR DELETE OR UPDATE ON sc_03_dictionary.dic_eg FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: dic_entry trg_audit_dic_entry; Type: TRIGGER; Schema: sc_03_dictionary; Owner: -
--

CREATE TRIGGER trg_audit_dic_entry AFTER INSERT OR DELETE OR UPDATE ON sc_03_dictionary.dic_entry FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: dic_index trg_audit_dic_index; Type: TRIGGER; Schema: sc_03_dictionary; Owner: -
--

CREATE TRIGGER trg_audit_dic_index AFTER INSERT OR DELETE OR UPDATE ON sc_03_dictionary.dic_index FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: dic_note trg_audit_dic_note; Type: TRIGGER; Schema: sc_03_dictionary; Owner: -
--

CREATE TRIGGER trg_audit_dic_note AFTER INSERT OR DELETE OR UPDATE ON sc_03_dictionary.dic_note FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: dic_quote trg_audit_dic_quote; Type: TRIGGER; Schema: sc_03_dictionary; Owner: -
--

CREATE TRIGGER trg_audit_dic_quote AFTER INSERT OR DELETE OR UPDATE ON sc_03_dictionary.dic_quote FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: dic_ref trg_audit_dic_ref; Type: TRIGGER; Schema: sc_03_dictionary; Owner: -
--

CREATE TRIGGER trg_audit_dic_ref AFTER INSERT OR DELETE OR UPDATE ON sc_03_dictionary.dic_ref FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: dic_scan trg_audit_dic_scan; Type: TRIGGER; Schema: sc_03_dictionary; Owner: -
--

CREATE TRIGGER trg_audit_dic_scan AFTER INSERT OR DELETE OR UPDATE ON sc_03_dictionary.dic_scan FOR EACH ROW EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();


--
-- Name: dic_vocab trg_vocab_normalize; Type: TRIGGER; Schema: sc_03_dictionary; Owner: -
--

CREATE TRIGGER trg_vocab_normalize BEFORE INSERT OR UPDATE OF term ON sc_03_dictionary.dic_vocab FOR EACH ROW EXECUTE FUNCTION public.fn_vocab_normalize();


--
-- Name: user_roles fk_rails_3369e0d5fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_rails_3369e0d5fc FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: oauth_access_tokens fk_rails_732cb83ab7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_732cb83ab7 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: oauth_access_grants fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: dic_eg tbl_dic_eg_fk_entry_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_eg
    ADD CONSTRAINT tbl_dic_eg_fk_entry_id_fkey FOREIGN KEY (fk_entry_id) REFERENCES sc_03_dictionary.dic_entry(id) ON DELETE CASCADE;


--
-- Name: dic_eg tbl_dic_eg_fk_index_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_eg
    ADD CONSTRAINT tbl_dic_eg_fk_index_id_fkey FOREIGN KEY (fk_index_id) REFERENCES sc_03_dictionary.dic_index(id) ON DELETE CASCADE;


--
-- Name: dic_entry tbl_dic_entry_fk_index_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_entry
    ADD CONSTRAINT tbl_dic_entry_fk_index_id_fkey FOREIGN KEY (fk_index_id) REFERENCES sc_03_dictionary.dic_index(id) ON DELETE CASCADE;


--
-- Name: dic_note tbl_dic_note_fk_entry_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_note
    ADD CONSTRAINT tbl_dic_note_fk_entry_id_fkey FOREIGN KEY (fk_entry_id) REFERENCES sc_03_dictionary.dic_entry(id) ON DELETE CASCADE;


--
-- Name: dic_note tbl_dic_note_fk_index_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_note
    ADD CONSTRAINT tbl_dic_note_fk_index_id_fkey FOREIGN KEY (fk_index_id) REFERENCES sc_03_dictionary.dic_index(id) ON DELETE CASCADE;


--
-- Name: dic_quote tbl_dic_quote_fk_entry_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_quote
    ADD CONSTRAINT tbl_dic_quote_fk_entry_id_fkey FOREIGN KEY (fk_entry_id) REFERENCES sc_03_dictionary.dic_entry(id) ON DELETE CASCADE;


--
-- Name: dic_quote tbl_dic_quote_fk_index_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_quote
    ADD CONSTRAINT tbl_dic_quote_fk_index_id_fkey FOREIGN KEY (fk_index_id) REFERENCES sc_03_dictionary.dic_index(id) ON DELETE CASCADE;


--
-- Name: dic_ref tbl_dic_ref_fk_entry_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_ref
    ADD CONSTRAINT tbl_dic_ref_fk_entry_id_fkey FOREIGN KEY (fk_entry_id) REFERENCES sc_03_dictionary.dic_entry(id) ON DELETE CASCADE;


--
-- Name: dic_ref tbl_dic_ref_fk_index_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_ref
    ADD CONSTRAINT tbl_dic_ref_fk_index_id_fkey FOREIGN KEY (fk_index_id) REFERENCES sc_03_dictionary.dic_index(id) ON DELETE CASCADE;


--
-- Name: dic_scan tbl_dic_scan_fk_index_id_fkey; Type: FK CONSTRAINT; Schema: sc_03_dictionary; Owner: -
--

ALTER TABLE ONLY sc_03_dictionary.dic_scan
    ADD CONSTRAINT tbl_dic_scan_fk_index_id_fkey FOREIGN KEY (fk_index_id) REFERENCES sc_03_dictionary.dic_index(id) ON DELETE CASCADE;


--
-- Name: ocr_link fk_ocr_link_dic_entry; Type: FK CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_link
    ADD CONSTRAINT fk_ocr_link_dic_entry FOREIGN KEY (fk_entry_id) REFERENCES sc_03_dictionary.dic_entry(id) ON DELETE SET NULL;


--
-- Name: ocr_link fk_ocr_link_dic_index; Type: FK CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_link
    ADD CONSTRAINT fk_ocr_link_dic_index FOREIGN KEY (fk_index_id) REFERENCES sc_03_dictionary.dic_index(id) ON DELETE SET NULL;


--
-- Name: ocr_link fk_ocr_link_page_result; Type: FK CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_link
    ADD CONSTRAINT fk_ocr_link_page_result FOREIGN KEY (fk_page_result_id) REFERENCES sc_06_ocr.ocr_page_result(id) ON DELETE CASCADE;


--
-- Name: ocr_page_result fk_ocr_page_result_page; Type: FK CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_page_result
    ADD CONSTRAINT fk_ocr_page_result_page FOREIGN KEY (fk_page_id) REFERENCES sc_06_ocr.ocr_page(id) ON DELETE CASCADE;


--
-- Name: ocr_page_result fk_ocr_page_result_run; Type: FK CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_page_result
    ADD CONSTRAINT fk_ocr_page_result_run FOREIGN KEY (fk_run_id) REFERENCES sc_06_ocr.ocr_run(id) ON DELETE CASCADE;


--
-- Name: ocr_page fk_ocr_page_source_doc; Type: FK CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_page
    ADD CONSTRAINT fk_ocr_page_source_doc FOREIGN KEY (fk_source_doc_id) REFERENCES sc_06_ocr.ocr_source_doc(id) ON DELETE CASCADE;


--
-- Name: ocr_review fk_ocr_review_page_result; Type: FK CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_review
    ADD CONSTRAINT fk_ocr_review_page_result FOREIGN KEY (fk_page_result_id) REFERENCES sc_06_ocr.ocr_page_result(id) ON DELETE CASCADE;


--
-- Name: ocr_token fk_ocr_token_page_result; Type: FK CONSTRAINT; Schema: sc_06_ocr; Owner: -
--

ALTER TABLE ONLY sc_06_ocr.ocr_token
    ADD CONSTRAINT fk_ocr_token_page_result FOREIGN KEY (fk_page_result_id) REFERENCES sc_06_ocr.ocr_page_result(id) ON DELETE CASCADE;


--
-- Name: temporary_hash fk_temporary_hash_index_id; Type: FK CONSTRAINT; Schema: sc_07_hash; Owner: -
--

ALTER TABLE ONLY sc_07_hash.temporary_hash
    ADD CONSTRAINT fk_temporary_hash_index_id FOREIGN KEY (fk_index_id) REFERENCES sc_03_dictionary.dic_index(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260219191541'),
('20260218180629'),
('20260218063636'),
('20260209050443'),
('20260207152542'),
('20260206045823'),
('20260131054304'),
('20260123192741'),
('20260123182157'),
('20260123182124'),
('20260123182044'),
('20260123181305'),
('20260123180128'),
('20260123172718'),
('20260123165647'),
('20260123165425'),
('20260123165040'),
('20260123164921'),
('20260123164520'),
('20260123164321'),
('20260123164206'),
('20260123164001'),
('20260123163225'),
('20260123163145'),
('20260123163115'),
('20260123162953'),
('20260123162916'),
('20260123162840'),
('20260123162815'),
('20260123162649'),
('20260123162616'),
('20260123162441'),
('20260123162413'),
('20260123162320'),
('20260123162306');

