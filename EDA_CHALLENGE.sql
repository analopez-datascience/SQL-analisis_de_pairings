select*
from aircraft a --483

select*
from pairing p --3834

select*
from fdp_limit fl --13

select*
from flight f --2899

select*
from variation_zone vz --25591


----------------------------------------------
-- RANGO DE FECHAS
----------------------------------------------
  
SELECT 
  
    MIN(at_dt_flight_date) AS minimo,
    MAX(at_dt_flight_date) AS maximo
   
FROM pairing p ;

--Estamos observando solo los dias 25, 26, 27, 28 y 29 de octubre de 2019

SELECT 
    COUNT(DISTINCT AT_DT_FLIGHT_DATE) AS total_dias
FROM 
    Pairing;
-- Vamos a analizar el comportamiento de los pairing estos cinco días
   

SELECT 
    AT_DT_FLIGHT_DATE,
    TO_CHAR(AT_DT_FLIGHT_DATE, 'Day') AS dia_semana
FROM 
    Pairing;

-- El periodo a analizas es de viernes a martes

-----------------------------------------------
-- ANÁLISIS VALORES NULOS
-----------------------------------------------
-- Podemos observar que ninugna de nuestras tablas contiene valore nulos. 

-- AIRCRAFT

SELECT 
    COUNT(*) - COUNT(ID_AIRCRAFT) AS valores_nulos_ID_AIRCRAFT,
    COUNT(*) - COUNT(AT_CD_EQUIPMENT_TYPE) AS valores_nulos_AT_CD_EQUIPMENT_TYPE,
    COUNT(*) - COUNT(MT_SEATS) AS valores_nulos_MT_SEATS,
    COUNT(*) - COUNT(ID_SOURCE_AC) AS valores_nulos_ID_SOURCE_AC,
    COUNT(*) - COUNT(AT_CD_AIRLINE_CODE) AS valores_nulos_AT_CD_AIRLINE_CODE
FROM Aircraft;


-- FDP_LIMIT

SELECT 
    COUNT(*) - COUNT(AT_TM_INITIAL_TIME) AS valores_nulos_AT_TM_INITIAL_TIME,
    COUNT(*) - COUNT(AT_TM_FINAL_TIME) AS valores_nulos_AT_TM_FINAL_TIME,
    COUNT(*) - COUNT(AT_SECTORS_1) AS valores_nulos_AT_SECTORS_1,
    COUNT(*) - COUNT(AT_TM_SECTORS_1) AS valores_nulos_AT_TM_SECTORS_1,
    COUNT(*) - COUNT(AT_SECTORS_2) AS valores_nulos_AT_SECTORS_2,
    COUNT(*) - COUNT(AT_TM_SECTORS_2) AS valores_nulos_AT_TM_SECTORS_2,
    COUNT(*) - COUNT(AT_SECTORS_3) AS valores_nulos_AT_SECTORS_3,
    COUNT(*) - COUNT(AT_TM_SECTORS_3) AS valores_nulos_AT_TM_SECTORS_3,
    COUNT(*) - COUNT(AT_SECTORS_4) AS valores_nulos_AT_SECTORS_4,
    COUNT(*) - COUNT(AT_TM_SECTORS_4) AS valores_nulos_AT_TM_SECTORS_4,
    COUNT(*) - COUNT(AT_SECTORS_5) AS valores_nulos_AT_SECTORS_5,
    COUNT(*) - COUNT(AT_TM_SECTORS_5) AS valores_nulos_AT_TM_SECTORS_5,
    COUNT(*) - COUNT(AT_SECTORS_6) AS valores_nulos_AT_SECTORS_6,
    COUNT(*) - COUNT(AT_TM_SECTORS_6) AS valores_nulos_AT_TM_SECTORS_6,
    COUNT(*) - COUNT(AT_SECTORS_7) AS valores_nulos_AT_SECTORS_7,
    COUNT(*) - COUNT(AT_TM_SECTORS_7) AS valores_nulos_AT_TM_SECTORS_7,
    COUNT(*) - COUNT(AT_SECTORS_8) AS valores_nulos_AT_SECTORS_8,
    COUNT(*) - COUNT(AT_TM_SECTORS_8) AS valores_nulos_AT_TM_SECTORS_8,
    COUNT(*) - COUNT(AT_SECTORS_9) AS valores_nulos_AT_SECTORS_9,
    COUNT(*) - COUNT(AT_TM_SECTORS_9) AS valores_nulos_AT_TM_SECTORS_9,
    COUNT(*) - COUNT(AT_SECTORS_10) AS valores_nulos_AT_SECTORS_10,
    COUNT(*) - COUNT(AT_TM_SECTORS_10) AS valores_nulos_AT_TM_SECTORS_10
FROM FDP_Limit;



-- FLIGHT

