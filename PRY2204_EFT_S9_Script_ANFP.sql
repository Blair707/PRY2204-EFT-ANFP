--   0. LIMPIEZA (opcional: permit ejecutar el script desde cero)
BEGIN
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE "' || t.table_name || '" CASCADE CONSTRAINTS';
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name = 'SEQ_CLUB_FUTBOL') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/

-- 1. SECUENCIA
      -- Código de CLUB_FUTBOL: comienza en 703 y se incrementa de 4 en 4
CREATE SEQUENCE SEQ_CLUB_FUTBOL
  START WITH 703
  INCREMENT BY 4
  NOCACHE
  NOCYCLE;

-- 2. CREACIÓN DE TABLAS (en orden de dependencia)
-- Solo se declaran las PK y los valores por defecto; el resto de las
-- restricciones (FK, UN, CK) se agregan en la sección 3 mediante ALTER TABLE.


-- Tablas sin claves foráneas
CREATE TABLE REGION (
  id_region   NUMBER(2)     NOT NULL,
  nombre      VARCHAR2(40)  NOT NULL,
  CONSTRAINT REGION_PK PRIMARY KEY (id_region)
);

CREATE TABLE ASOCIACION (
  id_asociacion      NUMBER(3)     NOT NULL,
  nombre_asociacion  VARCHAR2(60)  NOT NULL,
  fecha_creacion     DATE          NOT NULL,
  tipo_asociacion    CHAR(1)       DEFAULT 'P' NOT NULL,
  CONSTRAINT ASOCIACION_PK PRIMARY KEY (id_asociacion)
);

CREATE TABLE NACIONALIDAD (
  id_nacion    NUMBER(3) GENERATED ALWAYS AS IDENTITY (START WITH 210 INCREMENT BY 2) NOT NULL,
  descripcion  VARCHAR2(30) NOT NULL,
  CONSTRAINT NACIONALIDAD_PK PRIMARY KEY (id_nacion)
);

CREATE TABLE ESTADO_CIVIL (
  id_estado_civil  NUMBER(2)     NOT NULL,
  descripcion      VARCHAR2(20)  NOT NULL,
  CONSTRAINT ESTADO_CIVIL_PK PRIMARY KEY (id_estado_civil)
);

CREATE TABLE IDIOMA (
  id_idioma  NUMBER(3)     NOT NULL,
  nombre     VARCHAR2(30)  NOT NULL,
  CONSTRAINT IDIOMA_PK PRIMARY KEY (id_idioma)
);

CREATE TABLE ESCUELA_FUTBOL (
  id_escuela        NUMBER(4)     NOT NULL,
  nombre_escuela    VARCHAR2(60)  NOT NULL,
  capacidad         NUMBER(6)     NOT NULL,
  fecha_fundacion   DATE          NOT NULL,
  CONSTRAINT ESCUELA_FUTBOL_PK PRIMARY KEY (id_escuela)
);

-- Tablas con una FK
CREATE TABLE COMUNA (
  id_comuna  NUMBER(4)     NOT NULL,
  REGION_id_region  NUMBER(2)     NOT NULL,
  nombre     VARCHAR2(40)  NOT NULL,
  CONSTRAINT COMUNA_PK PRIMARY KEY (id_comuna)
);

-- Tablas con FK a COMUNA
CREATE TABLE CLUB_FUTBOL (
  id_club            NUMBER(4)      NOT NULL,
  nombre_club        VARCHAR2(60)   NOT NULL,
  patrimonio         NUMBER(12)     DEFAULT 0 NOT NULL,
  ubicacion_calle    VARCHAR2(80)   NOT NULL,
  tipo_club          VARCHAR2(12)   DEFAULT 'Profesional' NOT NULL,
  CONSTRAINT CLUB_FUTBOL_PK PRIMARY KEY (id_club)
);

