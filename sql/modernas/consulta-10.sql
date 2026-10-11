-- 10. Total de votos de los municipios agrupados por su letra inicial.
SELECT SUBSTRING(municipio, 1, 1) AS letra, SUM(cantidad) AS votos
FROM voto_detalle
WHERE tipovotante_id >= 4
GROUP BY SUBSTRING(municipio, 1, 1)
ORDER BY letra;
