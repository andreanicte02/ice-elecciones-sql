-- 4. El país con mayor porcentaje de votantes analfabetas.
-- La versión de 2018 usa TOP 1 sin ORDER BY, así que el país que devuelve depende del motor: mira la pestaña 2018.
WITH por_pais AS (
  SELECT pais,
         SUM(CASE WHEN tipovotante_id = 4 THEN cantidad ELSE 0 END) AS analfabetas,
         SUM(CASE WHEN tipovotante_id >= 4 THEN cantidad ELSE 0 END) AS total
  FROM voto_detalle
  GROUP BY pais
), ranking AS (
  SELECT pais, analfabetas, 100.0 * analfabetas / total AS porcentaje,
         ROW_NUMBER() OVER (ORDER BY 1.0 * analfabetas / total DESC) AS puesto
  FROM por_pais
)
SELECT pais, analfabetas, porcentaje
FROM ranking
WHERE puesto = 1;
