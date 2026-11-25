-- ExamNet Feedback Portal: Complete Schema & Password-Only Admin RPC
-- Replace 'Benex7818' with your own strong password before running.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.examnet_feedback (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  full_name text not null,
  course_year text not null,
  room_number text not null,
  device text not null,
  internet text not null,
  rating_details jsonb not null default '{}'::jsonb,
  lag text not null,
  image_speed text not null,
  issues text[] not null default '{}',
  images_missing text,
  internet_impact text,
  ease_of_use text,
  readability text,
  comfort text,
  liked text,
  problems text,
  suggestions text,
  additional text
);

-- If upgrading an existing examnet_feedback table, ensure all columns exist:
alter table public.examnet_feedback
  add column if not exists rating_details jsonb not null default '{}'::jsonb,
  add column if not exists lag text not null default '',
  add column if not exists image_speed text not null default '',
  add column if not exists issues text[] not null default '{}',
  add column if not exists images_missing text,
  add column if not exists internet_impact text,
  add column if not exists ease_of_use text,
  add column if not exists readability text,
  add column if not exists comfort text,
  add column if not exists liked text,
  add column if not exists problems text,
  add column if not exists suggestions text,
  add column if not exists additional text;

-- Helpful indexes for filtering and sorting in admin analytics
create index if not exists idx_examnet_feedback_created_at
  on public.examnet_feedback (created_at desc);

create index if not exists idx_examnet_feedback_room_device
  on public.examnet_feedback (room_number, device);

alter table public.examnet_feedback enable row level security;

-- Explicit grants are required in addition to RLS policies.
grant usage on schema public to anon, authenticated;
grant insert on table public.examnet_feedback to anon, authenticated;

drop policy if exists "Public may submit feedback" on public.examnet_feedback;
drop policy if exists "Anyone can submit feedback" on public.examnet_feedback;
drop policy if exists "Admin may read feedback" on public.examnet_feedback;
drop policy if exists "Admin can view feedback" on public.examnet_feedback;

create policy "Public may submit feedback"
  on public.examnet_feedback
  for insert
  to anon, authenticated
  with check (true);

-- Private schema for admin password hash (never exposed to browser clients)
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.examnet_admin_secret (
  id int primary key check (id = 1),
  password_hash text not null
);

revoke all on private.examnet_admin_secret from public, anon, authenticated;

-- Change this password phrase before executing this SQL!
insert into private.examnet_admin_secret (id, password_hash)
values (1, extensions.crypt('Benex7818', extensions.gen_salt('bf', 12)))
on conflict (id) do update set password_hash = excluded.password_hash;

create or replace function public.examnet_admin_feedback(p_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  saved_hash text;
begin
  select password_hash into saved_hash
  from private.examnet_admin_secret
  where id = 1;

  if saved_hash is null or p_password is null or saved_hash <> extensions.crypt(p_password, saved_hash) then
    raise exception 'Unauthorized';
  end if;

  return coalesce(
    (
      select jsonb_agg(to_jsonb(f) order by f.created_at desc)
      from public.examnet_feedback f
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.examnet_admin_feedback(text) from public;
grant execute on function public.examnet_admin_feedback(text) to anon, authenticated;


create or replace function public.examnet_admin_reset_feedback(p_password text)
returns bigint
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  saved_hash text;
  deleted_count bigint;
begin
  select password_hash into saved_hash
  from private.examnet_admin_secret
  where id = 1;

  if saved_hash is null or p_password is null or saved_hash <> extensions.crypt(p_password, saved_hash) then
    raise exception 'Unauthorized';
  end if;

  delete from public.examnet_feedback;
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

revoke all on function public.examnet_admin_reset_feedback(text) from public;
grant execute on function public.examnet_admin_reset_feedback(text) to anon, authenticated;
