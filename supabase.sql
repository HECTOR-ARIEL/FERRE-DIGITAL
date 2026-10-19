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
alter table productos add column if not exists minimo numeric(12,2);  -- compra mínima en el catálogo (vacío = por unidad)
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

-- ===================== SECTORES =====================
-- Cada producto puede estar en un sector (Herramientas, Electricidad...). Los sectores se crean desde el panel.
create table if not exists sectores(
  id bigint generated always as identity primary key,
  nombre text not null unique
);
-- Al borrar un sector, sus productos quedan "sin sector" (no se borran)
alter table productos add column if not exists sector_id bigint references sectores(id) on delete set null;
create index if not exists productos_sector_idx on productos(sector_id);
-- Sectores iniciales (solo la primera vez, cuando todavía no hay ninguno)
insert into sectores(nombre)
  select x from unnest(array['Herramientas','Jardinería','Electricidad','Grasas','Lubricantes']) x
  where not exists (select 1 from sectores);

-- ===================== PRESUPUESTOS =====================
create table if not exists presupuestos(
  id bigint generated always as identity primary key,
  fecha timestamptz default now(),
  cliente text,
  total numeric(12,2),
  lineas jsonb
);

-- ===================== PEDIDOS AL PROVEEDOR =====================
-- Cada pedido enviado recuerda hasta qué presupuesto incluyó:
-- el siguiente pedido cuenta las ventas a partir de ahí.
create table if not exists pedidos(
  id bigint generated always as identity primary key,
  fecha timestamptz default now(),
  hasta_presupuesto bigint not null default 0,
  lineas jsonb                              -- [{id, nombre, cantidad}] lo que se pidió
);

-- ===================== PEDIDOS WEB (CARRITO DEL CATÁLOGO) =====================
-- Lo que los clientes arman en el carrito y envían. No descuenta stock:
-- desde el panel (pestaña "Pedidos web") se pasa a presupuesto y ahí se descuenta.
create table if not exists solicitudes(
  id bigint generated always as identity primary key,
  fecha timestamptz default now(),
  cliente text not null,
  telefono text,
  nota text,
  total numeric(12,2),                      -- total estimado con los precios del momento
  lineas jsonb not null,                    -- [{id, codigo, nombre, precio, cantidad, reservado}]
  estado text not null default 'nuevo',     -- nuevo · presupuestado · descartado
  presupuesto_id bigint
);
create index if not exists solicitudes_estado_idx on solicitudes(estado, id);

-- ===================== PERMISOS =====================
alter table solicitudes enable row level security;
drop policy if exists "admin solicitudes" on solicitudes;
-- Solo tú (con sesión) ves y cambias los pedidos web. Los clientes los envían con enviar_solicitud().
create policy "admin solicitudes" on solicitudes for all to authenticated using (true) with check (true);
alter table productos enable row level security;
alter table presupuestos enable row level security;
alter table pedidos enable row level security;
drop policy if exists "admin pedidos" on pedidos;
create policy "admin pedidos" on pedidos for all to authenticated using (true) with check (true);
alter table sectores enable row level security;
drop policy if exists "ver sectores" on sectores;
drop policy if exists "admin sectores" on sectores;
create policy "ver sectores" on sectores for select using (true);
create policy "admin sectores" on sectores for all to authenticated using (true) with check (true);
drop policy if exists "catalogo publico" on productos;
drop policy if exists "admin productos" on productos;
drop policy if exists "admin presupuestos" on presupuestos;
-- Cualquiera puede VER el catálogo; solo usuarios con sesión pueden modificar
create policy "catalogo publico" on productos for select using (activo and not borrado);
create policy "admin productos" on productos for all to authenticated using (true) with check (true);
create policy "admin presupuestos" on presupuestos for all to authenticated using (true) with check (true);
-- Los visitantes no pueden ver tu costo ni tu % de ganancia
revoke select on productos from anon;
grant select (id, codigo, nombre, precio, imagen, stock, activo, borrado, sector_id, minimo) on productos to anon;

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
drop trigger if exists sectores_cambio on sectores;
create trigger sectores_cambio after insert or update or delete on sectores
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
-- Si viene de un pedido web (p_solicitud), primero se devuelve lo que ese pedido tenía reservado
-- y después se descuenta lo del presupuesto: así no se descuenta dos veces aunque cambies cantidades.
drop function if exists crear_presupuesto(text, jsonb);
drop function if exists crear_presupuesto(text, jsonb, bigint);
create function crear_presupuesto(p_cliente text, p_lineas jsonb, p_solicitud bigint default null)
returns jsonb language plpgsql as $$
declare l jsonb; n bigint; t numeric := 0; c numeric; d numeric; pr record; lineas jsonb := '[]'; s record;
begin
  if p_solicitud is not null then
    select * into s from solicitudes where id = p_solicitud for update;
    if not found then raise exception 'No existe el pedido web Nº %', p_solicitud; end if;
    if s.estado <> 'nuevo' then raise exception 'El pedido web Nº % ya no está pendiente (%)', p_solicitud, s.estado; end if;
    for l in select * from jsonb_array_elements(s.lineas) loop
      update productos set stock = stock + coalesce((l->>'reservado')::numeric, 0)
        where id = (l->>'id')::bigint and coalesce((l->>'reservado')::numeric, 0) > 0;
    end loop;
  end if;
  for l in select * from jsonb_array_elements(p_lineas) loop
    c := (l->>'cantidad')::numeric;
    if c is null or c < 0 then raise exception 'Cantidad no válida: %', l->>'nombre'; end if;
    select id, codigo, nombre, precio, stock into pr from productos where id = (l->>'id')::bigint for update;
    if not found then raise exception 'Producto no encontrado: %', l->>'nombre'; end if;
    d := least(c, greatest(pr.stock, 0));
    if d > 0 then update productos set stock = stock - d where id = pr.id; end if;
    lineas := lineas || jsonb_build_object('id', pr.id, 'codigo', pr.codigo, 'nombre', pr.nombre,
                                           'precio', pr.precio, 'cantidad', c, 'disponible', d);
    t := t + d * pr.precio;
  end loop;
  insert into presupuestos(cliente, total, lineas) values (p_cliente, t, lineas) returning id into n;
  if p_solicitud is not null then
    update solicitudes set estado = 'presupuestado', presupuesto_id = n where id = p_solicitud;
  end if;
  return jsonb_build_object('id', n, 'total', t, 'lineas', lineas);
