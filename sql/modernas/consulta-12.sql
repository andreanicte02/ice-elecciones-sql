-- 12. Votos por nivel de escolaridad (primaria, medio, universitario) en cada país.
SELECT pais,
       SUM(CASE WHEN tipovotante_id = 3 THEN cantidad ELSE 0 END) AS primaria,
       SUM(CASE WHEN tipovotante_id = 2 THEN cantidad ELSE 0 END) AS medio,
       SUM(CASE WHEN tipovotante_id = 1 THEN cantidad ELSE 0 END) AS universitario
FROM voto_detalle
GROUP BY pais
ORDER BY pais;
