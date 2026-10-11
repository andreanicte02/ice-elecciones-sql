-- 14. El país con la elección más reñida: menor diferencia de porcentaje entre el partido más votado y el menos votado.
WITH por_partido AS (
  SELECT pais, partido, SUM(cantidad) AS votos
  FROM voto_detalle
  WHERE tipovotante_id >= 4
  GROUP BY pais, partido
), porcentajes AS (
  SELECT pais, 100.0 * votos / SUM(votos) OVER (PARTITION BY pais) AS porcentaje
  FROM por_partido
), diferencias AS (
  SELECT pais, MAX(porcentaje) - MIN(porcentaje) AS porcentaje
  FROM porcentajes
  GROUP BY pais
), ranking AS (
  SELECT pais, porcentaje, ROW_NUMBER() OVER (ORDER BY porcentaje) AS puesto
  FROM diferencias
)
SELECT pais, porcentaje
FROM ranking
WHERE puesto = 1;