end $$;

-- Importar Excel de cantidades: SUMA la cantidad al stock que ya tiene cada producto.
-- Recibe [{id, cantidad}] (el panel ya reconoció cada fila). Los productos en la papelera se ignoran.
create or replace function sumar_stock(p_filas jsonb)
returns int language plpgsql as $$
declare f jsonb; n int := 0;
begin
  for f in select * from jsonb_array_elements(p_filas) loop
    update productos set stock = stock + (f->>'cantidad')::numeric
      where id = (f->>'id')::bigint and not borrado;
    if found then n := n + 1; end if;
  end loop;
  return n;
end $$;

-- Carrito del catálogo: el cliente envía su pedido. Los precios y nombres se toman de la base
-- (no del navegador) y se ignoran los productos ocultos o en la papelera.
-- El stock se RESERVA en el momento (se descuenta lo que haya; queda como "reservado" en cada línea),
-- así el catálogo muestra enseguida lo que queda. Al pasarlo a presupuesto no se descuenta otra vez;
-- si se descarta, el stock vuelve.
-- Límites para evitar abusos: textos cortos, hasta 300 productos y 30 pedidos cada 10 minutos.
create or replace function enviar_solicitud(p_cliente text, p_telefono text, p_nota text, p_lineas jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare l jsonb; c numeric; d numeric; pr record; lineas jsonb := '[]'; t numeric := 0; n bigint; falta boolean := false;
begin
  p_cliente := left(trim(coalesce(p_cliente, '')), 100);
  p_telefono := left(trim(coalesce(p_telefono, '')), 40);
  p_nota := left(trim(coalesce(p_nota, '')), 1000);
  if p_cliente = '' then raise exception 'Falta el nombre'; end if;
  if jsonb_typeof(p_lineas) is distinct from 'array' or jsonb_array_length(p_lineas) = 0 then
    raise exception 'El carrito está vacío'; end if;
  if jsonb_array_length(p_lineas) > 300 then raise exception 'Demasiados productos en el carrito'; end if;
  if (select count(*) from solicitudes where fecha > now() - interval '10 minutes') >= 30 then
    raise exception 'Hay muchos pedidos seguidos. Probá de nuevo en unos minutos'; end if;
  for l in select * from jsonb_array_elements(p_lineas) loop
    c := (l->>'cantidad')::numeric;
    if c is null or c <= 0 or c > 100000 then raise exception 'Cantidad no válida'; end if;
    select id, codigo, nombre, precio, stock, minimo into pr from productos
      where id = (l->>'id')::bigint and activo and not borrado for update;
    continue when not found;
    if coalesce(pr.minimo, 0) > c then c := pr.minimo; end if;  -- respeta la compra mínima
    d := least(c, greatest(pr.stock, 0));
    if d > 0 then update productos set stock = stock - d where id = pr.id; end if;
    if d < c then falta := true; end if;
    lineas := lineas || jsonb_build_object('id', pr.id, 'codigo', pr.codigo, 'nombre', pr.nombre,
                                           'precio', pr.precio, 'cantidad', c, 'reservado', d);
    t := t + c * pr.precio;
  end loop;
  if jsonb_array_length(lineas) = 0 then raise exception 'Los productos del carrito ya no están disponibles'; end if;
  insert into solicitudes(cliente, telefono, nota, total, lineas)
    values (p_cliente, nullif(p_telefono, ''), nullif(p_nota, ''), t, lineas) returning id into n;
  return jsonb_build_object('id', n, 'total', t, 'falta', falta);
end $$;
revoke execute on function enviar_solicitud(text, text, text, jsonb) from public;
grant execute on function enviar_solicitud(text, text, text, jsonb) to anon, authenticated;

-- Pedidos web: descartar devuelve al stock lo reservado; recuperar un descartado lo vuelve a reservar.
create or replace function estado_solicitud(p_id bigint, p_estado text)
returns void language plpgsql as $$
declare s record; l jsonb; c numeric; d numeric; st numeric; nuevas jsonb := '[]';
begin
  select * into s from solicitudes where id = p_id for update;
  if not found then raise exception 'No existe el pedido web Nº %', p_id; end if;
  if s.estado = 'nuevo' and p_estado = 'descartado' then
    for l in select * from jsonb_array_elements(s.lineas) loop
      update productos set stock = stock + coalesce((l->>'reservado')::numeric, 0)
        where id = (l->>'id')::bigint and coalesce((l->>'reservado')::numeric, 0) > 0;
      nuevas := nuevas || jsonb_set(l, '{reservado}', '0');
    end loop;
  elsif s.estado = 'descartado' and p_estado = 'nuevo' then
    for l in select * from jsonb_array_elements(s.lineas) loop
      c := (l->>'cantidad')::numeric;
      select stock into st from productos where id = (l->>'id')::bigint for update;
      d := case when found then least(c, greatest(st, 0)) else 0 end;
      if d > 0 then update productos set stock = stock - d where id = (l->>'id')::bigint; end if;
      nuevas := nuevas || jsonb_set(l, '{reservado}', to_jsonb(d));
    end loop;
  else
    raise exception 'No se puede pasar el pedido de "%" a "%"', s.estado, p_estado;
  end if;
  update solicitudes set estado = p_estado, lineas = nuevas where id = p_id;
end $$;
revoke execute on function estado_solicitud(bigint, text) from public, anon;
grant execute on function estado_solicitud(bigint, text) to authenticated;

-- Pedidos web: cambiar la cantidad de un producto de un pedido nuevo (0 = quitarlo).
-- Devuelve al stock lo que tenía reservado y vuelve a reservar la cantidad nueva (lo que haya).
create or replace function cantidad_solicitud(p_id bigint, p_producto bigint, p_cantidad numeric)
returns jsonb language plpgsql as $$
declare s record; l jsonb; v_nuevas jsonb := '[]'; v_total numeric := 0; v_r numeric; v_d numeric; v_st numeric; v_hay boolean := false;
begin
  if p_cantidad is null or p_cantidad < 0 or p_cantidad > 100000 then raise exception 'Cantidad no válida'; end if;
  select * into s from solicitudes where id = p_id for update;
  if not found then raise exception 'No existe el pedido web Nº %', p_id; end if;
  if s.estado <> 'nuevo' then raise exception 'Solo se pueden editar pedidos nuevos (este está %)', s.estado; end if;
  for l in select * from jsonb_array_elements(s.lineas) loop
    if (l->>'id')::bigint = p_producto then
      v_hay := true;
      v_r := coalesce((l->>'reservado')::numeric, 0);
      update productos set stock = stock + v_r where id = p_producto returning stock into v_st;
      v_d := least(p_cantidad, greatest(coalesce(v_st, 0), 0));
      if v_d > 0 then update productos set stock = stock - v_d where id = p_producto returning stock into v_st; end if;
      if p_cantidad > 0 then
        l := jsonb_set(jsonb_set(l, '{cantidad}', to_jsonb(p_cantidad)), '{reservado}', to_jsonb(v_d));
      else
        l := null;
      end if;
    end if;
    if l is not null then
      v_nuevas := v_nuevas || l;
      v_total := v_total + (l->>'cantidad')::numeric * (l->>'precio')::numeric;
    end if;
  end loop;
  if not v_hay then raise exception 'Ese producto ya no está en el pedido'; end if;
  if jsonb_array_length(v_nuevas) = 0 then raise exception 'No se puede dejar el pedido vacío: usa Descartar'; end if;
  update solicitudes set lineas = v_nuevas, total = v_total where id = p_id;
  return jsonb_build_object('lineas', v_nuevas, 'total', v_total, 'stock', v_st);
end $$;
revoke execute on function cantidad_solicitud(bigint, bigint, numeric) from public, anon;
grant execute on function cantidad_solicitud(bigint, bigint, numeric) to authenticated;

revoke execute on function importar_productos(jsonb, numeric) from public, anon;
revoke execute on function sumar_stock(jsonb) from public, anon;
grant execute on function sumar_stock(jsonb) to authenticated;
revoke execute on function crear_presupuesto(text, jsonb, bigint) from public, anon;
grant execute on function importar_productos(jsonb, numeric) to authenticated;
grant execute on function crear_presupuesto(text, jsonb, bigint) to authenticated;
