-- La siguiente línea debe ejecutarse solo si usas Oracle 18c
ALTER SESSION SET "_ORACLE_SCRIPT"=true;

-- Crear el usuario
CREATE USER EA1_1_MDY_FOL IDENTIFIED BY "Oracle12345@"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;

-- Asignar cuota ilimitada en el tablespace USERS
ALTER USER EA1_1_MDY_FOL QUOTA UNLIMITED ON USERS;

-- Otorgar permisos de conexión y recursos
GRANT RESOURCE, CONNECT TO EA1_1_MDY_FOL;

-- Establecer roles predeterminados
ALTER USER EA1_1_MDY_FOL DEFAULT ROLE RESOURCE, CONNECT;

-- Verificar si el usuario fue creado correctamente
SELECT username FROM dba_users WHERE username = 'EA1_1_MDY_FOL';

