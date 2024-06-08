-- codigo marga
select 
	p.at_ds_flight_crew_code,
--	p.at_dt_duty_assign,
	f.at_cd_flight_number, 
	f.at_dt_flight_date, 
	f.at_ts_std_utc,
--	f.at_cd_airline_code as aircode,
--	f.at_ts_sta_utc,
--	f.at_ts_std_utc,
	a.at_cd_equipment_type as tipo,
	f.at_cd_airport_orig as departure,
	EXTRACT(EPOCH FROM (at_ts_sta_utc - at_ts_std_utc)) / 60 AS at_duration,
	p.at_is_dhc_flight,
	case
		WHEN f.at_cd_airport_orig IN ('FCO', 'ORY', 'AMS') THEN 60
        WHEN f.at_cd_airport_orig IN ('ALC', 'MAD') AND EXTRACT(EPOCH FROM (at_ts_sta_utc - at_ts_std_utc)) / 60 <= 180 THEN 50
        WHEN f.at_cd_airport_orig IN ('ALC', 'MAD') AND EXTRACT(EPOCH FROM (at_ts_sta_utc - at_ts_std_utc)) / 60 > 180 THEN 60
        WHEN EXTRACT(EPOCH FROM (at_ts_sta_utc - at_ts_std_utc)) / 60 <= 180 AND (a.at_cd_equipment_type = '321' OR f.at_cd_airport_orig = 'BCN') THEN 55
        WHEN EXTRACT(EPOCH FROM (at_ts_sta_utc - at_ts_std_utc)) / 60 > 180 AND (a.at_cd_equipment_type IN ('319', '320', '321') OR f.at_cd_airport_orig = 'BCN') THEN 60
        WHEN EXTRACT(EPOCH FROM (at_ts_sta_utc - at_ts_std_utc)) / 60 <= 180 AND a.at_cd_equipment_type IN ('319', '320') THEN 45 
        WHEN p.at_is_dhc_flight THEN 45
        ELSE 45 -- Valor por defecto si no se cumple ninguna condición
    END AS sign_in_time
from pairing p
left join flight f 
on p.at_cd_flight_number = f.at_cd_flight_number and p.at_dt_flight_date = f.at_dt_flight_date 
left join aircraft a 
on f.id_aircraft::char = a.id_aircraft
order by p.at_cd_flight_number;  
--order by p.at_ds_flight_crew_code, f.at_cd_flight_number, f.at_ts_std_utc
--where p.at_ds_flight_crew_code = '"002H "';  

-- da muchos valores repetidos, analizamos errores:

-- vemos el join entre pairing y glifhts
-- para que el join no me duplique las filas, el on debe ser en flight numer y flight date
select * from pairing p 
left join flight f 
on p.at_cd_flight_number = f.at_cd_flight_number and p.at_dt_flight_date = f.at_dt_flight_date 
where p.at_ds_flight_crew_code = '"101A "'; 


-- ahora el join de ambas con aircraft
select * from pairing p 
left join flight f 
on p.at_cd_flight_number = f.at_cd_flight_number and p.at_dt_flight_date = f.at_dt_flight_date 
left join aircraft a 
on f.id_aircraft::char = a.id_aircraft 
where p.at_ds_flight_crew_code = '"101A "'
order by p.at_dt_duty_assign ; 


select * from aircraft a ;
--ver si los distinct de crew code coinciden 
select distinct p.at_ds_flight_crew_code from pairing p 

select distinct trim(replace(p.at_ds_flight_crew_code, '"', '')) from pairing p
-- coinciden

select * from pairing p 
where p.at_ds_flight_crew_code = '"101A "';

select * from flight f 
where f.at_cd_flight_number = 8226;
select * from pairing p 
where p.at_ds_flight_crew_code = '"002H "';






/* limpiar duplicados pairing:
 	Notamos que hay registros duplicados que nos sesgan los resultados
 */
create view pairing_limpio as (
	select distinct 
		p.at_ds_flight_crew_code, 
		p.at_dt_duty_assign, 
		p.at_cd_flight_number,
		p.at_cd_leg,
		p.at_dt_flight_date, 
		p.at_cd_airline_code, 
		p.at_cd_airport_orig, 
		p.at_is_dhc_flight  
	from 
		pairing p
)
--3829 registros

