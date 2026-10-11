-- 3. Votos de mujeres por departamento y su porcentaje sobre el total de mujeres del país.
WITH por_depto AS (
  SELECT pais, departamento, SUM(cantidad) AS votos
  FROM voto_detalle
  WHERE tipovotante_id >= 4 AND genero = 'mujeres'
  GROUP BY pais, departamento
)
SELECT pais, departamento, votos,
       100.0 * votos / SUM(votos) OVER (PARTITION BY pais) AS porcentaje
FROM por_depto
ORDER BY pais, departamento;
