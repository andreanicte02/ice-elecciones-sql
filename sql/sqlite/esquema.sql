-- SQLite version of creacionbd.sql: the same 10 tables, keys and foreign keys.
-- IDENTITY(1,1) becomes INTEGER PRIMARY KEY, which SQLite numbers from 1 the same way.
PRAGMA foreign_keys = ON;

CREATE TABLE pais (
  id     INTEGER PRIMARY KEY,
  nombre VARCHAR(50)
);

CREATE TABLE region (
  id      INTEGER PRIMARY KEY,
  nombre  VARCHAR(50),
  pais_id INTEGER NOT NULL REFERENCES pais (id)
);

CREATE TABLE departamento (
  id        INTEGER PRIMARY KEY,
  nombre    VARCHAR(50),
  region_id INTEGER NOT NULL REFERENCES region (id)
);

CREATE TABLE municipio (
  id              INTEGER PRIMARY KEY,
  nombre          VARCHAR(50),
  departamento_id INTEGER NOT NULL REFERENCES departamento (id)
);

CREATE TABLE eleccion (
  id              INTEGER PRIMARY KEY,
  nombre_eleccion VARCHAR(50)
);

CREATE TABLE partido (
  id             INTEGER PRIMARY KEY,
  partido        VARCHAR(50),
  nombre_partido VARCHAR(50)
);

CREATE TABLE genero (
  id     INTEGER PRIMARY KEY,
  nombre VARCHAR(50)
);

CREATE TABLE raza (
  id     INTEGER PRIMARY KEY,
  nombre VARCHAR(50)
);

CREATE TABLE tipovotante (
  id   INTEGER PRIMARY KEY,
  tipo CHAR(20)
);

CREATE TABLE voto (
  id             INTEGER PRIMARY KEY,
  cantidad       INTEGER,
  ano            INTEGER,
  eleccion_id    INTEGER NOT NULL REFERENCES eleccion (id),
  partido_id     INTEGER NOT NULL REFERENCES partido (id),
  genero_id      INTEGER NOT NULL REFERENCES genero (id),
  raza_id        INTEGER NOT NULL REFERENCES raza (id),
  tipovotante_id INTEGER NOT NULL REFERENCES tipovotante (id),
  municipio_id   INTEGER NOT NULL REFERENCES municipio (id)
);
