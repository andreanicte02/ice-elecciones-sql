-- 2. Total y porcentaje de votos de mujeres indígenas alfabetas.
SELECT SUM(CASE WHEN tipovotante_id = 5 AND genero = 'mujeres' AND raza = 'INDIGENAS'
                THEN cantidad ELSE 0 END) AS votos,
       100.0 * SUM(CASE WHEN tipovotante_id = 5 AND genero = 'mujeres' AND raza = 'INDIGENAS'
                        THEN cantidad ELSE 0 END)
             / SUM(CASE WHEN tipovotante_id >= 4 THEN cantidad ELSE 0 END) AS porcentaje
FROM voto_detalle;