SELECT 
    COUNT(*) - COUNT(AT_CD_FLIGHT_NUMBER) AS valores_nulos_AT_CD_FLIGHT_NUMBER,
    COUNT(*) - COUNT(AT_CD_LEG) AS valores_nulos_AT_CD_LEG,
    COUNT(*) - COUNT(AT_DT_FLIGHT_DATE) AS valores_nulos_AT_DT_FLIGHT_DATE,
    COUNT(*) - COUNT(AT_CD_AIRLINE_CODE) AS valores_nulos_AT_CD_AIRLINE_CODE,
    COUNT(*) - COUNT(AT_CD_AIRPORT_ORIG) AS valores_nulos_AT_CD_AIRPORT_ORIG,
    COUNT(*) - COUNT(AT_CD_AIRPORT_DEST) AS valores_nulos_AT_CD_AIRPORT_DEST,
    COUNT(*) - COUNT(AT_TS_STD_UTC) AS valores_nulos_AT_TS_STD_UTC,
    COUNT(*) - COUNT(AT_TS_STA_UTC) AS valores_nulos_AT_TS_STA_UTC,
    COUNT(*) - COUNT(ID_AIRCRAFT) AS valores_nulos_ID_AIRCRAFT
FROM Flight;


-- PAIRING

SELECT 
    COUNT(*) - COUNT(at_ds_flight_crew_code) AS valores_nulos_at_ds_flight_crew_code,
    COUNT(*) - COUNT(at_dt_duty_assign) AS valores_nulos_at_dt_duty_assign,
    COUNT(*) - COUNT(at_cd_route_category) AS valores_nulos_at_cd_route_category,
    COUNT(*) - COUNT(at_cd_flight_number) AS valores_nulos_at_cd_flight_number,
    COUNT(*) - COUNT(at_cd_leg) AS valores_nulos_at_cd_leg,
    COUNT(*) - COUNT(at_dt_flight_date) AS valores_nulos_at_dt_flight_date,
    COUNT(*) - COUNT(at_cd_airline_code) AS valores_nulos_at_cd_airline_code,
    COUNT(*) - COUNT(at_cd_airport_orig) AS valores_nulos_at_cd_airport_orig,
    COUNT(*) - COUNT(at_is_dhc_flight) AS valores_nulos_at_is_dhc_flight
FROM pairing;

-- VARIATION_ZONE

SELECT 
    COUNT(*) - COUNT(AT_CD_AIRPORT) AS valores_nulos_AT_CD_AIRPORT,
    COUNT(*) - COUNT(AT_DT_START_DATE_UTC) AS valores_nulos_AT_DT_START_DATE_UTC,
    COUNT(*) - COUNT(AT_DT_END_DATE_UTC) AS valores_nulos_AT_DT_END_DATE_UTC,
    COUNT(*) - COUNT(AT_MIN_VARIATION) AS valores_nulos_AT_MIN_VARIATION
FROM Variation_Zone;


---------- Análsis varios

-- distribución de vuelos por categoria

SELECT 
    AT_CD_ROUTE_CATEGORY,
    COUNT(*) AS num_vuelos
FROM 
    Pairing
GROUP BY 
    AT_CD_ROUTE_CATEGORY
ORDER BY 
    num_vuelos DESC;
   
-- número de vuelos por aeropuerto de salida
   
SELECT 
    AT_CD_AIRPORT_ORIG,
    COUNT(*) AS num_vuelos
FROM 
    Pairing
GROUP BY 
    AT_CD_AIRPORT_ORIG
ORDER BY 
    num_vuelos DESC;

-- aeropuertos de origen 
   
SELECT 
    at_cd_airport_orig,
    COUNT(*) as aeropuertos_distintos
FROM 
    Pairing
GROUP BY 
    at_cd_airport_orig
ORDER BY 
    aeropuertos_distintos DESC;
   
-- número de vuelos por aerolínea

SELECT 
    AT_CD_AIRLINE_CODE,
    COUNT(*) AS num_vuelos
FROM 
    Pairing
GROUP BY 
    AT_CD_AIRLINE_CODE
ORDER BY 
    num_vuelos DESC;

   
-- frecuencia por tipología de vuelo

SELECT 
    AT_CD_LEG,
    COUNT(*) AS num_vuelos
FROM 
    Pairing
GROUP BY 
    AT_CD_LEG
ORDER BY 
    num_vuelos DESC;

   
-- número de vuelos por día de la semana

SELECT 
    TO_CHAR(AT_DT_FLIGHT_DATE, 'Day') AS dia_semana,
    COUNT(*) AS num_vuelos
FROM 
    Pairing
GROUP BY 
    TO_CHAR(AT_DT_FLIGHT_DATE, 'Day')
ORDER BY 
    num_vuelos DESC;
   
-- aquí podríamos calcular el porcentaje significativo de número de vuelos durante el fin de semana respecto a la semana
   

-- posicionales u operacionales
   
SELECT 
    AT_IS_DHC_FLIGHT,
    COUNT(*) AS num_vuelos
FROM 
    Pairing
GROUP BY 
    AT_IS_DHC_FLIGHT;
   
--Limpieza de duplicados 
   


SELECT 
    SUM(CASE WHEN columna1 IS NULL THEN 1 ELSE 0 END) AS columna1_nulos,
    SUM(CASE WHEN columna2 IS NULL THEN 1 ELSE 0 END) AS columna2_nulos,
    SUM(CASE WHEN columna3 IS NULL THEN 1 ELSE 0 END) AS columna3_nulos,
    SUM(CASE WHEN columna4 IS NULL THEN 1 ELSE 0 END) AS columna4_nulos
FROM 
    clientes;




