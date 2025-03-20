
-- 1. Función que retorna la cantidad total de atenciones en un período específico
CREATE OR REPLACE FUNCTION fn_total_atenciones(p_periodo IN VARCHAR2) RETURN NUMBER IS
    v_total NUMBER := 0;
    v_inicio_periodo DATE;
    v_fin_periodo DATE;
BEGIN
    -- Convertir el período a rango de fechas
    v_inicio_periodo := TO_DATE(p_periodo, 'MM-YYYY');
    v_fin_periodo := LAST_DAY(v_inicio_periodo);

    SELECT COUNT(*)
    INTO v_total
    FROM ATENCION
    WHERE fecha_atencion BETWEEN v_inicio_periodo AND v_fin_periodo;

    RETURN v_total;
END;
/

-- 2. Función que retorna la cantidad de atenciones de una especialidad en un período específico
CREATE OR REPLACE FUNCTION fn_atenciones_especialidad(p_esp_id IN NUMBER, p_periodo IN VARCHAR2) RETURN NUMBER IS
    v_total NUMBER := 0;
    v_inicio_periodo DATE;
    v_fin_periodo DATE;
BEGIN
    v_inicio_periodo := TO_DATE(p_periodo, 'MM-YYYY');
    v_fin_periodo := LAST_DAY(v_inicio_periodo);

    SELECT COUNT(*)
    INTO v_total
    FROM ATENCION
    WHERE esp_id = p_esp_id
    AND fecha_atencion BETWEEN v_inicio_periodo AND v_fin_periodo;

    RETURN v_total;
END;
/

-- 3. Función que retorna el costo promedio de atenciones de una especialidad en un período específico
CREATE OR REPLACE FUNCTION fn_costo_promedio_especialidad(p_esp_id IN NUMBER, p_periodo IN VARCHAR2) RETURN NUMBER IS
    v_promedio NUMBER := 0;
    v_inicio_periodo DATE;
    v_fin_periodo DATE;
BEGIN
    v_inicio_periodo := TO_DATE(p_periodo, 'MM-YYYY');
    v_fin_periodo := LAST_DAY(v_inicio_periodo);

    SELECT NVL(AVG(costo), 0)
    INTO v_promedio
    FROM ATENCION
    WHERE esp_id = p_esp_id
    AND fecha_atencion BETWEEN v_inicio_periodo AND v_fin_periodo;

    RETURN v_promedio;
END;
/

-- 4. Función que genera un informe de atenciones por especialidad y retorna un valor de verdad
CREATE OR REPLACE FUNCTION fn_informe_atenciones(p_periodo IN VARCHAR2) RETURN BOOLEAN IS
    v_existen_registros BOOLEAN := FALSE;
    v_total_atenciones NUMBER := fn_total_atenciones(p_periodo);
    v_cantidad_atenciones NUMBER;
    v_costo_promedio NUMBER;
    v_porcentaje NUMBER;

    -- Cursor para obtener los médicos por especialidad
    CURSOR c_medicos(p_esp_id NUMBER, p_periodo VARCHAR2) IS
        SELECT 
            UTL_RAW.CAST_TO_VARCHAR2(UTL_I18N.STRING_TO_RAW(med.pnombre || ' ' || med.snombre || ' ' || med.apaterno || ' ' || med.amaterno, 'AL32UTF8')) AS NombreDoctor,
            med.med_run || '-' || med.dv_run AS RutDoctor,
            esp.esp_id AS IdEspecialidad
        FROM medico med
        JOIN ESPECIALIDAD_MEDICO esp ON med.med_run = esp.med_run
        WHERE esp.esp_id = p_esp_id
        AND TO_CHAR(med.fecha_contrato, 'MM-YYYY') = p_periodo;

BEGIN
    IF v_total_atenciones = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Advertencia: No se encontraron registros de atenciones en el período especificado.');
        RETURN FALSE;
    END IF;

    FOR rec IN (SELECT esp_id, nombre FROM ESPECIALIDAD) LOOP
        v_cantidad_atenciones := fn_atenciones_especialidad(rec.esp_id, p_periodo);
        v_costo_promedio := fn_costo_promedio_especialidad(rec.esp_id, p_periodo);

        IF v_total_atenciones > 0 THEN
            v_porcentaje := (v_cantidad_atenciones / v_total_atenciones) * 100;
        ELSE
            v_porcentaje := 0;
        END IF;

        IF v_cantidad_atenciones > 0 THEN
            v_existen_registros := TRUE;
        END IF;

        -- Imprimir información de la especialidad
        DBMS_OUTPUT.PUT_LINE('+++++++++++++++++++++++++++++++++++++');
        DBMS_OUTPUT.PUT_LINE(rec.nombre);
        DBMS_OUTPUT.PUT_LINE('----------- Costo promedio   : $' || TO_CHAR(v_costo_promedio, 'FM999G999G999'));
        DBMS_OUTPUT.PUT_LINE('----------- Total atenciones : ' || v_cantidad_atenciones);
        DBMS_OUTPUT.PUT_LINE('----------- % del total    :'||TO_CHAR(v_porcentaje, '990.99') || '%');

        -- Listar médicos de la especialidad en el período
        FOR med_rec IN c_medicos(rec.esp_id, p_periodo) LOOP
            DBMS_OUTPUT.PUT_LINE('  - Doctor: ' || med_rec.NombreDoctor || ' (RUT: ' || med_rec.RutDoctor || ')');
        END LOOP;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('+++++++++++++++++++++++++++++++++++++');
    DBMS_OUTPUT.PUT_LINE('CANTIDAD ATENCIONES DEL PERIODO: ' || v_total_atenciones);
    DBMS_OUTPUT.PUT_LINE('Listado emitido');

    RETURN v_existen_registros;
END;
/

-- 5. Bloque PL/SQL para llamar a la función almacenada y mostrar mensaje de éxito o fracaso
SET SERVEROUTPUT ON;

DECLARE
    v_resultado BOOLEAN;
BEGIN
    v_resultado := fn_informe_atenciones('06-2024');
    
    IF v_resultado THEN
        DBMS_OUTPUT.PUT_LINE('Éxito: Informe generado con éxito.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Advertencia: No se encontraron registros en el período especificado.');
    END IF;
END;


