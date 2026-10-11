-- Replaces the Excel import at the top of cargaabd.sql (OPENROWSET + the ACE OLE DB
-- driver, which only exists on Windows). It fills the same #TEMPORAL0 temporary table
-- from data/ICE-Fuente.csv; the rest of cargaabd.sql then runs unchanged in the same session.
--
-- SQL Server on Linux reads plain-text BULK INSERT files as code page 437 and doesn't
-- support the CODEPAGE option, which garbles accents (Pacífico -> Pac├¡fico). So the
-- loader uses a UTF-16 copy of the CSV (DATAFILETYPE = 'widechar'), which every platform
-- reads correctly; tests/verificar.py writes that copy to build/ before running this.
-- The text columns use COLLATE DATABASE_DEFAULT so they compare cleanly with the tables.
CREATE TABLE #TEMPORAL0 (
  PAIS            VARCHAR(50) COLLATE DATABASE_DEFAULT,
  NOMBRE_ELECCION VARCHAR(50) COLLATE DATABASE_DEFAULT,
  AÑO_ELECCION    INT,
  REGION          VARCHAR(50) COLLATE DATABASE_DEFAULT,
  DEPTO           VARCHAR(50) COLLATE DATABASE_DEFAULT,
  MUNICIPIO       VARCHAR(50) COLLATE DATABASE_DEFAULT,
  PARTIDO         VARCHAR(50) COLLATE DATABASE_DEFAULT,
  NOMBRE_PARTIDO  VARCHAR(50) COLLATE DATABASE_DEFAULT,
  SEXO            VARCHAR(50) COLLATE DATABASE_DEFAULT,
  RAZA            VARCHAR(50) COLLATE DATABASE_DEFAULT,
  ANALFABETOS     INT,
  ALFABETOS       INT,
  PRIMARIA        INT,
  [NIVEL MEDIO]   INT,
  UNIVERSITARIOS  INT
);

BULK INSERT #TEMPORAL0
FROM '/data/ICE-Fuente-utf16.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, DATAFILETYPE = 'widechar');
