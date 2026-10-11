-- 8. Departamentos de Guatemala con más votos que el departamento de Guatemala.
WITH por_depto AS (
  SELECT departamento, SUM(cantidad) AS votos
  FROM voto_detalle
  WHERE tipovotante_id >= 4 AND pais = 'GUATEMALA'
  GROUP BY departamento
)
SELECT departamento, votos
FROM por_depto
WHERE votos > (SELECT votos FROM por_depto WHERE departamento = 'Guatemala');
