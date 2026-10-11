-- The flat sheet, as the 2018 load script expects it in #TEMPORAL0.
-- data/ICE-Fuente.csv is inserted here row by row before sql/sqlite/carga.sql runs.
CREATE TEMP TABLE [#TEMPORAL0] (
  pais            VARCHAR(50),
  nombre_eleccion VARCHAR(50),
  año_eleccion    INTEGER,
  region          VARCHAR(50),
  depto           VARCHAR(50),
  municipio       VARCHAR(50),
  partido         VARCHAR(50),
  nombre_partido  VARCHAR(50),
  sexo            VARCHAR(50),
  raza            VARCHAR(50),
  analfabetos     INTEGER,
  alfabetos       INTEGER,
  primaria        INTEGER,
  [nivel medio]   INTEGER,
  universitarios  INTEGER
);
