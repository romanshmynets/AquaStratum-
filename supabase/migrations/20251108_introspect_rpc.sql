-- Introspection helpers exposed via PostgREST (RPC)
create schema if not exists introspect;

-- Tables
create or replace function introspect.tables()
returns table (schema_name text, table_name text)
language sql
security definer
set search_path = public
stable
as $$
  select table_schema::text as schema_name,
         table_name::text   as table_name
  from information_schema.tables
  where table_type = 'BASE TABLE'
    and table_schema not in ('pg_catalog','information_schema','pg_toast','extensions')
  order by 1,2;
$$;

-- Columns
create or replace function introspect.columns()
returns table (schema_name text, table_name text, column_name text, data_type text, is_nullable text, ordinal_position int)
language sql
security definer
set search_path = public
stable
as $$
  select c.table_schema::text  as schema_name,
         c.table_name::text    as table_name,
         c.column_name::text   as column_name,
         c.data_type::text     as data_type,
         c.is_nullable::text   as is_nullable,
         c.ordinal_position::int as ordinal_position
  from information_schema.columns c
  join information_schema.tables t
    on t.table_schema = c.table_schema and t.table_name = c.table_name
  where t.table_type = 'BASE TABLE'
    and t.table_schema not in ('pg_catalog','information_schema','pg_toast','extensions')
  order by 1,2,6;
$$;

-- Primary keys
create or replace function introspect.pks()
returns table (schema_name text, table_name text, pk_columns text)
language sql
security definer
set search_path = public
stable
as $$
  with pk as (
    select n.nspname as schema_name,
           c.relname as table_name,
           string_agg(a.attname, ',' order by a.attnum) as pk_columns
    from pg_index i
    join pg_class c on c.oid = i.indrelid and i.indisprimary
    join pg_namespace n on n.oid = c.relnamespace
    join pg_attribute a on a.attrelid = c.oid and a.attnum = any(i.indkey)
    where n.nspname not in ('pg_catalog','information_schema','pg_toast','extensions')
    group by 1,2
  )
  select schema_name, table_name, pk_columns from pk order by 1,2;
$$;

-- Foreign keys
create or replace function introspect.fks()
returns table (
  src_schema text, src_table text, src_columns text,
  tgt_schema text, tgt_table text, tgt_columns text,
  constraint_name text
)
language sql
security definer
set search_path = public
stable
as $$
  select
    ns1.nspname::text as src_schema,
    c1.relname::text  as src_table,
    string_agg(a1.attname, ',' order by a1.attnum)::text as src_columns,
    ns2.nspname::text as tgt_schema,
    c2.relname::text  as tgt_table,
    string_agg(a2.attname, ',' order by a2.attnum)::text as tgt_columns,
    con.conname::text as constraint_name
  from pg_constraint con
  join pg_class c1 on c1.oid = con.conrelid
  join pg_namespace ns1 on ns1.oid = c1.relnamespace
  join pg_class c2 on c2.oid = con.confrelid
  join pg_namespace ns2 on ns2.oid = c2.relnamespace
  join unnest(con.conkey)  with ordinality as ck(attnum, ord) on true
  join unnest(con.confkey) with ordinality as fk(attnum, ord) on ord=ord
  join pg_attribute a1 on a1.attrelid = c1.oid and a1.attnum = ck.attnum
  join pg_attribute a2 on a2.attrelid = c2.oid and a2.attnum = fk.attnum
  where con.contype = 'f'
    and ns1.nspname not in ('pg_catalog','information_schema','pg_toast','extensions')
    and ns2.nspname not in ('pg_catalog','information_schema','pg_toast','extensions')
  group by 1,2,4,5,7
  order by 1,2,7;
$$;

-- Indexes
create or replace function introspect.indexes()
returns table (schema_name text, table_name text, index_name text, index_def text)
language sql
security definer
set search_path = public
stable
as $$
  select schemaname::text as schema_name,
         tablename::text  as table_name,
         indexname::text  as index_name,
         indexdef::text   as index_def
  from pg_indexes
  where schemaname not in ('pg_catalog','information_schema','pg_toast','extensions')
  order by 1,2,3;
$$;

-- Views
create or replace function introspect.views()
returns table (schema_name text, view_name text)
language sql
security definer
set search_path = public
stable
as $$
  select table_schema::text as schema_name,
         table_name::text   as view_name
  from information_schema.views
  where table_schema not in ('pg_catalog','information_schema')
  order by 1,2;
$$;

grant usage on schema introspect to postgres, anon, authenticated, service_role;
grant execute on all functions in schema introspect to postgres, anon, authenticated, service_role;
alter default privileges in schema introspect grant execute on functions to postgres, anon, authenticated, service_role;
