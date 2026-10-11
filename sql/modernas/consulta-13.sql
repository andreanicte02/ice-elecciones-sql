-- 13. Porcentaje de votos por raza en cada país.
WITH por_raza AS (
  SELECT pais, raza, SUM(cantidad) AS votos
  FROM voto_detalle
  WHERE tipovotante_id >= 4
  GROUP BY pais, raza
)
SELECT pais, raza, votos,
       100.0 * votos / SUM(votos) OVER (PARTITION BY pais) AS porcentaje
FROM por_raza
ORDER BY pais, raza;
