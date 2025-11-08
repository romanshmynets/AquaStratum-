-- Extensions commonly enabled in Supabase (safe if already present)
create extension if not exists pgcrypto;
create extension if not exists uuid-ossp;

-- Separate application schema
create schema if not exists app;

-- Example table (adjust or extend later)
create table if not exists app.users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  full_name text,
  created_at timestamptz not null default now()
);

-- RLS (Row Level Security) – enable and give a minimal policy example
alter table app.users enable row level security;

-- Drop/create policy to keep it idempotent
drop policy if exists "users_can_read_self" on app.users;
create policy "users_can_read_self"
on app.users for select
using (auth.uid() = id);

-- Helpful index
create index if not exists idx_users_email on app.users (email);

-- Add more tables below (use the same pattern: IF NOT EXISTS + DROP POLICY/CREATE POLICY)
