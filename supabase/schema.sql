create table if not exists public.allowed_users (
  github_username text primary key,
  role text not null default 'member' check (role in ('admin', 'member')),
  created_at timestamptz not null default now()
);

alter table public.allowed_users enable row level security;

create or replace function public.is_setup_hub_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.allowed_users
    where lower(github_username) = lower(coalesce(auth.jwt() -> 'user_metadata' ->> 'user_name', ''))
      and role = 'admin'
  );
$$;

revoke all on function public.is_setup_hub_admin() from public;
grant execute on function public.is_setup_hub_admin() to authenticated;

create policy "allowed users can read themselves"
on public.allowed_users for select
to authenticated
using (
  lower(github_username) = lower(coalesce(auth.jwt() -> 'user_metadata' ->> 'user_name', ''))
  or public.is_setup_hub_admin()
);

create policy "admins can add members"
on public.allowed_users for insert
to authenticated
with check (
  public.is_setup_hub_admin()
);

create policy "admins can remove members"
on public.allowed_users for delete
to authenticated
using (
  public.is_setup_hub_admin()
);

-- 创建表后，在 Supabase SQL Editor 运行一次：
-- insert into public.allowed_users (github_username, role) values ('91vrvd', 'admin');
