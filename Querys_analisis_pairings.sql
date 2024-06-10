							--- CHALLENGE SQL VUELING ACADEMY ------


/*
 	EJERCICIO 1:
 	
	¿A qué hora debe firmar cada tripulación por pairing y día? 
	
	¿Cómo afecta la elección del aeropuerto de salida en la hora de firma requerida? Compara las diferencias de 
	horas de firma para varios aeropuertos comunes y diferentes tipos de aviones. 

*/
							
							
						
							
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
--3834 registros


/* limpiar duplicados flight:
 	Notamos que hay registros duplicados que nos sesgan los resultados
*/

select * from flight f ;
--2899 registros

--- esto nos devuelve at_cd_leg = 'A' que significa que tiene el mismo aeropuerto de salida y llegada

select * from flight f where f.at_cd_airport_orig = f.at_cd_airport_dest 

--Notamos que los vuelos que tienen el mismo aeropuerto de origen y de llegada, tienen asignado otro vuelo a la misma hora para el pairing,
--esto haria que al contar los saltos de cada pairing aparezca un valor de mas para esos casos, lo que seria un error a la hora de definir 
--las horas que puede trabajar en ese dia. Decidimos quitar estos casos.

-- limpiamos duplicados:
create view flight_limpio as (
	select * 
		from flight f
	except
	select * 
		from flight f 
	where f.at_cd_airport_orig = f.at_cd_airport_dest 
) 
--2894 registros



-- Obtener el primer vuelo para cada pairing por dia de asignación:

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
	FROM (       -- mediante el select unimos cada pairing con la info del vuelo, mediante una particion, luego ordenamos de primero a ultimo
				 -- los vuelos dentro de un mismo dia de asignacion, asi obtenemos el primer vuelo de cada dia
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
	WHERE rn = 1    -- filtramos por el primer valor, es decir, el primer vuelo del día.
)

/*
Añadirle a la tabla la hora en local. 
*/


/*
 RESPONDIENDO A LA PREGUNTA:
 
  ¿A qué hora debe firmar cada tripulación por pairing y día? 
 
 Mediante esta vista, calculamos los minutos previos a la hora de salida del primer avion, este resultado nos ayudará a determinar la hora
 exacta en que la tripulación tiene que firmar. Estos minutos estaran definidos por la condicion:
 		
 		case
			WHEN aeropuerto_salida IN ('FCO', 'ORY', 'AMS') THEN 60
	        WHEN aeropuerto_salida IN ('ALC', 'MAD') AND EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 <= 180 THEN 50
	        WHEN aeropuerto_salida IN ('ALC', 'MAD') AND EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 > 180 THEN 60
	        WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 <= 180 AND (tipo_avion = '321' OR aeropuerto_salida = 'BCN') THEN 55
	        WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 > 180 AND (tipo_avion IN ('319', '320', '321') OR aeropuerto_salida = 'BCN') THEN 60
	        WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 <= 180 AND tipo_avion IN ('319', '320') THEN 45 
	        WHEN posicional THEN 45
	        ELSE 45 
	    END AS minutos_previos_firma
	    
Al no contar con información de los minutos previos necesarios, para los casos que no cumplen las condiciones dadas, determinamos que serán 45 minutos.

Una vez obtuvimos los minutos de antelación, definimos la hora exacta de firma mediante:

hora_salida::timestamp - CONCAT(minutos_previos_firma, ' minutes')::interval AS hora_firma
	    
 */

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
			-- la condicion que prevalece es si el aeropiuerto es FCO, ORY o AMS
			WHEN aeropuerto_salida IN ('FCO', 'ORY', 'AMS') THEN 60
			-- la siguiente condicion es si es BCN o A321 y la duracion del vuelo menor o mayor a 3 hs
			WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 <= 180 AND (tipo_avion = '321' OR aeropuerto_salida = 'BCN') THEN 55
			WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 > 180 AND (tipo_avion = '321' OR aeropuerto_salida = 'BCN') THEN 60
			-- la siguiente condicion es si es ALC o MAD
	        WHEN aeropuerto_salida IN ('ALC', 'MAD') AND EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 <= 180 THEN 50
	        WHEN aeropuerto_salida IN ('ALC', 'MAD') AND EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 > 180 THEN 60
	        -- La siguiente condicion es si es A319 o A320 y lka duracion del vuelo mayor o menor a 3 hs
	        WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 <= 180 AND tipo_avion IN ('319', '320') THEN 45 
	        WHEN EXTRACT(EPOCH FROM (hora_llegada - hora_salida)) / 60 > 180 AND tipo_avion IN ('319', '320') THEN 60 
	        WHEN posicional THEN 45
	        ELSE 45 -- Valor por defecto si no se cumple ninguna condición
	    END AS minutos_previos_firma,
	    	hora_salida
	from primer_vuelo)
