-- Pega todo esto en Supabase > SQL Editor > Run
create table productos(
  id bigint generated always as identity primary key,
  codigo text unique not null,
  nombre text not null,
  precio numeric(12,2) not null default 0,
  stock numeric(12,2) not null default 0,
  activo boolean not null default true
);
create table presupuestos(
  id bigint generated always as identity primary key,
  fecha timestamptz default now(),
  cliente text,
  total numeric(12,2),
  lineas jsonb
);
alter table productos enable row level security;
alter table presupuestos enable row level security;
-- Cualquiera puede VER el catálogo; solo usuarios con sesión pueden modificar
create policy "catalogo publico" on productos for select using (activo);
create policy "admin productos" on productos for all to authenticated using (true) with check (true);
create policy "admin presupuestos" on presupuestos for all to authenticated using (true) with check (true);

-- Crea el presupuesto y descuenta el stock en una sola operación.
-- Si algún producto no tiene stock suficiente, no se guarda nada.
create or replace function crear_presupuesto(p_cliente text, p_lineas jsonb)
returns bigint language plpgsql as $$
declare l jsonb; n bigint; t numeric := 0;
begin
  for l in select * from jsonb_array_elements(p_lineas) loop
    update productos set stock = stock - (l->>'cantidad')::numeric
      where id = (l->>'id')::bigint and stock >= (l->>'cantidad')::numeric;
    if not found then raise exception 'Stock insuficiente: %', l->>'nombre'; end if;
    t := t + (l->>'cantidad')::numeric * (l->>'precio')::numeric;
  end loop;
  insert into presupuestos(cliente, total, lineas) values (p_cliente, t, p_lineas) returning id into n;
  return n;
end $$;