-- Supertipo TRABAJADOR (jugadores y personal de planta)
CREATE TABLE TRABAJADOR (
  id_inscripcion     NUMBER(9)      NOT NULL,   -- N° de inscripción (Figura 1)
  rut                NUMBER(8)      NOT NULL,
  dv_rut             CHAR(1)        NOT NULL,
  nombres            VARCHAR2(50)   NOT NULL,
  apellido_paterno   VARCHAR2(30)   NOT NULL,
  apellido_materno   VARCHAR2(30)   NOT NULL,
  sueldo_base        NUMBER(9)      DEFAULT 0 NOT NULL,
  fecha_nacimiento   DATE           NOT NULL,
  genero             CHAR(1)        NOT NULL,
  email              VARCHAR2(80),
  telefono_movil     VARCHAR2(15)   NOT NULL,
  direccion          VARCHAR2(80)   NOT NULL,
  ESTADO_CIVIL_id_estado_civil    NUMBER(2)      NOT NULL,
  COMUNA_id_comuna        NUMBER(4)      NOT NULL,
  NACIONALIDAD_id_nacion         NUMBER(3)      NOT NULL,
  tipo_trabajador    CHAR(1)        NOT NULL,   -- J = jugador, P = personal de planta
  CONSTRAINT TRABAJADOR_PK PRIMARY KEY (id_inscripcion)
);

-- Subtipo JUGADOR
CREATE TABLE JUGADOR (
  id_inscripcion      NUMBER(9)    NOT NULL,
  puesto              VARCHAR2(30) NOT NULL,
  monto_total_premios NUMBER(12)   DEFAULT 0 NOT NULL,
  ASOCIACION_id_asociacion       NUMBER(3)    NOT NULL,
  ESCUELA_FUTBOL_id_escuela         NUMBER(4),                -- opcional: puede no venir de una escuela
  anio_egreso_escuela NUMBER(4),                -- opcional: año en que dejó el amateurismo
  CONSTRAINT JUGADOR_PK PRIMARY KEY (id_inscripcion)
);

-- Subtipo PERSONAL_PLANTA
CREATE TABLE PERSONAL_PLANTA (
  id_inscripcion      NUMBER(9)    NOT NULL,
  CLUB_FUTBOL_id_club            NUMBER(4)    NOT NULL,
  horas_trabajadas    NUMBER(4)    DEFAULT 0,
  valor_hora_extra    NUMBER(7)    DEFAULT 0,
  CONSTRAINT PERSONAL_PLANTA_PK PRIMARY KEY (id_inscripcion)
);

