--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2 (Ubuntu 17.2-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: obtener_subtotal_carrito(integer); Type: FUNCTION; Schema: public; Owner: eko_bazar_owner
--

CREATE FUNCTION public.obtener_subtotal_carrito(carrito_id_param integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    subtotal NUMERIC(10, 2);
BEGIN
    SELECT 
        SUM(co.cantidad * pr.precio) 
    INTO 
        subtotal
    FROM 
        compras co
    JOIN 
        productos pr ON co.producto_id = pr.id
    WHERE 
        co.carrito_id = carrito_id_param;

    -- Si el carrito no tiene productos, devolvemos 0 como subtotal.
    IF subtotal IS NULL THEN
        RETURN 0;
    END IF;

    RETURN subtotal;
END;
$$;


ALTER FUNCTION public.obtener_subtotal_carrito(carrito_id_param integer) OWNER TO eko_bazar_owner;

--
-- Name: registrar_evento_usuario(); Type: FUNCTION; Schema: public; Owner: eko_bazar_owner
--

CREATE FUNCTION public.registrar_evento_usuario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    accion VARCHAR(50);
    datos_usuario JSONB;
    usuario_actual VARCHAR(100);
BEGIN
    -- Determinar el tipo de acción
    IF TG_OP = 'INSERT' THEN
        accion := 'CREACIÓN';
        datos_usuario := row_to_json(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        accion := 'ACTUALIZACIÓN';
        datos_usuario := jsonb_build_object(
            'antes', row_to_json(OLD),
            'después', row_to_json(NEW)
        );
    ELSIF TG_OP = 'DELETE' THEN
        accion := 'ELIMINACIÓN';
        datos_usuario := row_to_json(OLD);
    END IF;

    -- Obtener el usuario actual si está disponible
    SELECT CURRENT_USER INTO usuario_actual;

    -- Insertar el log en la tabla logs_usuarios
    INSERT INTO logs_usuarios (usuario_id, accion, datos, realizado_por)
    VALUES (
        COALESCE(NEW.id, OLD.id), -- ID del usuario afectado (si existe)
        accion,
        datos_usuario,
        usuario_actual
    );

    RETURN NULL; -- Los triggers de AFTER no alteran los datos de las filas
END;
$$;


ALTER FUNCTION public.registrar_evento_usuario() OWNER TO eko_bazar_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: carritos; Type: TABLE; Schema: public; Owner: eko_bazar_owner
--

CREATE TABLE public.carritos (
    id integer NOT NULL,
    usuario_id integer,
    pago_id integer
);


ALTER TABLE public.carritos OWNER TO eko_bazar_owner;

--
-- Name: carritos_id_seq; Type: SEQUENCE; Schema: public; Owner: eko_bazar_owner
--

CREATE SEQUENCE public.carritos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.carritos_id_seq OWNER TO eko_bazar_owner;

--
-- Name: carritos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: eko_bazar_owner
--

ALTER SEQUENCE public.carritos_id_seq OWNED BY public.carritos.id;


--
-- Name: compras; Type: TABLE; Schema: public; Owner: eko_bazar_owner
--

CREATE TABLE public.compras (
    id integer NOT NULL,
    carrito_id integer,
    producto_id integer,
    cantidad integer NOT NULL,
    CONSTRAINT compras_cantidad_check CHECK ((cantidad > 0))
);


ALTER TABLE public.compras OWNER TO eko_bazar_owner;

--
-- Name: compras_id_seq; Type: SEQUENCE; Schema: public; Owner: eko_bazar_owner
--

CREATE SEQUENCE public.compras_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.compras_id_seq OWNER TO eko_bazar_owner;

--
-- Name: compras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: eko_bazar_owner
--

ALTER SEQUENCE public.compras_id_seq OWNED BY public.compras.id;


--
-- Name: favoritos; Type: TABLE; Schema: public; Owner: eko_bazar_owner
--

CREATE TABLE public.favoritos (
    id integer NOT NULL,
    usuario_id integer,
    producto_id integer
);


ALTER TABLE public.favoritos OWNER TO eko_bazar_owner;

--
-- Name: favoritos_id_seq; Type: SEQUENCE; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE public.favoritos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.favoritos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logs_usuarios; Type: TABLE; Schema: public; Owner: eko_bazar_owner
--

CREATE TABLE public.logs_usuarios (
    id integer NOT NULL,
    usuario_id integer,
    accion character varying(50) NOT NULL,
    datos jsonb,
    realizado_por character varying(100),
    fecha_evento timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.logs_usuarios OWNER TO eko_bazar_owner;

--
-- Name: logs_usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: eko_bazar_owner
--

CREATE SEQUENCE public.logs_usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logs_usuarios_id_seq OWNER TO eko_bazar_owner;

--
-- Name: logs_usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: eko_bazar_owner
--

ALTER SEQUENCE public.logs_usuarios_id_seq OWNED BY public.logs_usuarios.id;


--
-- Name: pagos; Type: TABLE; Schema: public; Owner: eko_bazar_owner
--

CREATE TABLE public.pagos (
    id integer NOT NULL,
    carrito_id integer,
    usuario_id integer,
    fecha_pago timestamp without time zone DEFAULT now(),
    total numeric(10,2) NOT NULL
);


ALTER TABLE public.pagos OWNER TO eko_bazar_owner;

--
-- Name: pagos_id_seq; Type: SEQUENCE; Schema: public; Owner: eko_bazar_owner
--

CREATE SEQUENCE public.pagos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pagos_id_seq OWNER TO eko_bazar_owner;

--
-- Name: pagos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: eko_bazar_owner
--

ALTER SEQUENCE public.pagos_id_seq OWNED BY public.pagos.id;


--
-- Name: productos; Type: TABLE; Schema: public; Owner: eko_bazar_owner
--

CREATE TABLE public.productos (
    id integer NOT NULL,
    nombre character varying(255) NOT NULL,
    marca character varying(100),
    descripcion text,
    precio numeric(10,2) NOT NULL,
    precio_mayoreo numeric(10,2),
    imagen_url text,
    stock integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.productos OWNER TO eko_bazar_owner;

--
-- Name: productos_id_seq; Type: SEQUENCE; Schema: public; Owner: eko_bazar_owner
--

CREATE SEQUENCE public.productos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.productos_id_seq OWNER TO eko_bazar_owner;

--
-- Name: productos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: eko_bazar_owner
--

ALTER SEQUENCE public.productos_id_seq OWNED BY public.productos.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: eko_bazar_owner
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    apellidos character varying(150) NOT NULL,
    correo character varying(150) NOT NULL,
    telefono character varying(20),
    direccion text,
    fecha_nacimiento date NOT NULL,
    password character varying NOT NULL,
    rol character varying(20) DEFAULT 'cliente'::character varying NOT NULL
);


ALTER TABLE public.usuarios OWNER TO eko_bazar_owner;

--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: eko_bazar_owner
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_seq OWNER TO eko_bazar_owner;

--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: eko_bazar_owner
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: vista_carritos; Type: VIEW; Schema: public; Owner: eko_bazar_owner
--

CREATE VIEW public.vista_carritos AS
 SELECT id AS carrito_id,
    usuario_id,
        CASE
            WHEN (pago_id IS NULL) THEN 'Pendiente de pago'::text
            ELSE 'Pago registrado'::text
        END AS estado_pago
   FROM public.carritos c;


ALTER VIEW public.vista_carritos OWNER TO eko_bazar_owner;

--
-- Name: vista_compras; Type: VIEW; Schema: public; Owner: eko_bazar_owner
--

CREATE VIEW public.vista_compras AS
 SELECT co.id AS compra_id,
    co.carrito_id,
    c.usuario_id AS usuario_carrito,
    p.nombre AS nombre_producto,
    co.cantidad,
    p.precio AS precio_producto,
    ((co.cantidad)::numeric * p.precio) AS total_compra
   FROM ((public.compras co
     JOIN public.carritos c ON ((co.carrito_id = c.id)))
     JOIN public.productos p ON ((co.producto_id = p.id)));


ALTER VIEW public.vista_compras OWNER TO eko_bazar_owner;

--
-- Name: vista_pagos; Type: VIEW; Schema: public; Owner: eko_bazar_owner
--

CREATE VIEW public.vista_pagos AS
SELECT
    NULL::integer AS pago_id,
    NULL::character varying(100) AS nombre_usuario,
    NULL::integer AS carrito_id,
    NULL::timestamp without time zone AS fecha_pago,
    NULL::numeric(10,2) AS total_pago,
    NULL::numeric AS subtotal_productos,
    NULL::numeric AS diferencia_pago;


ALTER VIEW public.vista_pagos OWNER TO eko_bazar_owner;

--
-- Name: vista_productos; Type: VIEW; Schema: public; Owner: eko_bazar_owner
--

CREATE VIEW public.vista_productos AS
 SELECT id AS producto_id,
    nombre,
    imagen_url
   FROM public.productos;


ALTER VIEW public.vista_productos OWNER TO eko_bazar_owner;

--
-- Name: vista_productos_precios; Type: VIEW; Schema: public; Owner: eko_bazar_owner
--

CREATE VIEW public.vista_productos_precios AS
 SELECT id AS producto_id,
    nombre,
    marca,
    precio,
    precio_mayoreo,
        CASE
            WHEN (precio_mayoreo IS NOT NULL) THEN 'Disponible'::text
            ELSE 'No disponible'::text
        END AS estado_mayoreo
   FROM public.productos;


ALTER VIEW public.vista_productos_precios OWNER TO eko_bazar_owner;

--
-- Name: vista_usuarios; Type: VIEW; Schema: public; Owner: eko_bazar_owner
--

CREATE VIEW public.vista_usuarios AS
 SELECT nombre,
    date_part('year'::text, age((fecha_nacimiento)::timestamp with time zone)) AS edad,
    fecha_nacimiento,
    correo,
    id,
    rol
   FROM public.usuarios;


ALTER VIEW public.vista_usuarios OWNER TO eko_bazar_owner;

--
-- Name: carritos id; Type: DEFAULT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.carritos ALTER COLUMN id SET DEFAULT nextval('public.carritos_id_seq'::regclass);


--
-- Name: compras id; Type: DEFAULT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.compras ALTER COLUMN id SET DEFAULT nextval('public.compras_id_seq'::regclass);


--
-- Name: logs_usuarios id; Type: DEFAULT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.logs_usuarios ALTER COLUMN id SET DEFAULT nextval('public.logs_usuarios_id_seq'::regclass);


--
-- Name: pagos id; Type: DEFAULT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.pagos ALTER COLUMN id SET DEFAULT nextval('public.pagos_id_seq'::regclass);


--
-- Name: productos id; Type: DEFAULT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.productos ALTER COLUMN id SET DEFAULT nextval('public.productos_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Data for Name: carritos; Type: TABLE DATA; Schema: public; Owner: eko_bazar_owner
--

COPY public.carritos (id, usuario_id, pago_id) FROM stdin;
1	16	1
2	17	2
3	17	3
4	16	4
5	16	5
6	16	6
7	16	7
8	16	8
9	16	\N
10	17	9
11	17	10
12	17	11
13	17	12
\.


--
-- Data for Name: compras; Type: TABLE DATA; Schema: public; Owner: eko_bazar_owner
--

COPY public.compras (id, carrito_id, producto_id, cantidad) FROM stdin;
3	1	3	1
1	1	1	1
2	1	2	2
33	9	5	5
32	9	11	6
\.


--
-- Data for Name: favoritos; Type: TABLE DATA; Schema: public; Owner: eko_bazar_owner
--

COPY public.favoritos (id, usuario_id, producto_id) FROM stdin;
23	17	1
33	16	11
34	16	2
\.


--
-- Data for Name: logs_usuarios; Type: TABLE DATA; Schema: public; Owner: eko_bazar_owner
--

COPY public.logs_usuarios (id, usuario_id, accion, datos, realizado_por, fecha_evento) FROM stdin;
1	4	CREACIÓN	{"id": 4, "edad": 53, "correo": "eui@wouh.cokoe", "nombre": "a", "telefono": null, "apellidos": "a", "direccion": null, "fecha_nacimiento": "2024-11-01"}	postgres	2024-12-03 12:53:44.26301
2	8	CREACIÓN	{"id": 8, "edad": 53, "correo": "edewd23di@wou2dh.cokoeded3w", "nombre": "b", "telefono": null, "apellidos": "b", "direccion": null, "fecha_nacimiento": "2024-11-01"}	postgres	2024-12-03 12:56:14.126193
3	9	CREACIÓN	{"id": 9, "edad": 53, "correo": "edewd23di@wou2dh.cokoeded3wdeqkjuwfbkuqedw", "nombre": "c", "telefono": null, "apellidos": "c", "direccion": null, "fecha_nacimiento": "2004-11-30"}	postgres	2024-12-03 12:56:47.664809
4	11	CREACIÓN	{"id": 11, "edad": 20, "correo": "jgn@gmail.com", "nombre": "Jesús", "telefono": null, "apellidos": "García Nigoche", "direccion": null, "fecha_nacimiento": "2004-10-22"}	postgres	2024-12-03 12:59:08.262401
5	4	ELIMINACIÓN	{"id": 4, "edad": 53, "correo": "eui@wouh.cokoe", "nombre": "a", "telefono": null, "apellidos": "a", "direccion": null, "fecha_nacimiento": "2024-11-01"}	postgres	2024-12-03 12:59:52.70482
6	12	CREACIÓN	{"id": 12, "edad": 45, "correo": "egoer@oeinfi.cojeo", "nombre": "Jorge", "telefono": null, "apellidos": "Martinez", "direccion": null, "fecha_nacimiento": "1990-02-10"}	postgres	2024-12-03 13:47:18.070477
7	13	CREACIÓN	{"id": 13, "edad": 30, "correo": "horacio@tecvalles.mx", "nombre": "Horacio", "telefono": null, "apellidos": "García", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-03 18:17:12.191785
8	13	ELIMINACIÓN	{"id": 13, "edad": 30, "correo": "horacio@tecvalles.mx", "nombre": "Horacio", "telefono": null, "apellidos": "García", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-03 18:43:03.488605
9	14	CREACIÓN	{"id": 14, "edad": 34, "correo": "sergio@gmail.com", "nombre": "Sergio", "telefono": null, "apellidos": "Martinez (es inventado jaja, no me lo sé)", "direccion": null, "fecha_nacimiento": "2000-04-12"}	postgres	2024-12-03 20:09:08.294672
10	14	ELIMINACIÓN	{"id": 14, "edad": 34, "correo": "sergio@gmail.com", "nombre": "Sergio", "telefono": null, "apellidos": "Martinez (es inventado jaja, no me lo sé)", "direccion": null, "fecha_nacimiento": "2000-04-12"}	postgres	2024-12-03 20:09:15.459839
11	12	ELIMINACIÓN	{"id": 12, "edad": 45, "correo": "egoer@oeinfi.cojeo", "nombre": "Jorge", "telefono": null, "apellidos": "Martinez", "direccion": null, "fecha_nacimiento": "1990-02-10"}	postgres	2024-12-03 20:09:21.834814
12	15	CREACIÓN	{"id": 15, "edad": 40, "correo": "jesus@a.com", "nombre": "Jesus", "password": "$2y$10$qAJNxZFLuQiSSWjmG.OET.xuyNFGOu6kbwK4s9pFWYK6WPKn49YIW", "telefono": null, "apellidos": "Garcia", "direccion": null, "fecha_nacimiento": "2000-01-10"}	postgres	2024-12-04 09:00:47.785306
13	8	ELIMINACIÓN	{"id": 8, "edad": 53, "correo": "edewd23di@wou2dh.cokoeded3w", "nombre": "b", "password": null, "telefono": null, "apellidos": "b", "direccion": null, "fecha_nacimiento": "2024-11-01"}	postgres	2024-12-04 09:12:28.711203
14	9	ELIMINACIÓN	{"id": 9, "edad": 53, "correo": "edewd23di@wou2dh.cokoeded3wdeqkjuwfbkuqedw", "nombre": "c", "password": null, "telefono": null, "apellidos": "c", "direccion": null, "fecha_nacimiento": "2004-11-30"}	postgres	2024-12-04 09:12:31.268594
15	11	ELIMINACIÓN	{"id": 11, "edad": 20, "correo": "jgn@gmail.com", "nombre": "Jesús", "password": null, "telefono": null, "apellidos": "García Nigoche", "direccion": null, "fecha_nacimiento": "2004-10-22"}	postgres	2024-12-04 09:12:35.396518
16	16	CREACIÓN	{"id": 16, "edad": 22, "correo": "sergio@a.com", "nombre": "Sergio", "password": "$2y$10$1spbLOkBTfA4tcsgx/pC8ebPnDGrIsffeTlGnGiPl1faG4nlEAHDe", "telefono": null, "apellidos": "Martinez", "direccion": null, "fecha_nacimiento": "1999-12-13"}	postgres	2024-12-04 09:13:16.326563
17	17	CREACIÓN	{"id": 17, "edad": 23, "correo": "juangpt@xd.com", "nombre": "Juan", "password": "$2y$10$7HTNERFudOhXSZvsqT/sSuulbDETLDabUahDwKljWekjnZedVUuqS", "telefono": null, "apellidos": "GPT", "direccion": null, "fecha_nacimiento": "2000-10-10"}	postgres	2024-12-04 11:18:17.717062
18	17	ELIMINACIÓN	{"id": 17, "edad": 23, "correo": "juangpt@xd.com", "nombre": "Juan", "password": "$2y$10$7HTNERFudOhXSZvsqT/sSuulbDETLDabUahDwKljWekjnZedVUuqS", "telefono": null, "apellidos": "GPT", "direccion": null, "fecha_nacimiento": "2000-10-10"}	postgres	2024-12-04 11:20:59.229959
19	18	CREACIÓN	{"id": 18, "edad": 23, "correo": "juangpt@xd.com", "nombre": "Juan", "password": "$2y$10$1x7oUWSlk4TD4fNMfbfwGO3wbPiMF/ZljhOwCy47WnG1AHIUSatZC", "telefono": null, "apellidos": "GPT", "direccion": null, "fecha_nacimiento": "2000-10-10"}	postgres	2024-12-04 11:21:12.957227
20	19	CREACIÓN	{"id": 19, "correo": "juanperez@a.com", "nombre": "Juan", "password": "$2y$10$1wkt4HFRtRMkMbYR/fkNpOWF/f9ZAA27WAwpkrEjVRakRaTpo/GcC", "telefono": null, "apellidos": "Perez", "direccion": null, "fecha_nacimiento": "2001-10-10"}	postgres	2024-12-04 12:03:27.264089
21	19	ELIMINACIÓN	{"id": 19, "correo": "juanperez@a.com", "nombre": "Juan", "password": "$2y$10$1wkt4HFRtRMkMbYR/fkNpOWF/f9ZAA27WAwpkrEjVRakRaTpo/GcC", "telefono": null, "apellidos": "Perez", "direccion": null, "fecha_nacimiento": "2001-10-10"}	postgres	2024-12-04 14:45:58.126289
22	18	ELIMINACIÓN	{"id": 18, "correo": "juangpt@xd.com", "nombre": "Juan", "password": "$2y$10$1x7oUWSlk4TD4fNMfbfwGO3wbPiMF/ZljhOwCy47WnG1AHIUSatZC", "telefono": null, "apellidos": "GPT", "direccion": null, "fecha_nacimiento": "2000-10-10"}	postgres	2024-12-04 21:00:04.438438
23	20	CREACIÓN	{"id": 20, "correo": "juan@a.com", "nombre": "Juan", "password": "$2y$10$HEQ0AavpUAw4RJQpmbIC2el7/hxAQsSPPa7Z33.H9UYU31AWLGo8a", "telefono": null, "apellidos": "Torres", "direccion": null, "fecha_nacimiento": "1987-08-24"}	postgres	2024-12-04 21:01:47.801474
24	20	ELIMINACIÓN	{"id": 20, "correo": "juan@a.com", "nombre": "Juan", "password": "$2y$10$HEQ0AavpUAw4RJQpmbIC2el7/hxAQsSPPa7Z33.H9UYU31AWLGo8a", "telefono": null, "apellidos": "Torres", "direccion": null, "fecha_nacimiento": "1987-08-24"}	postgres	2024-12-04 21:24:39.924688
25	21	CREACIÓN	{"id": 21, "correo": "mayely@a.com", "nombre": "Mayely", "password": "$2y$10$S5MWqXCowftKLSkfCPkmtedL7htjtOTegKGh.XN.GmAAoNcnZwN8u", "telefono": null, "apellidos": "Castillo", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-04 21:25:11.968967
26	21	ELIMINACIÓN	{"id": 21, "correo": "mayely@a.com", "nombre": "Mayely", "password": "$2y$10$S5MWqXCowftKLSkfCPkmtedL7htjtOTegKGh.XN.GmAAoNcnZwN8u", "telefono": null, "apellidos": "Castillo", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-04 21:28:17.797905
27	23	CREACIÓN	{"id": 23, "correo": "mayely@a.com", "nombre": "Mayely", "password": "$2y$10$61D8TrBFlpuJkguXFqi9TOmiiCmmxOfEBwxRLOBx7uMNKphhoW0DG", "telefono": null, "apellidos": "Castillo", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-04 21:28:42.904321
28	26	CREACIÓN	{"id": 26, "correo": "mayely@a.comaaaaa", "nombre": "Mayelya", "password": "$2y$10$GkkPFiUJ3viSsWdIzzgWB.QiSbmA24Mth5tSIzlnr2goKKwgfyeba", "telefono": null, "apellidos": "Castilloooo", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-04 21:29:43.953307
29	26	ELIMINACIÓN	{"id": 26, "correo": "mayely@a.comaaaaa", "nombre": "Mayelya", "password": "$2y$10$GkkPFiUJ3viSsWdIzzgWB.QiSbmA24Mth5tSIzlnr2goKKwgfyeba", "telefono": null, "apellidos": "Castilloooo", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-04 21:44:02.218498
30	28	CREACIÓN	{"id": 28, "correo": "juan@a.com", "nombre": "Juan", "password": "$2y$10$XchMCdv1/cJnSLDlp9XaXeJcd5.AqNptE3/oM7bQGxv8ReLdbOFa.", "telefono": null, "apellidos": "Rosas Torres", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-04 21:44:29.142579
31	30	CREACIÓN	{"id": 30, "correo": "efleipfjjuan@a.com", "nombre": "Juan", "password": "$2y$10$i2t083roN0VnUqmZPGkpd.iHol7mSaNm9RiCIEAdRtmY8DhFrst4W", "telefono": null, "apellidos": "Rosas ", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-04 21:46:44.37952
32	32	CREACIÓN	{"id": 32, "correo": "efleipfjjuan@a.comswdw", "nombre": "Juan", "password": "$2y$10$aGOAq1SSuqQJC1nQPEymDeliBq7SzSaTYRD6x21PqGjVIlVkcJ4hm", "telefono": null, "apellidos": "Rosas ", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-04 21:48:57.181575
33	33	CREACIÓN	{"id": 33, "correo": "efleipfjjuan@a3e3e3.comswdw", "nombre": "Juan", "password": "$2y$10$NupsqRBKaJo53/CzlORIJehHpJtp9Q84.S0RXIduzWYyQe0v22amq", "telefono": null, "apellidos": "Rosas ", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-04 21:49:47.871684
34	34	CREACIÓN	{"id": 34, "correo": "a@a.c", "nombre": "a", "password": "$2y$10$nzsuCR3VFBuiS46DLmrJ9uGPZ23A.PguvsBfhYFGkUdQkC69I6w1y", "telefono": null, "apellidos": "a", "direccion": null, "fecha_nacimiento": "1993-06-30"}	postgres	2024-12-04 21:50:26.96154
35	35	CREACIÓN	{"id": 35, "correo": "aewdwed@a.cswdwe", "nombre": "aqqq", "password": "$2y$10$e377R0CTPwcriNMe2NQc6.ABgWpRwQ3DNfhzIa.YbCLLowP.fMPBe", "telefono": null, "apellidos": "aeee", "direccion": null, "fecha_nacimiento": "1993-06-30"}	postgres	2024-12-04 21:51:06.758261
36	36	CREACIÓN	{"id": 36, "correo": "jesus2@a.com", "nombre": "Jesus2", "password": "$2y$10$WeiwqgbNLkl/WUtf2RDJq.AVnzZIlBUAB1LBjzY.IA5vsSjNCW42W", "telefono": null, "apellidos": "Garcia", "direccion": null, "fecha_nacimiento": "2000-10-10"}	postgres	2024-12-05 09:30:17.014111
37	23	ELIMINACIÓN	{"id": 23, "correo": "mayely@a.com", "nombre": "Mayely", "password": "$2y$10$61D8TrBFlpuJkguXFqi9TOmiiCmmxOfEBwxRLOBx7uMNKphhoW0DG", "telefono": null, "apellidos": "Castillo", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-05 12:51:04.813247
38	34	ELIMINACIÓN	{"id": 34, "correo": "a@a.c", "nombre": "a", "password": "$2y$10$nzsuCR3VFBuiS46DLmrJ9uGPZ23A.PguvsBfhYFGkUdQkC69I6w1y", "telefono": null, "apellidos": "a", "direccion": null, "fecha_nacimiento": "1993-06-30"}	postgres	2024-12-05 13:42:32.973199
39	37	CREACIÓN	{"id": 37, "correo": "mayely@a.a", "nombre": "Mayely", "password": "$2y$10$f8/78GzzzTCMUMCK2qmvueLWIFsh0Lk91Ol.WcAkNfuwd6ln6aoxK", "telefono": null, "apellidos": "Castillo", "direccion": null, "fecha_nacimiento": "2001-12-17"}	postgres	2024-12-05 13:49:11.05922
40	28	ELIMINACIÓN	{"id": 28, "correo": "juan@a.com", "nombre": "Juan", "password": "$2y$10$XchMCdv1/cJnSLDlp9XaXeJcd5.AqNptE3/oM7bQGxv8ReLdbOFa.", "telefono": null, "apellidos": "Rosas Torres", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-05 13:50:13.243212
41	35	ELIMINACIÓN	{"id": 35, "correo": "aewdwed@a.cswdwe", "nombre": "aqqq", "password": "$2y$10$e377R0CTPwcriNMe2NQc6.ABgWpRwQ3DNfhzIa.YbCLLowP.fMPBe", "telefono": null, "apellidos": "aeee", "direccion": null, "fecha_nacimiento": "1993-06-30"}	postgres	2024-12-05 16:45:36.329438
42	36	ELIMINACIÓN	{"id": 36, "correo": "jesus2@a.com", "nombre": "Jesus2", "password": "$2y$10$WeiwqgbNLkl/WUtf2RDJq.AVnzZIlBUAB1LBjzY.IA5vsSjNCW42W", "telefono": null, "apellidos": "Garcia", "direccion": null, "fecha_nacimiento": "2000-10-10"}	postgres	2024-12-05 16:45:38.686557
43	33	ELIMINACIÓN	{"id": 33, "correo": "efleipfjjuan@a3e3e3.comswdw", "nombre": "Juan", "password": "$2y$10$NupsqRBKaJo53/CzlORIJehHpJtp9Q84.S0RXIduzWYyQe0v22amq", "telefono": null, "apellidos": "Rosas ", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-05 16:45:40.586203
44	30	ELIMINACIÓN	{"id": 30, "correo": "efleipfjjuan@a.com", "nombre": "Juan", "password": "$2y$10$i2t083roN0VnUqmZPGkpd.iHol7mSaNm9RiCIEAdRtmY8DhFrst4W", "telefono": null, "apellidos": "Rosas ", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-05 16:45:42.366765
45	32	ELIMINACIÓN	{"id": 32, "correo": "efleipfjjuan@a.comswdw", "nombre": "Juan", "password": "$2y$10$aGOAq1SSuqQJC1nQPEymDeliBq7SzSaTYRD6x21PqGjVIlVkcJ4hm", "telefono": null, "apellidos": "Rosas ", "direccion": null, "fecha_nacimiento": "1990-10-10"}	postgres	2024-12-05 16:45:43.97623
46	38	CREACIÓN	{"id": 38, "correo": "juan@a.com", "nombre": "Juan", "password": "$2y$10$gpfsGBx8n1NEIFZAD3k1DOhiNnpOW/qNMG8GxOQV.b3nD5vbSomga", "telefono": null, "apellidos": "Torres", "direccion": null, "fecha_nacimiento": "2000-10-10"}	postgres	2024-12-05 22:19:25.098596
47	39	CREACIÓN	{"id": 39, "correo": "a@a.a", "nombre": "Juan", "password": "$2y$10$yUpqyBtmFQxLDsziK/jmX.je060QNiQlqIW02qM5xjITq8QTFq68e", "telefono": null, "apellidos": "Torres", "direccion": null, "fecha_nacimiento": "2000-01-10"}	postgres	2024-12-06 10:08:34.076195
48	39	ELIMINACIÓN	{"id": 39, "correo": "a@a.a", "nombre": "Juan", "password": "$2y$10$yUpqyBtmFQxLDsziK/jmX.je060QNiQlqIW02qM5xjITq8QTFq68e", "telefono": null, "apellidos": "Torres", "direccion": null, "fecha_nacimiento": "2000-01-10"}	postgres	2024-12-06 10:09:54.312252
49	38	ELIMINACIÓN	{"id": 38, "correo": "juan@a.com", "nombre": "Juan", "password": "$2y$10$gpfsGBx8n1NEIFZAD3k1DOhiNnpOW/qNMG8GxOQV.b3nD5vbSomga", "telefono": null, "apellidos": "Torres", "direccion": null, "fecha_nacimiento": "2000-10-10"}	postgres	2024-12-06 10:10:15.510083
50	1	CREACIÓN	{"id": 1, "correo": "22690042@tecvalles.mx", "nombre": "Jesús", "password": "md5('tortuga')", "telefono": "8681307299", "apellidos": "García Nigoche", "direccion": "Vistahermosa Calle #1", "fecha_nacimiento": "2004-10-22"}	postgres	2024-12-06 11:45:37.7879
51	1	ELIMINACIÓN	{"id": 1, "correo": "22690042@tecvalles.mx", "nombre": "Jesús", "password": "md5('tortuga')", "telefono": "8681307299", "apellidos": "García Nigoche", "direccion": "Vistahermosa Calle #1", "fecha_nacimiento": "2004-10-22"}	postgres	2024-12-06 11:48:29.118578
52	1	CREACIÓN	{"id": 1, "correo": "22690042@tecvalles.mx", "nombre": "Jesús", "password": "39be78ae8e063a681aaf07b735b0a5f0", "telefono": "8681307299", "apellidos": "García Nigoche", "direccion": "Vistahermosa Calle #1", "fecha_nacimiento": "2004-10-22"}	postgres	2024-12-06 11:58:07.260348
53	1	ACTUALIZACIÓN	{"antes": {"id": 1, "correo": "22690042@tecvalles.mx", "nombre": "Jesús", "password": "39be78ae8e063a681aaf07b735b0a5f0", "telefono": "8681307299", "apellidos": "García Nigoche", "direccion": "Vistahermosa Calle #1", "fecha_nacimiento": "2004-10-22"}, "después": {"id": 1, "correo": "22690042@tecvalles.mx", "nombre": "Jesús", "password": "$2y$10$73Eus72.xCaEXxcBURQAAuwel6djUWSU3pqVSSx2bDNMQ1PTMbb0O", "telefono": "8681307299", "apellidos": "García Nigoche", "direccion": "Vistahermosa Calle #1", "fecha_nacimiento": "2004-10-22"}}	postgres	2024-12-06 12:24:59.340897
54	1	ACTUALIZACIÓN	{"antes": {"id": 1, "rol": "cliente", "correo": "22690042@tecvalles.mx", "nombre": "Jesús", "password": "$2y$10$73Eus72.xCaEXxcBURQAAuwel6djUWSU3pqVSSx2bDNMQ1PTMbb0O", "telefono": "8681307299", "apellidos": "García Nigoche", "direccion": "Vistahermosa Calle #1", "fecha_nacimiento": "2004-10-22"}, "después": {"id": 1, "rol": "admin", "correo": "22690042@tecvalles.mx", "nombre": "Jesús", "password": "$2y$10$73Eus72.xCaEXxcBURQAAuwel6djUWSU3pqVSSx2bDNMQ1PTMbb0O", "telefono": "8681307299", "apellidos": "García Nigoche", "direccion": "Vistahermosa Calle #1", "fecha_nacimiento": "2004-10-22"}}	postgres	2024-12-08 11:44:11.940049
55	17	ACTUALIZACIÓN	{"antes": {"id": 37, "rol": "cliente", "correo": "mayely@a.a", "nombre": "Mayely", "password": "$2y$10$f8/78GzzzTCMUMCK2qmvueLWIFsh0Lk91Ol.WcAkNfuwd6ln6aoxK", "telefono": null, "apellidos": "Castillo", "direccion": null, "fecha_nacimiento": "2001-12-17"}, "después": {"id": 17, "rol": "cliente", "correo": "mayely@a.com", "nombre": "Mayely", "password": "$2y$10$f8/78GzzzTCMUMCK2qmvueLWIFsh0Lk91Ol.WcAkNfuwd6ln6aoxK", "telefono": null, "apellidos": "Castillo", "direccion": null, "fecha_nacimiento": "2001-12-17"}}	postgres	2024-12-09 12:42:26.664365
56	1	ACTUALIZACIÓN	{"antes": {"id": 1, "rol": "admin", "correo": "22690042@tecvalles.mx", "nombre": "Jesús", "password": "$2y$10$73Eus72.xCaEXxcBURQAAuwel6djUWSU3pqVSSx2bDNMQ1PTMbb0O", "telefono": "8681307299", "apellidos": "García Nigoche", "direccion": "Vistahermosa Calle #1", "fecha_nacimiento": "2004-10-22"}, "después": {"id": 1, "rol": "admin", "correo": "admin1@a.com", "nombre": "Jesús", "password": "$2y$10$73Eus72.xCaEXxcBURQAAuwel6djUWSU3pqVSSx2bDNMQ1PTMbb0O", "telefono": "8681307299", "apellidos": "García Nigoche", "direccion": "Vistahermosa Calle #1", "fecha_nacimiento": "2004-10-22"}}	postgres	2024-12-11 10:12:19.865593
57	40	CREACIÓN	{"id": 40, "rol": "cliente", "correo": "admin2@a.com", "nombre": "Sergio", "password": "$2y$10$fkg0CPvnvFmf1/JGVEQC0.wmunJZsxEBrjBNEThN/CBC1ppI5gO/m", "telefono": "481408137958", "apellidos": "González Trejo", "direccion": "El tec", "fecha_nacimiento": "2003-06-04"}	postgres	2024-12-11 12:37:18.283566
58	40	ACTUALIZACIÓN	{"antes": {"id": 40, "rol": "cliente", "correo": "admin2@a.com", "nombre": "Sergio", "password": "$2y$10$fkg0CPvnvFmf1/JGVEQC0.wmunJZsxEBrjBNEThN/CBC1ppI5gO/m", "telefono": "481408137958", "apellidos": "González Trejo", "direccion": "El tec", "fecha_nacimiento": "2003-06-04"}, "después": {"id": 40, "rol": "admin", "correo": "admin2@a.com", "nombre": "Sergio", "password": "$2y$10$fkg0CPvnvFmf1/JGVEQC0.wmunJZsxEBrjBNEThN/CBC1ppI5gO/m", "telefono": "481408137958", "apellidos": "González Trejo", "direccion": "El tec", "fecha_nacimiento": "2003-06-04"}}	postgres	2024-12-11 12:38:38.752166
59	41	CREACIÓN	{"id": 41, "rol": "cliente", "correo": "t1@a.com", "nombre": "34tg3tg34", "password": "$2y$10$dyeP.Pl1tLBTX0RnY/IHrut2hfcESZLqCKktHEzNx3WbDYfwdpe4G", "telefono": "6325635246353", "apellidos": "32r24t4t", "direccion": "rt5w3tq4f", "fecha_nacimiento": "2000-10-10"}	eko_bazar_owner	2024-12-12 20:12:35.879484
60	41	ELIMINACIÓN	{"id": 41, "rol": "cliente", "correo": "t1@a.com", "nombre": "34tg3tg34", "password": "$2y$10$dyeP.Pl1tLBTX0RnY/IHrut2hfcESZLqCKktHEzNx3WbDYfwdpe4G", "telefono": "6325635246353", "apellidos": "32r24t4t", "direccion": "rt5w3tq4f", "fecha_nacimiento": "2000-10-10"}	eko_bazar_owner	2024-12-12 20:12:48.767468
\.


--
-- Data for Name: pagos; Type: TABLE DATA; Schema: public; Owner: eko_bazar_owner
--

COPY public.pagos (id, carrito_id, usuario_id, fecha_pago, total) FROM stdin;
1	1	16	2024-12-09 22:19:22.58982	61997.99
2	2	17	2024-12-09 22:30:40.325864	16079.48
3	3	17	2024-12-09 22:43:16.231459	28999.97
4	4	16	2024-12-10 21:08:32.607164	106.00
5	5	16	2024-12-10 23:39:20.56187	25999.99
6	6	16	2024-12-11 09:31:48.280683	68524.47
7	7	16	2024-12-11 09:58:13.707585	1026.49
8	8	16	2024-12-11 12:33:01.107363	20078.00
9	10	17	2024-12-13 05:40:11.784661	26.50
10	11	17	2024-12-13 17:35:30.537254	26.50
11	12	17	2024-12-13 18:36:36.891252	26.50
12	13	17	2024-12-13 21:58:58.444155	1754.00
\.


--
-- Data for Name: productos; Type: TABLE DATA; Schema: public; Owner: eko_bazar_owner
--

COPY public.productos (id, nombre, marca, descripcion, precio, precio_mayoreo, imagen_url, stock) FROM stdin;
3	Auriculares Bluetooth	Sony	Auriculares inalámbricos con cancelación de ruido y sonido de alta calidad.	3999.00	3699.00	https://via.placeholder.com/300?text=Auriculares	2
4	Monitor 4K	LG	Monitor Ultra HD de 27 pulgadas con diseño sin bordes.	8999.99	8500.00	https://via.placeholder.com/300?text=Monitor	2
6	Teclado Mecánico	Razer	Teclado con switches mecánicos y retroiluminación RGB personalizable.	4999.99	4699.99	https://via.placeholder.com/300?text=Teclado	2
7	Disco Duro Externo	Seagate	Disco duro de 2TB con conexión USB 3.0 y diseño compacto.	2499.50	2299.00	https://via.placeholder.com/300?text=Disco+Duro	2
8	Cámara Fotográfica	Canon	Cámara DSLR de 24MP ideal para fotografía profesional.	18999.99	17999.99	https://via.placeholder.com/300?text=Cámara	2
9	Impresora Multifuncional	HP	Impresora con funciones de escaneo, impresión y copiado.	3999.00	3799.00	https://via.placeholder.com/300?text=Impresora	2
14	Auriculares Bluetooth	Sony	Auriculares inalámbricos con cancelación de ruido y sonido de alta calidad.	3999.00	3699.00	https://m.media-amazon.com/images/I/61D4Z3yKPAL._AC_SL1500_.jpg	0
15	Monitor 4K	LG	Monitor Ultra HD de 27 pulgadas con diseño sin bordes.	8999.99	8500.00	https://m.media-amazon.com/images/I/81k5bZP2TzL._AC_SL1500_.jpg	0
16	Mouse Inalámbrico	Logitech	Mouse ergonómico con conectividad Bluetooth y USB.	999.99	899.00	https://m.media-amazon.com/images/I/61mpMH5TzkL._AC_SL1500_.jpg	0
18	Disco Duro Externo	Seagate	Disco duro de 2TB con conexión USB 3.0 y diseño compacto.	2499.50	2299.00	https://m.media-amazon.com/images/I/71TJawlszxL._AC_SL1500_.jpg	0
19	Cámara Fotográfica	Canon	Cámara DSLR de 24MP ideal para fotografía profesional.	18999.99	17999.99	https://m.media-amazon.com/images/I/81Zt42ioCgL._AC_SL1500_.jpg	0
20	Impresora Multifuncional	HP	Impresora con funciones de escaneo, impresión y copiado.	3999.00	3799.00	https://m.media-amazon.com/images/I/81tP-6DTmtL._AC_SL1500_.jpg	0
1	Laptop Gamer	Acer	Laptop potente con tarjeta gráfica dedicada y procesador de última generación.	25999.99	23999.99	https://via.placeholder.com/300?text=Laptop+Gamer	3
13	Smartphone muy caro	Samsung	Teléfono móvil con conectividad 5G, cámara triple y batería de larga duración.	15999.50	14999.00	https://m.media-amazon.com/images/I/71r69Y7BSeL._AC_SL1500_.jpg	5
2	Smartphone 5G	Samsung	Teléfono móvil con conectividad 5G, cámara triple y batería de larga duración.	15999.50	14999.00	https://via.placeholder.com/300?text=Smartphone	2
5	Mouse Inalámbrico	Logitech	Mouse ergonómico con conectividad Bluetooth y USB.	400.00	300.00	https://via.placeholder.com/300?text=Mouse	-2
11	Maseca Amarilla 1Kg	Maseca	Es harina de maíz de la mejor calidad, 100% ideal para nutrir a toda tu familia	26.50	22.00	../../uploads/maseca.jpeg	8
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: eko_bazar_owner
--

COPY public.usuarios (id, nombre, apellidos, correo, telefono, direccion, fecha_nacimiento, password, rol) FROM stdin;
15	Jesus	Garcia	jesus@a.com	\N	\N	2000-01-10	$2y$10$qAJNxZFLuQiSSWjmG.OET.xuyNFGOu6kbwK4s9pFWYK6WPKn49YIW	cliente
16	Sergio	Martinez	sergio@a.com	\N	\N	1999-12-13	$2y$10$1spbLOkBTfA4tcsgx/pC8ebPnDGrIsffeTlGnGiPl1faG4nlEAHDe	cliente
17	Mayely	Castillo	mayely@a.com	\N	\N	2001-12-17	$2y$10$f8/78GzzzTCMUMCK2qmvueLWIFsh0Lk91Ol.WcAkNfuwd6ln6aoxK	cliente
1	Jesús	García Nigoche	admin1@a.com	8681307299	Vistahermosa Calle #1	2004-10-22	$2y$10$73Eus72.xCaEXxcBURQAAuwel6djUWSU3pqVSSx2bDNMQ1PTMbb0O	admin
40	Sergio	González Trejo	admin2@a.com	481408137958	El tec	2003-06-04	$2y$10$fkg0CPvnvFmf1/JGVEQC0.wmunJZsxEBrjBNEThN/CBC1ppI5gO/m	admin
\.


--
-- Name: carritos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: eko_bazar_owner
--

SELECT pg_catalog.setval('public.carritos_id_seq', 13, true);


--
-- Name: compras_id_seq; Type: SEQUENCE SET; Schema: public; Owner: eko_bazar_owner
--

SELECT pg_catalog.setval('public.compras_id_seq', 44, true);


--
-- Name: favoritos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: eko_bazar_owner
--

SELECT pg_catalog.setval('public.favoritos_id_seq', 34, true);


--
-- Name: logs_usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: eko_bazar_owner
--

SELECT pg_catalog.setval('public.logs_usuarios_id_seq', 60, true);


--
-- Name: pagos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: eko_bazar_owner
--

SELECT pg_catalog.setval('public.pagos_id_seq', 12, true);


--
-- Name: productos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: eko_bazar_owner
--

SELECT pg_catalog.setval('public.productos_id_seq', 22, true);


--
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: eko_bazar_owner
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 41, true);


--
-- Name: carritos carritos_pkey; Type: CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.carritos
    ADD CONSTRAINT carritos_pkey PRIMARY KEY (id);


--
-- Name: compras compras_pkey; Type: CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.compras
    ADD CONSTRAINT compras_pkey PRIMARY KEY (id);


--
-- Name: favoritos favoritos_pkey; Type: CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.favoritos
    ADD CONSTRAINT favoritos_pkey PRIMARY KEY (id);


--
-- Name: logs_usuarios logs_usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.logs_usuarios
    ADD CONSTRAINT logs_usuarios_pkey PRIMARY KEY (id);


--
-- Name: pagos pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (id);


--
-- Name: productos productos_pkey; Type: CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: vista_pagos _RETURN; Type: RULE; Schema: public; Owner: eko_bazar_owner
--

CREATE OR REPLACE VIEW public.vista_pagos AS
 SELECT p.id AS pago_id,
    u.nombre AS nombre_usuario,
    c.id AS carrito_id,
    p.fecha_pago,
    p.total AS total_pago,
    sum(((co.cantidad)::numeric * pr.precio)) AS subtotal_productos,
    (p.total - sum(((co.cantidad)::numeric * pr.precio))) AS diferencia_pago
   FROM ((((public.pagos p
     JOIN public.carritos c ON ((p.carrito_id = c.id)))
     JOIN public.usuarios u ON ((p.usuario_id = u.id)))
     JOIN public.compras co ON ((c.id = co.carrito_id)))
     JOIN public.productos pr ON ((co.producto_id = pr.id)))
  GROUP BY p.id, u.nombre, c.id;


--
-- Name: usuarios trigger_logs_usuarios; Type: TRIGGER; Schema: public; Owner: eko_bazar_owner
--

CREATE TRIGGER trigger_logs_usuarios AFTER INSERT OR DELETE OR UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.registrar_evento_usuario();


--
-- Name: carritos carritos_pago_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.carritos
    ADD CONSTRAINT carritos_pago_id_fkey FOREIGN KEY (pago_id) REFERENCES public.pagos(id);


--
-- Name: carritos carritos_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.carritos
    ADD CONSTRAINT carritos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: compras compras_carrito_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.compras
    ADD CONSTRAINT compras_carrito_id_fkey FOREIGN KEY (carrito_id) REFERENCES public.carritos(id);


--
-- Name: compras compras_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.compras
    ADD CONSTRAINT compras_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(id);


--
-- Name: pagos pagos_carrito_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_carrito_id_fkey FOREIGN KEY (carrito_id) REFERENCES public.carritos(id);


--
-- Name: pagos pagos_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: favoritos producto_id; Type: FK CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.favoritos
    ADD CONSTRAINT producto_id FOREIGN KEY (producto_id) REFERENCES public.productos(id);


--
-- Name: favoritos usuario_id; Type: FK CONSTRAINT; Schema: public; Owner: eko_bazar_owner
--

ALTER TABLE ONLY public.favoritos
    ADD CONSTRAINT usuario_id FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO neon_superuser WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON TABLES TO neon_superuser WITH GRANT OPTION;


--
-- PostgreSQL database dump complete
--

