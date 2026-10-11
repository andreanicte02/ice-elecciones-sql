-- 9. Promedio de votos por departamento en cada región.
WITH por_depto AS (
  SELECT pais, region, departamento, SUM(cantidad) AS votos
  FROM voto_detalle
  WHERE tipovotante_id >= 4
  GROUP BY pais, region, departamento
)
SELECT pais, region, 1.0 * SUM(votos) / COUNT(*) AS promedio
FROM por_depto
GROUP BY pais, region
ORDER BY pais;