-- Tablas intermedias (relaciones N:M
CREATE TABLE CONTRATO_JUGADOR (
  JUGADOR_id_inscripcion      NUMBER(9)  NOT NULL,
  CLUB_FUTBOL_id_club             NUMBER(4)  NOT NULL,
  fecha_incorporacion  DATE       NOT NULL,
  fecha_fin_contrato   DATE,                    -- NULL = contrato vigente
  CONSTRAINT CONTRATO_JUGADOR_PK PRIMARY KEY (JUGADOR_id_inscripcion, CLUB_FUTBOL_id_club, fecha_incorporacion)
);

CREATE TABLE DOMINIO_IDIOMA (
  JUGADOR_id_inscripcion NUMBER(9)     NOT NULL,
  IDIOMA_id_idioma      NUMBER(3)     NOT NULL,
  nivel_dominio   VARCHAR2(12)  DEFAULT 'BASICO' NOT NULL,
  CONSTRAINT DOMINIO_IDIOMA_PK PRIMARY KEY (JUGADOR_id_inscripcion, IDIOMA_id_idioma)
);

-- 3. MODIFICACIONES AL MODELO FÍSICO: restricciones FK, UN y CK

-- Claves foráneas (FK
ALTER TABLE COMUNA
  ADD CONSTRAINT COMUNA_REGION_FK FOREIGN KEY (REGION_id_region) REFERENCES REGION (id_region);

ALTER TABLE TRABAJADOR
  ADD CONSTRAINT TRABAJADOR_ESTADO_CIVIL_FK FOREIGN KEY (ESTADO_CIVIL_id_estado_civil) REFERENCES ESTADO_CIVIL (id_estado_civil);
ALTER TABLE TRABAJADOR
  ADD CONSTRAINT TRABAJADOR_COMUNA_FK FOREIGN KEY (COMUNA_id_comuna) REFERENCES COMUNA (id_comuna);
ALTER TABLE TRABAJADOR
  ADD CONSTRAINT TRABAJADOR_NACIONALIDAD_FK FOREIGN KEY (NACIONALIDAD_id_nacion) REFERENCES NACIONALIDAD (id_nacion);

ALTER TABLE JUGADOR
  ADD CONSTRAINT JUGADOR_TRABAJADOR_FK FOREIGN KEY (id_inscripcion) REFERENCES TRABAJADOR (id_inscripcion);
ALTER TABLE JUGADOR
  ADD CONSTRAINT JUGADOR_ASOCIACION_FK FOREIGN KEY (ASOCIACION_id_asociacion) REFERENCES ASOCIACION (id_asociacion);
ALTER TABLE JUGADOR
  ADD CONSTRAINT JUGADOR_ESCUELA_FUTBOL_FK FOREIGN KEY (ESCUELA_FUTBOL_id_escuela) REFERENCES ESCUELA_FUTBOL (id_escuela);

ALTER TABLE PERSONAL_PLANTA
  ADD CONSTRAINT PERSONAL_PLANTA_TRABAJADOR_FK FOREIGN KEY (id_inscripcion) REFERENCES TRABAJADOR (id_inscripcion);
ALTER TABLE PERSONAL_PLANTA
  ADD CONSTRAINT PERSONAL_PLANTA_CLUB_FUTBOL_FK FOREIGN KEY (CLUB_FUTBOL_id_club) REFERENCES CLUB_FUTBOL (id_club);

ALTER TABLE CONTRATO_JUGADOR
  ADD CONSTRAINT CONTRATO_JUGADOR_JUGADOR_FK FOREIGN KEY (JUGADOR_id_inscripcion) REFERENCES JUGADOR (id_inscripcion);
ALTER TABLE CONTRATO_JUGADOR
  ADD CONSTRAINT CONTRATO_JUGADOR_CLUB_FUTBOL_FK FOREIGN KEY (CLUB_FUTBOL_id_club) REFERENCES CLUB_FUTBOL (id_club);

ALTER TABLE DOMINIO_IDIOMA
  ADD CONSTRAINT DOMINIO_IDIOMA_JUGADOR_FK FOREIGN KEY (JUGADOR_id_inscripcion) REFERENCES JUGADOR (id_inscripcion);
ALTER TABLE DOMINIO_IDIOMA
  ADD CONSTRAINT DOMINIO_IDIOMA_IDIOMA_FK FOREIGN KEY (IDIOMA_id_idioma) REFERENCES IDIOMA (id_idioma);

-- Claves únicas (UN)
ALTER TABLE CLUB_FUTBOL
  ADD CONSTRAINT UN_CLUB_FUTBOL_NOMBRE UNIQUE (nombre_club);
ALTER TABLE TRABAJADOR
  ADD CONSTRAINT UN_TRABAJADOR_RUT UNIQUE (rut, dv_rut);
ALTER TABLE IDIOMA
  ADD CONSTRAINT UN_IDIOMA_NOMBRE UNIQUE (nombre);
ALTER TABLE NACIONALIDAD
  ADD CONSTRAINT UN_NACIONALIDAD_DESCRIPCION UNIQUE (descripcion);

-- Validaciones (CK)
ALTER TABLE ASOCIACION
  ADD CONSTRAINT CK_ASOCIACION_FECHA_CREACION CHECK (fecha_creacion >= DATE '1980-12-31');
ALTER TABLE ASOCIACION
  ADD CONSTRAINT CK_ASOCIACION_TIPO CHECK (tipo_asociacion IN ('P', 'A'));

ALTER TABLE CLUB_FUTBOL
  ADD CONSTRAINT CK_CLUB_FUTBOL_TIPO CHECK (tipo_club IN ('Profesional', 'Amateur'));
ALTER TABLE CLUB_FUTBOL
  ADD CONSTRAINT CK_CLUB_FUTBOL_PATRIMONIO CHECK (patrimonio >= 0);

ALTER TABLE TRABAJADOR
  ADD CONSTRAINT CK_TRABAJADOR_GENERO CHECK (genero IN ('M', 'F'));
ALTER TABLE TRABAJADOR
  ADD CONSTRAINT CK_TRABAJADOR_TIPO CHECK (tipo_trabajador IN ('J', 'P'));
ALTER TABLE TRABAJADOR
  ADD CONSTRAINT CK_TRABAJADOR_SUELDO CHECK (sueldo_base >= 0);

ALTER TABLE JUGADOR
  ADD CONSTRAINT CK_JUGADOR_PREMIOS CHECK (monto_total_premios >= 0);
ALTER TABLE JUGADOR
  ADD CONSTRAINT CK_JUGADOR_ESCUELA CHECK (
    (ESCUELA_FUTBOL_id_escuela IS NULL AND anio_egreso_escuela IS NULL) OR
    (ESCUELA_FUTBOL_id_escuela IS NOT NULL AND anio_egreso_escuela IS NOT NULL)
  );

ALTER TABLE PERSONAL_PLANTA
  ADD CONSTRAINT CK_PERSONAL_PLANTA_HORAS CHECK (horas_trabajadas >= 0 AND valor_hora_extra >= 0);

ALTER TABLE CONTRATO_JUGADOR
  ADD CONSTRAINT CK_CONTRATO_JUGADOR_FECHAS CHECK (fecha_fin_contrato IS NULL OR fecha_fin_contrato > fecha_incorporacion);

ALTER TABLE DOMINIO_IDIOMA
  ADD CONSTRAINT CK_DOMINIO_IDIOMA_NIVEL CHECK (nivel_dominio IN ('BASICO', 'INTERMEDIO', 'AVANZADO', 'NATIVO'));

-- 4. POBLAMIENTO (REGION, COMUNA, ASOCIACION, NACIONALIDAD, CLUB_FUTBOL)

-- REGION
INSERT INTO REGION (id_region, nombre) VALUES (1,  'ARICA Y PARINACOTA Y TARAPACA');
INSERT INTO REGION (id_region, nombre) VALUES (2,  'ANTOFAGASTA');
INSERT INTO REGION (id_region, nombre) VALUES (3,  'ATACAMA Y COQUIMBO');
INSERT INTO REGION (id_region, nombre) VALUES (5,  'VALPARAISO');
INSERT INTO REGION (id_region, nombre) VALUES (13, 'METROPOLITANA');
INSERT INTO REGION (id_region, nombre) VALUES (8,  'BIOBIO');
INSERT INTO REGION (id_region, nombre) VALUES (16, 'NUBLE');

-- COMUNA
INSERT INTO COMUNA (id_comuna, REGION_id_region, nombre) VALUES (101, 13, 'Santiago');
INSERT INTO COMUNA (id_comuna, REGION_id_region, nombre) VALUES (102, 5,  'Valparaíso');
INSERT INTO COMUNA (id_comuna, REGION_id_region, nombre) VALUES (103, 8,  'Concepción');
INSERT INTO COMUNA (id_comuna, REGION_id_region, nombre) VALUES (104, 2,  'Antofagasta');
INSERT INTO COMUNA (id_comuna, REGION_id_region, nombre) VALUES (105, 16, 'Chillán');

-- ASOCIACION
INSERT INTO ASOCIACION VALUES (25, 'Asociación de Fútbol de Santiago',        TO_DATE('15-05-2001', 'DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION VALUES (26, 'Asociación Nacional de Fútbol Amateur',   TO_DATE('10-03-1998', 'DD-MM-YYYY'), 'A');
INSERT INTO ASOCIACION VALUES (27, 'Asociación de Fútbol de Valparaíso',      TO_DATE('21-07-1987', 'DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION VALUES (28, 'Asociación de Fútbol de Concepción',      TO_DATE('30-11-1995', 'DD-MM-YYYY'), 'A');
INSERT INTO ASOCIACION VALUES (29, 'Asociación de Fútbol de Antofagasta',     TO_DATE('25-06-2003', 'DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION VALUES (30, 'Asociación de Fútbol de Temuco',          TO_DATE('12-01-2010', 'DD-MM-YYYY'), 'A');
INSERT INTO ASOCIACION VALUES (31, 'Asociación de Fútbol de Rancagua',        TO_DATE('08-09-1999', 'DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION VALUES (32, 'Asociación de Fútbol de Puerto Montt',    TO_DATE('20-04-2005', 'DD-MM-YYYY'), 'A');
INSERT INTO ASOCIACION VALUES (33, 'Asociación de Fútbol de La Serena',       TO_DATE('14-08-2012', 'DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION VALUES (34, 'Asociación de Fútbol de Chillán',         TO_DATE('01-12-2018', 'DD-MM-YYYY'), 'A');

-- NACIONALIDAD
INSERT INTO NACIONALIDAD (descripcion) VALUES ('Chilena');
INSERT INTO NACIONALIDAD (descripcion) VALUES ('Argentina');
INSERT INTO NACIONALIDAD (descripcion) VALUES ('Peruana');
INSERT INTO NACIONALIDAD (descripcion) VALUES ('Boliviana');
INSERT INTO NACIONALIDAD (descripcion) VALUES ('Brasileña');

-- CLUB_FUTBOL
INSERT INTO CLUB_FUTBOL (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
  VALUES (SEQ_CLUB_FUTBOL.NEXTVAL, 'Colo-Colo',            500000000, 'Av. Marathon 5300',              'Profesional');
INSERT INTO CLUB_FUTBOL (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
  VALUES (SEQ_CLUB_FUTBOL.NEXTVAL, 'Universidad de Chile', 450000000, 'Av. El Parrón 0931',             'Profesional');
INSERT INTO CLUB_FUTBOL (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
  VALUES (SEQ_CLUB_FUTBOL.NEXTVAL, 'Deportes Antofagasta', 180000000, 'Avenida Angamos 01606',          'Profesional');
INSERT INTO CLUB_FUTBOL (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
  VALUES (SEQ_CLUB_FUTBOL.NEXTVAL, 'Huachipato',           220000000, 'Avenida Desiderio García 909',   'Profesional');
INSERT INTO CLUB_FUTBOL (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
  VALUES (SEQ_CLUB_FUTBOL.NEXTVAL, 'Ñublense',             170000000, 'Avenida Pedro Aguirre Cerda 1003', 'Profesional');

COMMIT;


-- 5. FASE 4: CONSULTAS DE RECUPERACIÓN DE DATOS

-- Informe 1: Asociaciones de fútbol profesional creadas después del año 2000
SELECT 'ID:' || id_asociacion || ' * ' || nombre_asociacion AS "ASOCIACION",
       TO_CHAR(fecha_creacion, 'DD-MM-YYYY')                AS "CREADA",
       tipo_asociacion                                      AS "TIPO"
FROM   ASOCIACION
WHERE  tipo_asociacion = 'P'
AND    EXTRACT(YEAR FROM fecha_creacion) > 2000
ORDER  BY fecha_creacion DESC;

-- Informe 2: Patrimonio de clubes en pesos y dólares
SELECT id_club               AS "CLUB",
       nombre_club           AS "NOMBRE CLUB",
       patrimonio            AS "PATRIMONIO EN PESOS",
       patrimonio / 955      AS "PATRIMONIO EN DOLARES"
FROM   CLUB_FUTBOL
WHERE  UPPER(nombre_club) LIKE '%A%'
AND    patrimonio > 200000000
AND    tipo_club = 'Profesional'
ORDER  BY id_club DESC;