select *, hora_salida::timestamp - CONCAT(minutos_previos_firma, ' minutes')::interval AS hora_firma  --restando los minutos previos a la hora de salida del primer vuelo obtenemos la hora exacta en la que deben firmar
from resultado
)


/*
 RESPONDIENDO A LA PREGUNTA:
 
	¿Cómo afecta la elección del aeropuerto de salida en la hora de firma requerida? Compara las diferencias de 
	horas de firma para varios aeropuertos comunes y diferentes tipos de aviones.

 */

-- query para agrupar por avion y aeropuerto
create view minutos_por_avion_y_aeropuerto as (
	select 
		case when tipo_avion in ('319', '320') then 'A319/A320'
		when tipo_avion = '321' then '321'
		else 'Otros' end as grupo_avion,
		case when aeropuerto_salida = 'BCN' then 'BCN' 
		when aeropuerto_salida in ('FCO', 'ORY', 'AMS') then 'FCO/ORY/AMS'
		when aeropuerto_salida in ('ALC', 'MAD') then 'ALC/MAD'
		else 'Otros' end as grupo_aeropuerto,
		round(avg(minutos_previos_firma), 2) as minutos_previos_promedio
	from resultado
	group by grupo_avion, grupo_aeropuerto
	order by grupo_aeropuerto
);



/*
 	EJERCICIO 2:
 	
 	¿Cuál es el FDP y FDP Máximo para cada pairing? 
 	
	¿Cómo se distribuyen los pairings a lo largo de las distintas bases y tipos de avión?
 	
*/

/*
	Existe un límite máximo permitido de horas de servicio diarias, conocido como Flight 
	Duty Period Maximum (FDP Máximo). El Flight Duty Period (FDP) se refiere al periodo de tiempo que empieza desde la 
	hora de firma para el primer vuelo y termina cuando el último vuelo del día se detiene, scheduled time arrival (STA). 
	Para determinar este FDP y garantizar que no se exceda el FDP Máximo, es necesario tener en cuenta la hora de firma 
	y el número de sectores (vuelos) que el tripulante opera dentro de cada Pairing.
 
 */

/*

	Ya tenemos la hora de firma del primer vuelo, ahora necesitamos saber la hora de llegada del último vuelo, esto determinara las horas trabajadas por cada pairing.
	
	Obtener la hora del último vuelo:
	
	Cómo hicimos anteriormente para determinar el primer vuelo del dia, hacemos una partición para cada crew code y ordenamos los vuelos por día de asignación
	desde el ultimo al primero, luego nos quedamos con el primer valor de ese listado, es decir, el último vuelo para cada turno.

*/

