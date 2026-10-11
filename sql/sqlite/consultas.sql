-- SQLite port of consultas.sql (2018). The only change: SQL Server's `select top 1`
-- becomes `limit 1` (queries 4 and 14). Query 5 was never written in 2018.
-------------------------------------------------------------consulta 1
select c3.ne as nombre_elecciones, c3.anio as fecha, c3.nomb as pais, c3.partido, c3.porcentaje as porcentaje
, c3.vts as votos_mayores
from
(
select C2.nomb, (C1.vts*1.00 / C2.sumvts*1.00) * 100 as porcentaje, c1.ptr as partido, c1.anio, c1.vts, C2.ne
from
(
select tabla.nom nomb, sum(tabla.vts)
 sumvts, tabla.ne

from
(
select  p.nombre nom, sum( v.cantidad) as vts,  part.nombre_partido prt, v.ano anio, e.nombre_eleccion ne
from  voto v, pais p, departamento dep, municipio mun, region re, partido part, eleccion e
where v.tipovotante_id >= 4
and v.municipio_id = mun.id
and mun.departamento_id = dep.id
and dep.region_id = re.id
and re.pais_id = p.id
and v.partido_id = part.id
and v.eleccion_id = e.id
group by p.nombre, part.nombre_partido, v.ano, part.nombre_partido, e.nombre_eleccion)as tabla
group by tabla.nom , tabla.ne
) as C2,
-----
(
select  *
from
(
select t.nombre nmb, t.botos vts, t.nombre_partido ptr, t.ano anio,
row_number () over (partition by t.nombre order by t.botos desc) as prueba
from 
(
select  p.nombre, sum( v.cantidad) as botos,  part.nombre_partido, v.ano
from  voto v, pais p, departamento dep, municipio mun, region re, partido part
where v.tipovotante_id >= 4
and v.municipio_id = mun.id
and mun.departamento_id = dep.id
and dep.region_id = re.id
and re.pais_id = p.id
and v.partido_id = part.id
group by p.nombre, part.nombre_partido, v.ano 
) as t
)as t2
where t2.prueba = 1
) as C1
where C1.nmb = C2.nomb)
c3 
;
-----------------------------------------------------------------------fin
-----------------------------------------------------------------------consulta 2
SELECT c1.votos as [Mujeres indigenas alfabetas], (c1.votos*1.00/c2.votos*1.00)*100.00 as [Porcentaje sobre total votos]
from
(select  sum( cantidad )as votos
from voto v , genero ge, raza ra
where v.tipovotante_id = 5
and v.genero_id = ge.id
and v.genero_id = 2
and ra.id = v.raza_id
and ra.nombre = 'INDIGENAS') as c1,
(select  sum( cantidad )as votos
from voto v 
where v.tipovotante_id >= 4
) as c2
------------------------------------------------------------------consulta 3

select * from
(
select c1.pais, c1.departamento,c1.votos, ((c1.votos*1.00/ c2.totalvotos*1.00) *100.00) as porcentaje
from
(select pa.nombre as pais, de.nombre as departamento,sum(v.cantidad) as votos
from voto v, municipio mu, departamento de, region re, pais pa, genero ge
where v.tipovotante_id >=4
and v.municipio_id = mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.genero_id = ge.id
and ge.id = 2 ---si no por el nombre
group by  pa.nombre, de.id, de.nombre) as c1,


(select pa.nombre as pais, sum(v.cantidad) as totalvotos
from voto v, municipio mu, departamento de, region re, pais pa, genero ge
where v.tipovotante_id >=4
and v.municipio_id = mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.genero_id = ge.id
and ge.id = 2 ---- si no por el nombre
group by  pa.nombre  ) as c2
where c2.pais = c1.pais
) as c3 
order by c3.pais
----------------------------------------------------------------fin
----------------------------------------------------------------consulta 4