--- esto nos devuelve at_cd_leg = 'A' que significa que tiene el mismo aeropuerto de salida y llegada
select * from flight f where f.at_cd_airport_orig = f.at_cd_airport_dest 

-- limpiamos duplicados:
create view flight_limpio as (
	select * 
		from flight f
	except
	select * 
		from flight f 
	where f.at_cd_airport_orig = f.at_cd_airport_dest 
) 


select * from pairing_limpio pl 
where pl.at_ds_flight_crew_code = 'MD02A'

select * from pairing
--3.834 registros

select  at_cd_leg, count(at_cd_leg) as leg from flight f 
group by at_cd_leg;
-- 2887 valores vacios sobre un total de 2899, que hacen que tengamos valores duplicados al hacer join con 
-- el resto de las tablas.

--vista

create view primer_vuelo as(
	select 
	    id,
	    num_vuelo,
	    hora_salida,
	    hora_llegada,
	    dia_convocatoria,
	    fecha_salida,
	    tipo_avion,
	    aeropuerto_salida,
	    posicional
	FROM (
	    SELECT 
	        TRIM(REPLACE(p.at_ds_flight_crew_code, '"', '')) AS id, 
	        p.at_cd_flight_number AS num_vuelo,
	        f.at_ts_std_utc AS hora_salida,
	        f.at_ts_sta_utc as hora_llegada,
	        p.at_dt_duty_assign AS dia_convocatoria,
	        a.at_cd_equipment_type AS tipo_avion,
	        f.at_cd_airport_orig as aeropuerto_salida,
	        p.at_is_dhc_flight as posicional,
	        CAST(f.at_ts_std_utc AS DATE) AS fecha_salida,
	        ROW_NUMBER() OVER (PARTITION BY TRIM(REPLACE(p.at_ds_flight_crew_code, '"', '')), CAST(f.at_ts_std_utc AS DATE) ORDER BY f.at_ts_std_utc) AS rn
	    FROM pairing_limpio p 
	    JOIN flight_limpio f 
	        ON p.at_cd_flight_number = f.at_cd_flight_number 
	        AND p.at_dt_flight_date = f.at_dt_flight_date
	        and p.at_cd_airline_code = f.at_cd_airline_code 
	        and p.at_cd_airport_orig = f.at_cd_airport_orig
	    join aircraft a 
		on f.id_aircraft::char = a.id_aircraft
	) subquery
	WHERE rn = 1
)

select * from flight f where f.at_cd_flight_number = 1940 and f.at_cd_airport_orig = 'MAD';

select distinct tipo_avion from primer_vuelo;

create view resultado as (
with resultado as(
	select 
	 		id,
		    num_vuelo,
		    hora_llegada,
		    dia_convocatoria,
		    fecha_salida,
		    tipo_avion,
		    aeropuerto_salida,
		    posicional,
			EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 AS duracion_vuelo,
		case
			WHEN aeropuerto_salida IN ('FCO', 'ORY', 'AMS') THEN 60
	        WHEN aeropuerto_salida IN ('ALC', 'MAD') AND EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 <= 180 THEN 50
	        WHEN aeropuerto_salida IN ('ALC', 'MAD') AND EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 > 180 THEN 60
	        WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 <= 180 AND (tipo_avion = '321' OR aeropuerto_salida = 'BCN') THEN 55
	        WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 > 180 AND (tipo_avion IN ('319', '320', '321') OR aeropuerto_salida = 'BCN') THEN 60
	        WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 <= 180 AND tipo_avion IN ('319', '320') THEN 45 
	        WHEN posicional THEN 45
	        ELSE 45 -- Valor por defecto si no se cumple ninguna condición
	    END AS minutos_previos_firma,
	    	hora_salida
	    	--hora_salida::timestamp - CONCAT(minutos_previos_firma, ' minutes')::interval AS hora_firma
	from primer_vuelo)
select *, hora_salida::timestamp - CONCAT(minutos_previos_firma, ' minutes')::interval AS hora_firma
from resultado
)
	
select distinct a.at_cd_equipment_type  from aircraft a ;


