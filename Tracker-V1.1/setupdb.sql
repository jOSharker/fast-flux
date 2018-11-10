-- PostgreSQL database setup

SET client_encoding = 'LATIN1';
SET check_function_bodies = false;
SET client_min_messages = warning;


COMMENT ON SCHEMA public IS 'Standard public schema';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;


CREATE TABLE hostname (
    hostname character varying(200) NOT NULL,
    submit_date date,
    last_seen date,
    live boolean,
    track boolean
);

CREATE TABLE "input" (
    hostname character varying(200) NOT NULL,
    date_submit date
);


CREATE TABLE node (
    ip character varying(15) NOT NULL,
    hostname character varying(200),
    "time" integer
);

ALTER TABLE ONLY hostname
    ADD CONSTRAINT hostname_pk PRIMARY KEY (hostname);

ALTER TABLE ONLY "input"
    ADD CONSTRAINT input_pk PRIMARY KEY (hostname);

