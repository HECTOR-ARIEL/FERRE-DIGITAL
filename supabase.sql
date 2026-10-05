-- Pega todo esto en Supabase > SQL Editor > Run.
-- Se puede ejecutar varias veces: sirve para crear la base desde cero
-- y también para actualizar una base que ya tenga productos.

-- ===================== PRODUCTOS =====================
create table if not exists productos(
  id bigint generated always as identity primary key,
  codigo text unique,                       -- tu código propio (opcional)
  nombre text not null,                     -- descripción que se muestra (editable)
  stock numeric(12,2) not null default 0,
  activo boolean not null default true      -- false = oculto en el catálogo
);
alter table productos add column if not exists costo numeric(12,2) not null default 0;     -- precio del Excel
alter table productos add column if not exists ganancia numeric(9,4) not null default 0;   -- % de ganancia
alter table productos add column if not exists imagen text;                                -- URL de la foto
alter table productos add column if not exists clave text;  -- descripción original del Excel (no se edita)
alter table productos add column if not exists borrado boolean not null default false;  -- en la papelera
alter table productos alter column codigo drop not null;

-- Versión anterior: "precio" era un número fijo. Ahora pasa a ser el costo,
-- y el precio de venta se calcula solo: costo + % de ganancia.
do $$ begin
  if exists(select 1 from information_schema.columns
            where table_schema='public' and table_name='productos' and column_name='precio' and is_generated='NEVER') then
    execute 'update productos set costo = precio';
    execute 'alter table productos drop column precio';
  end if;
end $$;
alter table productos add column if not exists precio numeric(12,2)
  generated always as (round(costo * (1 + ganancia / 100), 2)) stored;

-- Clave para reconocer cada producto al importar el Excel (por su descripción)
update productos p set clave = s.k
from (select id, lower(regexp_replace(trim(nombre), '\s+', ' ', 'g')) k,
             row_number() over (partition by lower(regexp_replace(trim(nombre), '\s+', ' ', 'g')) order by id) n
      from productos) s
where p.id = s.id and s.n = 1 and p.clave is null;
create unique index if not exists productos_clave_key on productos(clave);

-- ===================== PRESUPUESTOS =====================
create table if not exists presupuestos(
  id bigint generated always as identity primary key,
  fecha timestamptz default now(),
  cliente text,
  total numeric(12,2),
  lineas jsonb
);

-- ===================== PERMISOS =====================
alter table productos enable row level security;
alter table presupuestos enable row level security;
drop policy if exists "catalogo publico" on productos;
drop policy if exists "admin productos" on productos;
drop policy if exists "admin presupuestos" on presupuestos;
-- Cualquiera puede VER el catálogo; solo usuarios con sesión pueden modificar
create policy "catalogo publico" on productos for select using (activo and not borrado);
create policy "admin productos" on productos for all to authenticated using (true) with check (true);
create policy "admin presupuestos" on presupuestos for all to authenticated using (true) with check (true);
-- Los visitantes no pueden ver tu costo ni tu % de ganancia
revoke select on productos from anon;
grant select (id, codigo, nombre, precio, imagen, stock, activo, borrado) on productos to anon;

-- ===================== AVISO DE CAMBIOS =====================
-- Una sola fila con la hora del último cambio en productos.
-- El catálogo la consulta cada pocos segundos y, si cambió, recarga los productos.
create table if not exists cambios(id int primary key default 1, ts timestamptz not null default now());
insert into cambios(id) values (1) on conflict (id) do nothing;
alter table cambios enable row level security;
drop policy if exists "leer cambios" on cambios;
create policy "leer cambios" on cambios for select using (true);
create or replace function marcar_cambio() returns trigger
language plpgsql security definer set search_path = public as $$
begin update cambios set ts = now() where id = 1; return null; end $$;
drop trigger if exists productos_cambio on productos;
create trigger productos_cambio after insert or update or delete on productos
  for each statement execute function marcar_cambio();

