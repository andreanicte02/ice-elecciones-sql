-- 6. Regiones de cada país donde predomina la raza indígena.
WITH por_raza AS (
  SELECT pais, region, raza, SUM(cantidad) AS votos
  FROM voto_detalle
  WHERE tipovotante_id >= 4
  GROUP BY pais, region, raza
), ranking AS (
  SELECT pais, region, raza, votos,
         ROW_NUMBER() OVER (PARTITION BY pais, region ORDER BY votos DESC) AS puesto
  FROM por_raza
)
SELECT pais, region, votos, raza
FROM ranking
WHERE puesto = 1 AND raza = 'INDIGENAS'
ORDER BY pais, votos DESC;