select 
	case when aeropuerto_salida = 'BCN' then 'BCN' 
	when aeropuerto_salida in ('FCO', 'ORY', 'AMS') then 'FCO/ORY/AMS'
	when aeropuerto_salida in ('ALC', 'MAD') then 'ALC/MAD'
	else 'Otros' end as grupo_aeropuerto,
	case when tipo_avion in ('319', '320') then 'A319/A320'
	when tipo_avion = '321' then 'A321'
	else 'Otros' end as grupo_avion,
	avg(minutos_previos_firma)
from resultado
group by grupo_aeropuerto, grupo_avion;


-- query para agrupar por avion y aeropuerto
select 
	case when tipo_avion in ('319', '320') then 'A319/A320'
	when tipo_avion = '321' then '321'
	else 'Otros' end as grupo_avion,
	case when aeropuerto_salida = 'BCN' then 'BCN' 
	when aeropuerto_salida in ('FCO', 'ORY', 'AMS') then 'FCO/ORY/AMS'
	when aeropuerto_salida in ('ALC', 'MAD') then 'ALC/MAD'
	else 'Otros' end as grupo_aeropuerto,
	avg(minutos_previos_firma)
from resultado
group by grupo_avion, grupo_aeropuerto
order by grupo_aeropuerto;


-- ejercicio 2

create view ultimo_vuelo as(
	select 
	    id,
	    num_vuelo,
	    hora_salida,
	    hora_llegada,
	    dia_convocatoria,
	    fecha_salida,
	    tipo_avion,
	    aeropuerto_salida,
	    posicional
	FROM (
	    SELECT 
	        TRIM(REPLACE(p.at_ds_flight_crew_code, '"', '')) AS id, 
	        p.at_cd_flight_number AS num_vuelo,
	        f.at_ts_std_utc AS hora_salida,
	        f.at_ts_sta_utc as hora_llegada,
	        p.at_dt_duty_assign AS dia_convocatoria,
	        a.at_cd_equipment_type AS tipo_avion,
	        f.at_cd_airport_orig as aeropuerto_salida,
	        p.at_is_dhc_flight as posicional,
	        CAST(f.at_ts_std_utc AS DATE) AS fecha_salida,
	        ROW_NUMBER() OVER (PARTITION BY TRIM(REPLACE(p.at_ds_flight_crew_code, '"', '')), CAST(f.at_ts_sta_utc AS DATE) ORDER BY f.at_ts_sta_utc desc) AS rn
	    FROM pairing_limpio p 
	    JOIN flight_limpio f 
	        ON p.at_cd_flight_number = f.at_cd_flight_number 
	        AND f.at_dt_flight_date = p.at_dt_flight_date
	    join aircraft a 
		on f.id_aircraft::char = a.id_aircraft
	) subquery
	WHERE rn = 1
)


--calculo fdp pairing
create view horas_pairing as (
	select p.id, p.hora_firma, u.hora_llegada, (u.hora_llegada::timestamp - p.hora_firma::timestamp) as fdp_pairing
	from resultado p
	join ultimo_vuelo u
	on p.id = u.id and p.num_vuelo = u.num_vuelo and p.dia_convocatoria = u.dia_convocatoria
);

select * from horas_pairing ;

select * from fdp_limit;

select * from variation_zone
order by at_cd_airport ;


-- unpivot tabla fdp_limit:
create view fdp_v2 as (
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '1' AS saltos, f.at_tm_sectors_1 
	FROM fdp_limit f 
	UNION ALL 
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '2' AS saltos, f.at_tm_sectors_2 
	FROM fdp_limit f 
	UNION ALL 
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '3' AS saltos, f.at_tm_sectors_3 
	FROM fdp_limit f 
	UNION ALL 
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '4' AS saltos, f.at_tm_sectors_4 
	FROM fdp_limit f 
	UNION ALL 
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '5' AS saltos, f.at_tm_sectors_5 
	FROM fdp_limit f 
	UNION ALL 
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '6' AS saltos, f.at_tm_sectors_6 
	FROM fdp_limit f 
	UNION ALL 
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '7' AS saltos, f.at_tm_sectors_7 
	FROM fdp_limit f 
	UNION ALL 
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '8' AS saltos, f.at_tm_sectors_8 
	FROM fdp_limit f 
	UNION ALL 
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '9' AS saltos, f.at_tm_sectors_9 
	FROM fdp_limit f 
	UNION ALL 
	SELECT RIGHT(f.at_tm_initial_time, 8) AS at_tm_initial_time, f.at_tm_final_time, '10' AS saltos, f.at_tm_sectors_10 
	FROM fdp_limit f
);

