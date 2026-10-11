-- 1. Para cada elección, el partido con mayor porcentaje de votos en su país.
WITH votos AS (
  SELECT nombre_eleccion, ano, pais, nombre_partido, SUM(cantidad) AS votos
  FROM voto_detalle
  WHERE tipovotante_id >= 4
  GROUP BY nombre_eleccion, ano, pais, nombre_partido
), ranking AS (
  SELECT nombre_eleccion, ano, pais, nombre_partido, votos,
         100.0 * votos / SUM(votos) OVER (PARTITION BY nombre_eleccion, pais) AS porcentaje,
         ROW_NUMBER() OVER (PARTITION BY nombre_eleccion, pais ORDER BY votos DESC) AS puesto
  FROM votos
)
SELECT nombre_eleccion, ano, pais, nombre_partido, porcentaje, votos
FROM ranking
WHERE puesto = 1
ORDER BY pais;
