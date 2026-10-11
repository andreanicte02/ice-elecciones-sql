-- 11. Los dos partidos con más votos en cada municipio.
WITH por_municipio AS (
  SELECT pais, municipio, nombre_partido, partido, SUM(cantidad) AS votos
  FROM voto_detalle
  WHERE tipovotante_id >= 4
  GROUP BY pais, municipio, nombre_partido, partido
), ranking AS (
  SELECT pais, municipio, nombre_partido, partido, votos,
         ROW_NUMBER() OVER (PARTITION BY pais, municipio ORDER BY votos DESC) AS puesto
  FROM por_municipio
)
SELECT pais, municipio, nombre_partido, partido, votos
FROM ranking
WHERE puesto <= 2
ORDER BY pais, municipio, votos DESC;