select * from fdp_limit fl where at_tm_initial_time like '%06:00:00';


create view fdp_limit_v2 as (
	SELECT RIGHT(fl.at_tm_initial_time, 8) AS ultimos_8_caracteres
	FROM fdp_limit fl
)

UPDATE fdp_limit
SET at_tm_initial_time = REPLACE(at_tm_initial_time, '%06:00:00', '06:00:00')
WHERE at_tm_initial_time LIKE '%06:00:00';


select distinct p.at_ds_flight_crew_code, p.at_dt_duty_assign, p.at_cd_flight_number from pairing_limpio p
where TRIM(REPLACE(p.at_ds_flight_crew_code, '"', '')) = 'MD02A' ;
-- sacar el count de pairing


 -- CREO UNA VISTA DE SALTOS con id y convocatorias unicas -- NO REPETIDOS! 
create view saltos as (
		SELECT 
	         TRIM(REPLACE(p.at_ds_flight_crew_code, '"', '')) AS id, 
	        p.at_dt_duty_assign AS dia_convocatoria,
			count(TRIM(REPLACE(p.at_ds_flight_crew_code, '"', ''))) as saltos
	    FROM pairing_limpio p 
	    JOIN flight_limpio f 
			ON p.at_cd_flight_number = f.at_cd_flight_number 
	        AND p.at_dt_flight_date = f.at_dt_flight_date
	        and p.at_cd_airline_code = f.at_cd_airline_code 
	        and p.at_cd_airport_orig = f.at_cd_airport_orig
	    join aircraft a 
		on f.id_aircraft::char = a.id_aircraft
		group by 
			TRIM(REPLACE(p.at_ds_flight_crew_code, '"', '')), 
	        p.at_dt_duty_assign
);

--- hacer join entre resultados y variation zone
create view hora_firma_local as (
	select 
		r.id,
		r.dia_convocatoria,
		r.hora_firma::timestamp + CONCAT(vz.at_min_variation , ' minutes')::interval AS hora_firma_local
	from 
		resultado r
	left join 
		variation_zone vz 
	on 
		r.aeropuerto_salida = vz.at_cd_airport and r.hora_firma between vz.at_dt_start_date_utc and vz.at_dt_end_date_utc
);

create view hora_firma_local_v2 as (
	select *,
		 CAST(
	            TO_CHAR(EXTRACT(HOUR FROM h.hora_firma_local), 'FM00') || ':' || 
	            TO_CHAR(EXTRACT(MINUTE FROM h.hora_firma_local), 'FM00') || ':' || 
	            TO_CHAR(EXTRACT(SECOND FROM h.hora_firma_local), 'FM00') 
	        AS TIME) AS hora_firma_completa_time
	from hora_firma_local h
);

select * from hora_firma_local_v2


-- falta la variation zone para el aeropuerto LED
select distinct at_cd_airport  from variation_zone vz where at_cd_airport like '%LE%';
--no da ningun valor


--
create view fdp_maximo as (
	select s.*, h.hora_firma_local, h.hora_firma_completa_time, f.at_tm_sectors_1 as fdp_maximo
	from saltos s 
	left join hora_firma_local_v2 h
	on s.id = h.id and s.dia_convocatoria = h.dia_convocatoria
	left join fdp_v2 f
	on ((f.at_tm_initial_time::time < f.at_tm_final_time::time AND h.hora_firma_local::time BETWEEN f.at_tm_initial_time::time AND f.at_tm_final_time::time) and s.saltos::int = f.saltos::int) 
	    OR
	    (f.at_tm_initial_time::time > f.at_tm_final_time::time AND (h.hora_firma_local::time >= f.at_tm_initial_time::time OR h.hora_firma_local::time <= f.at_tm_final_time::time))
	and s.saltos = f.saltos::int
);