create view ultimo_vuelo as(
	select   -- seleccionamos solo la primer fila del select del from, que corresponde al último vuelo para cada pairing por día de convocatoria
	    id,
	    num_vuelo,
	    hora_salida,
	    hora_llegada,
	    dia_convocatoria,
	    fecha_salida,
	    tipo_avion,
	    aeropuerto_salida,
	    posicional
	FROM (    -- El primer select agrupa por id y por orden descendente los pairing segun la hora de llegada.
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
);

/*
 
 	En la vista resultado tenemos información de la hora de firma para cada pairing por día. En la vista ultimo_vuelo tenemos la hora de llegada para el último vuelo
 	por pairing para ese mismo día. Debemos unirlas para poder calcular las horas trabajadas (FDP)
 
*/

-- la columna fdp_pairing determinará las horas trabajadas por pairing y por día
create view horas_pairing as (
	select p.id, p.dia_convocatoria, p.hora_firma, u.hora_llegada, (u.hora_llegada::timestamp - p.hora_firma::timestamp) as fdp_pairing
	from resultado p
	join ultimo_vuelo u
	on p.id = u.id and p.dia_convocatoria = u.dia_convocatoria
);

/*
 Unpivoteamos la tabla fdp_limit y tomamos los 8 últimos carácteres de la columna initial time para solucionar el problema de los caracteres ocultos,
 esta tabla nos dice cuantas horas puede trabajar cada pairing en funcion de la hora de firma y cantidad de saltos.
*/

CREATE VIEW fdp_v2 AS 
(
    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '1' AS saltos, 
        f.at_tm_sectors_1 AS at_tm_sectors
    FROM fdp_limit f 

    UNION ALL 

    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '2' AS saltos, 
        f.at_tm_sectors_2 AS at_tm_sectors
    FROM fdp_limit f 

    UNION ALL 

    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '3' AS saltos, 
        f.at_tm_sectors_3 AS at_tm_sectors
    FROM fdp_limit f 

    UNION ALL 

    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '4' AS saltos, 
        f.at_tm_sectors_4 AS at_tm_sectors
    FROM fdp_limit f 

    UNION ALL 

    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '5' AS saltos, 
        f.at_tm_sectors_5 AS at_tm_sectors
    FROM fdp_limit f 

    UNION ALL 

    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '6' AS saltos, 
        f.at_tm_sectors_6 AS at_tm_sectors
    FROM fdp_limit f 

    UNION ALL 

    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '7' AS saltos, 
        f.at_tm_sectors_7 AS at_tm_sectors
    FROM fdp_limit f 

    UNION ALL 

    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '8' AS saltos, 
        f.at_tm_sectors_8 AS at_tm_sectors
    FROM fdp_limit f 

    UNION ALL 

    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '9' AS saltos, 
        f.at_tm_sectors_9 AS at_tm_sectors
    FROM fdp_limit f 

    UNION ALL 

    SELECT 
        RIGHT(f.at_tm_initial_time::text, 8) AS at_tm_initial_time, 
        f.at_tm_final_time, 
        '10' AS saltos, 
        f.at_tm_sectors_10 AS at_tm_sectors
    FROM fdp_limit f
);

/*
  
 Mediante la vista saltos, obtenemos la sumatoria de saltos de cada pairing por cada dia de convocatoria
 
 */

CREATE VIEW saltos AS 
(
    SELECT 
        TRIM(REPLACE(p.at_ds_flight_crew_code, '"', '')) AS id,   -- Solucionamos valores que tienen carácteres no deseados.
        p.at_dt_duty_assign AS dia_convocatoria,
        COUNT(*) AS saltos
    FROM pairing_limpio p 
    JOIN flight_limpio f 
        ON p.at_cd_flight_number = f.at_cd_flight_number 
        AND p.at_dt_flight_date = f.at_dt_flight_date
        AND p.at_cd_airline_code = f.at_cd_airline_code 
        AND p.at_cd_airport_orig = f.at_cd_airport_orig
    JOIN aircraft a 
        ON f.id_aircraft::char = a.id_aircraft
    GROUP BY 
        TRIM(REPLACE(p.at_ds_flight_crew_code, '"', '')), 
        p.at_dt_duty_assign
);

/*
 
 Con la vista hora_firma_local, a través de la tabla variation_zone ajustamos las horas de firma de la tabla resultado, que
 están en hora UTC, para que estén en hora local del aeropuerto de salida, que necesitamos para saber en que rango de fdp máximo
 esta cada pairing.
 
 */


CREATE VIEW hora_firma_local AS 
(
    SELECT 
        r.id,
        r.dia_convocatoria,
        r.hora_firma::timestamp + (vz.at_min_variation || ' minutes')::interval AS hora_firma_local
    FROM resultado r
    LEFT JOIN variation_zone vz 
        ON r.aeropuerto_salida = vz.at_cd_airport 
        AND r.hora_firma BETWEEN vz.at_dt_start_date_utc AND vz.at_dt_end_date_utc
);

-- mejoramos el tipo de dato para la columna de hora de firma

CREATE VIEW hora_firma_local_v2 AS 
(
    SELECT *,
        CAST(
            TO_CHAR(EXTRACT(HOUR FROM h.hora_firma_local), 'FM00') || ':' || 
            TO_CHAR(EXTRACT(MINUTE FROM h.hora_firma_local), 'FM00') || ':' || 
            TO_CHAR(EXTRACT(SECOND FROM h.hora_firma_local), 'FM00') 
        AS TIME) AS hora_firma_completa_time
    FROM hora_firma_local h
);

/*
 
 Haciendo joins con las tablas obtenidas, podemos determinar el fdp máximo para cada pairing
 
 */


CREATE VIEW fdp_maximo AS 
(
    SELECT 
        s.*, 
        h.hora_firma_local, 
        h.hora_firma_completa_time, 
        f.at_tm_sectors::time AS fdp_maximo
    FROM saltos s 
    LEFT JOIN hora_firma_local_v2 h
        ON s.id = h.id 
        AND s.dia_convocatoria = h.dia_convocatoria
    LEFT JOIN fdp_v2 f
        ON (
            (
                f.at_tm_initial_time::time < f.at_tm_final_time::time 
                AND h.hora_firma_local::time BETWEEN f.at_tm_initial_time::time AND f.at_tm_final_time::time
            ) 
            OR
            (
                f.at_tm_initial_time::time > f.at_tm_final_time::time 
                AND (h.hora_firma_local::time >= f.at_tm_initial_time::time OR h.hora_firma_local::time <= f.at_tm_final_time::time)
            )
        )
        AND s.saltos::int = f.saltos::int
);

/*
 
PREGUNTA:
¿Cómo se distribuyen los pairings a lo largo de las distintas bases y tipos de avión? 

Los resultados muestran que la mayoria de los pairings salen desde BCN, la otra característica relevante es que la mayoría corresponde a 
vuelos donde el tipo de avion es A319 o A320.

*/

create view distribucion_pairing as (
WITH TotalPairings AS (
    SELECT COUNT(*) AS total_pairing
    FROM resultado r
    JOIN horas_pairing hp 
    ON r.id = hp.id AND r.dia_convocatoria = hp.dia_convocatoria
)
SELECT 
    CASE 
        WHEN aeropuerto_salida = 'BCN' THEN 'BCN'
        WHEN aeropuerto_salida IN ('FCO', 'ORY', 'AMS') THEN 'FCO/ORY/AMS'
        WHEN aeropuerto_salida IN ('ALC', 'MAD') THEN 'ALC/MAD'
        ELSE 'Otros' 
    END AS grupo_aeropuerto,
    CASE 
        WHEN tipo_avion IN ('319', '320') THEN 'A319/A320'
        WHEN tipo_avion = '321' THEN '321'
        ELSE 'Otros' 
    END AS grupo_avion,
    COUNT(*) AS cantidad_pairing,
    round(COUNT(*) * 100.0 / (SELECT total_pairing FROM TotalPairings), 2) AS porcentaje_pairing,
    AVG(hp.fdp_pairing) AS fdp_promedio
FROM resultado r
JOIN horas_pairing hp 
ON r.id = hp.id AND r.dia_convocatoria = hp.dia_convocatoria 
GROUP BY grupo_aeropuerto, grupo_avion
ORDER BY grupo_aeropuerto
);


