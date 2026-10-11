-- One view with every join the 2018 queries repeated by hand.
-- tipovotante: 1 universitario, 2 medio, 3 primaria, 4 analfa, 5 alfa.
-- Every voter is counted once as analfa (4) or alfa (5), so `tipovotante_id >= 4`
-- means "all voters"; 1-3 break down the literate ones by schooling.
CREATE VIEW voto_detalle AS
SELECT v.cantidad,
       v.ano,
       v.tipovotante_id,
       e.nombre_eleccion,
       pa.nombre AS pais,
       re.nombre AS region,
       de.nombre AS departamento,
       mu.nombre AS municipio,
       pt.partido,
       pt.nombre_partido,
       ge.nombre AS genero,
       ra.nombre AS raza
FROM voto v
JOIN eleccion e      ON e.id = v.eleccion_id
JOIN municipio mu    ON mu.id = v.municipio_id
JOIN departamento de ON de.id = mu.departamento_id
JOIN region re       ON re.id = de.region_id
JOIN pais pa         ON pa.id = re.pais_id
JOIN partido pt      ON pt.id = v.partido_id
JOIN genero ge       ON ge.id = v.genero_id
JOIN raza ra         ON ra.id = v.raza_id;