select c1.nombre as pais, c1.personas_analfabetas as [Total personas analfabetas], 
(c1.personas_analfabetas*1.00/c2.personas_analfabetas*1.00)*100.0 as [Porcentaje de personas analfabetes en el pais]
from
(select pa.nombre,sum(cantidad) as personas_analfabetas
from voto v, municipio mu, departamento de, region re, pais pa 
where v.tipovotante_id=4
and v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
group by pa.nombre ) as c1,
(
select pa.nombre,sum(cantidad) as personas_analfabetas
from voto v, municipio mu, departamento de, region re, pais pa 
where v.tipovotante_id>=4
and v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
group by pa.nombre) as c2
where c1.nombre = c2.nombre
limit 1;
------------------------------------------------------------------fin
------------------------------------------------------------------consulta 6
select c2.pais, c2.nombre as region, c2.saber as votos, c2.raza  from
(select c1.pais, c1.nombre, c1.saber ,c1.raza, c1.idraza,
row_number () over ( partition by c1. pais ,c1.nombre order by c1.saber desc) as primero 
from (
select  pa.id ,pa.nombre as pais, re.nombre, sum(v.cantidad) saber, ra.nombre raza ,ra.id as idraza
from voto v, municipio mu, departamento de, region re, pais pa, partido part,
raza ra
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.partido_id = part.id
and v.tipovotante_id >=4
and v.raza_id = ra.id
group by pa.nombre, re.nombre, ra.nombre, pa.id, ra.id) as c1) as c2
where c2.primero = 1
and c2.idraza = 2
order by c2.pais , c2.saber desc
------------------------------------------------------------------fin
------------------------------------------------------------------consulta 7

select c3.pais, c3.depa, (c3.votosm*1.00/c4.votos*1.00)*100.00 as [porcentaje mujeres],
100.00 - ((c3.votosm*1.00/c4.votos*1.00)*100.00) as[porcentaje hombres],
c4.votos as [universitarios], c3.votosm as votos_mujeres, c4.votos-c3.votosm as votos_hombres from 
-------
(select  c2.pais, c2.depa, c2.votos as votosm  from(
select c1.pais, c1.depa, c1.votos, c1.genero ,
row_number () over ( partition by c1. pais , c1.depa order by  c1.pais , c1.depa, c1.votos desc) as primero
from
(select  pa.id idpais ,pa.nombre pais ,  de.nombre depa, sum(v.cantidad) votos ,ge.nombre genero
from voto v, municipio mu, departamento de, region re, pais pa, partido part, genero ge
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.partido_id = part.id
and v.genero_id=ge.id
and v.tipovotante_id =1
group by pa.id,pa.nombre, de.nombre, ge.nombre) as c1) as c2
where c2.primero = 1
and genero = 'mujeres')as c3,

(select  pa.nombre pais ,  de.nombre depa, sum(v.cantidad) votos 
from voto v, municipio mu, departamento de, region re, pais pa, partido part, genero ge
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.partido_id = part.id
and v.genero_id=ge.id
and v.tipovotante_id =1
group by pa.nombre, de.nombre)  as c4
where c4.pais  = c3.pais
and c4.depa = c3.depa
order by c3.pais, c3.depa
----------------------------------------------------------------------------consulta 8
select c1.depa as departamento, c1.votos as votos
from
(select  pa.nombre pais ,  de.nombre depa, sum(v.cantidad) as votos
from voto v, municipio mu, departamento de, region re, pais pa, partido part
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.partido_id = part.id
and v.tipovotante_id >=4
and pa.nombre ='GUATEMALA'
group by pa.nombre, de.nombre

)as c1,

(select  pa.nombre pais ,  de.nombre depa, sum(v.cantidad) as votos
from voto v, municipio mu, departamento de, region re, pais pa, partido part
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.partido_id = part.id
and v.tipovotante_id >=4
and pa.nombre ='GUATEMALA'
and de.nombre = 'Guatemala'
group by pa.nombre, de.nombre) as c2
where c1.votos > c2.votos
-----------------------------------------------------------------------------consulta 9
select c2.pais, c2.region, sum(c3.votos)*1.00/c2.total_regionxpais*1.00 as promedio--, sum(c3.votos) as total_votos , c2.total_regionxpais
 from(
select c1.pais as pais, c1.region as region , count (c1.region) as total_regionxpais
from(
select  pa.nombre pais , re.nombre as region, sum(v.cantidad) as votos , de.nombre
from voto v, municipio mu, departamento de, region re, pais pa
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id >=4
group by pa.nombre, re.nombre, de.nombre ) as c1
group by c1.pais, c1.region) as c2,
(select  pa.nombre pais  , re.nombre as region, sum(v.cantidad) as votos --quitar div 2 si estan a la mitad
from voto v, municipio mu, departamento de, region re, pais pa
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id >=4
group by pa.nombre, re.nombre, de.nombre, re.nombre ) as c3
where c3.pais = c2.pais
and c3.region = c2.region
group by c2.pais, c2.region, c2.total_regionxpais
order by c2.pais;
-------------------------------------------------------consulta 10