-- ===================== IMÁGENES =====================
insert into storage.buckets (id, name, public) values ('imagenes', 'imagenes', true)
  on conflict (id) do update set public = true;
drop policy if exists "admin imagenes" on storage.objects;
create policy "admin imagenes" on storage.objects for all to authenticated
  using (bucket_id = 'imagenes') with check (bucket_id = 'imagenes');

-- ===================== FUNCIONES =====================
-- Importa filas del Excel. Reconoce cada producto por su descripción ORIGINAL del Excel,
-- así que puedes cambiar la descripción visible y el código sin perder el vínculo.
-- Existentes: actualiza costo (y stock si viene). Nuevos: los crea con p_ganancia.
-- Los que están en la papelera se ignoran (no se actualizan ni se vuelven a crear).
create or replace function importar_productos(p_filas jsonb, p_ganancia numeric)
returns json language plpgsql as $$
declare f jsonb; k text; b boolean; nuevos int := 0; actualizados int := 0; omitidos int := 0;
begin
  for f in select * from jsonb_array_elements(p_filas) loop
    k := lower(regexp_replace(trim(f->>'descripcion'), '\s+', ' ', 'g'));
    continue when k = '';
    select borrado into b from productos where clave = k;
    if not found then
      insert into productos(clave, nombre, costo, ganancia, stock)
        values (k, regexp_replace(trim(f->>'descripcion'), '\s+', ' ', 'g'), (f->>'costo')::numeric,
                coalesce(p_ganancia, 0), coalesce((f->>'stock')::numeric, 0));
      nuevos := nuevos + 1;
    elsif b then
      omitidos := omitidos + 1;
    else
      update productos set costo = (f->>'costo')::numeric,
                           stock = coalesce((f->>'stock')::numeric, stock)
        where clave = k;
      actualizados := actualizados + 1;
    end if;
  end loop;
  return json_build_object('nuevos', nuevos, 'actualizados', actualizados, 'omitidos', omitidos);
end $$;

-- Crea el presupuesto y descuenta el stock en una sola operación.
-- Los precios se toman de la base de datos (no del navegador).
-- De cada producto se descuenta y se cobra solo lo que hay en stock ("disponible").
-- Lo que falta queda registrado para mostrarlo en rojo en el PDF.
drop function if exists crear_presupuesto(text, jsonb);
create function crear_presupuesto(p_cliente text, p_lineas jsonb)
returns jsonb language plpgsql as $$
declare l jsonb; n bigint; t numeric := 0; c numeric; d numeric; pr record; lineas jsonb := '[]';
begin
  for l in select * from jsonb_array_elements(p_lineas) loop
    c := (l->>'cantidad')::numeric;
    if c is null or c <= 0 then raise exception 'Cantidad no válida: %', l->>'nombre'; end if;
    select id, codigo, nombre, precio, stock into pr from productos where id = (l->>'id')::bigint for update;
    if not found then raise exception 'Producto no encontrado: %', l->>'nombre'; end if;
    d := least(c, greatest(pr.stock, 0));
    if d > 0 then update productos set stock = stock - d where id = pr.id; end if;
    lineas := lineas || jsonb_build_object('id', pr.id, 'codigo', pr.codigo, 'nombre', pr.nombre,
                                           'precio', pr.precio, 'cantidad', c, 'disponible', d);
    t := t + d * pr.precio;
  end loop;
  insert into presupuestos(cliente, total, lineas) values (p_cliente, t, lineas) returning id into n;
  return jsonb_build_object('id', n, 'total', t, 'lineas', lineas);
end $$;

revoke execute on function importar_productos(jsonb, numeric) from public, anon;
revoke execute on function crear_presupuesto(text, jsonb) from public, anon;
grant execute on function importar_productos(jsonb, numeric) to authenticated;
grant execute on function crear_presupuesto(text, jsonb) to authenticated;
