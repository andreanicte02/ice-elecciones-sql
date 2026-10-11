-- 5. Por país, el partido que ganó más alcaldías (municipios donde fue el más votado).
-- No existía en 2018: es la consulta que faltaba.
WITH por_municipio AS (
  SELECT pais, departamento, municipio, partido, nombre_partido, SUM(cantidad) AS votos
  FROM voto_detalle
  WHERE tipovotante_id >= 4
  GROUP BY pais, departamento, municipio, partido, nombre_partido
), ganadores AS (
  SELECT pais, partido, nombre_partido,
         ROW_NUMBER() OVER (PARTITION BY pais, departamento, municipio ORDER BY votos DESC) AS puesto
  FROM por_municipio
), alcaldias AS (
  SELECT pais, partido, nombre_partido, COUNT(*) AS alcaldias
  FROM ganadores
  WHERE puesto = 1
  GROUP BY pais, partido, nombre_partido
), ranking AS (
  SELECT pais, nombre_partido, alcaldias,
         RANK() OVER (PARTITION BY pais ORDER BY alcaldias DESC) AS lugar
  FROM alcaldias
)
SELECT pais, nombre_partido, alcaldias
FROM ranking
WHERE lugar = 1
ORDER BY pais;