select c1.municipio as letra , sum(c1.votos) as votos from
(select SUBSTRING( mu.nombre,1,1) as municipio, sum( cantidad )as votos
from voto v, municipio mu, departamento de, region re, pais pa
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id >=4
group by mu.nombre) as c1
group by c1.municipio
order by c1.municipio

-------------------------------------------------------consulta 11

select c2.pais, c2.municipio, c2.nombre_partido, c2.partido, c2.votos from
(select c1.pais, c1.municipio,c1.npartido as nombre_partido, c1.partido , c1.votos as votos,
row_number () over ( partition by  c1.pais, c1. municipio order by   c1.pais,c1.municipio, c1.votos  desc) as puesto
from 
(
select pa.nombre as pais,mu.nombre as municipio, part.nombre_partido as npartido ,part.partido as partido,   sum(cantidad )as votos
from voto v, municipio mu, departamento de, region re, pais pa, partido part
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id>=4
and v.partido_id  = part.id
group by pa.nombre, mu.nombre, part.nombre_partido ,part.partido

) as c1)as c2
where c2.puesto BETWEEN 1 and 2 
------------------------------------------------------------------------consulta 12

select c1.nombre, c1.primaria, c2.medio, c3.universitario from 
(select pa.nombre ,  sum( cantidad )as primaria
from voto v, municipio mu, departamento de, region re, pais pa
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id = 3
group by pa.nombre) as c1,

(select pa.nombre ,  sum( cantidad )as medio
from voto v, municipio mu, departamento de, region re, pais pa
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id = 2
group by pa.nombre) as c2,

(select pa.nombre ,  sum( cantidad )as universitario
from voto v, municipio mu, departamento de, region re, pais pa
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id = 1
group by pa.nombre) as c3
where c1.nombre= c2.nombre 
and c1.nombre= c3.nombre  
and c2.nombre= c3.nombre  
order by c1.nombre

---------------------------------------------------consulta 13
select  c1.pais, c1.raza, c1.votos, (c1.votos*1.00/c2.votos*1.00)*100 as porcentaje from

(select pa.nombre as pais, ra.nombre as raza,  sum( cantidad )as votos
from voto v, municipio mu, departamento de, region re, pais pa, raza ra
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id >=4
and v.raza_id  = ra.id
group by pa.nombre, ra.nombre) as c1,


(select pa.nombre as pais,  sum( cantidad )as votos
from voto v, municipio mu, departamento de, region re, pais pa
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id >=4
group by pa.nombre) as c2
where c1.pais = c2.pais
order by c1.pais
-----------------------------------------------------------consulta 14

select mayores2.pais, (mayores2.porcentaje -menores2.porcentaje) as porcentaje from
 
(select mayores.pais, mayores.porcentaje,
row_number () over ( partition by  mayores.pais order by   mayores.pais, mayores.porcentaje  desc) as puesto
from
(select c1.pais, (c1.votos*1.00/c2.votos*1.00)*100.00 as porcentaje
from
(
select pa.nombre as pais, part.partido,  sum( cantidad )as votos
from voto v, municipio mu, departamento de, region re, pais pa, partido part
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id >=4
and part.id = v.partido_id
group by pa.nombre, part.partido) as c1,


(select pa.nombre as pais, sum( cantidad )as votos
from voto v, municipio mu, departamento de, region re, pais pa
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id >=4
group by pa.nombre) as c2
where c1.pais = c2.pais) as mayores) as mayores2,

---menores

(select menores.pais, menores.porcentaje,
row_number () over ( partition by  menores.pais order by   menores.pais, menores.porcentaje  asc) as puesto
from
(select c1.pais, (c1.votos*1.00/c2.votos*1.00)*100.00 as porcentaje
from
(
select pa.nombre as pais, part.partido,  sum( cantidad )as votos
from voto v, municipio mu, departamento de, region re, pais pa, partido part
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id >=4
and part.id = v.partido_id
group by pa.nombre, part.partido) as c1,


(select pa.nombre as pais, sum( cantidad )as votos
from voto v, municipio mu, departamento de, region re, pais pa
where v.municipio_id= mu.id
and mu.departamento_id = de.id
and de.region_id = re.id
and re.pais_id = pa.id
and v.tipovotante_id >=4
group by pa.nombre) as c2
where c1.pais = c2.pais) as menores) as menores2
where menores2.pais = mayores2.pais
and menores2.puesto = 1
and mayores2.puesto =1
order by porcentaje asc
limit 1;

-----------------------------------------------------------fin :)
