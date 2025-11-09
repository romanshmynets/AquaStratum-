-- Extensions
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- Schema
create schema if not exists app;

-- Tables
create table if not exists app.users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  full_name text,
  created_at timestamptz not null default now()
);

-- RLS
alter table app.users enable row level security;

drop policy if exists "users_can_read_self" on app.users;
create policy "users_can_read_self"
on app.users for select
using (auth.uid() = id);

-- Indexes
create index if not exists idx_users_email on app.users(email);
