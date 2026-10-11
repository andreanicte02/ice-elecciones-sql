-- 7. Departamentos donde votaron más mujeres universitarias que hombres universitarios.
WITH por_depto AS (
  SELECT pais, departamento,
         SUM(CASE WHEN genero = 'mujeres' THEN cantidad ELSE 0 END) AS mujeres,
         SUM(CASE WHEN genero = 'hombres' THEN cantidad ELSE 0 END) AS hombres
  FROM voto_detalle
  WHERE tipovotante_id = 1
  GROUP BY pais, departamento
)
SELECT pais, departamento,
       100.0 * mujeres / (mujeres + hombres) AS porcentaje_mujeres,
       100.0 - 100.0 * mujeres / (mujeres + hombres) AS porcentaje_hombres,
       mujeres + hombres AS universitarios, mujeres, hombres
FROM por_depto
WHERE mujeres > hombres
ORDER BY pais, departamento;
