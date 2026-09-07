-- Run once in Supabase SQL Editor before using product images and the payment QR.
alter table public.products add column if not exists image_url text;

create table if not exists public.store_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

alter table public.store_settings enable row level security;
drop policy if exists "Public can read store settings" on public.store_settings;
drop policy if exists "Authenticated admins can manage store settings" on public.store_settings;
create policy "Public can read store settings"
  on public.store_settings for select using (true);
create policy "Authenticated admins can manage store settings"
  on public.store_settings for all to authenticated using (true) with check (true);

insert into storage.buckets (id, name, public)
values ('site-assets', 'site-assets', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can view site assets" on storage.objects;
drop policy if exists "Authenticated admins can upload site assets" on storage.objects;
drop policy if exists "Authenticated admins can update site assets" on storage.objects;
create policy "Public can view site assets"
  on storage.objects for select using (bucket_id = 'site-assets');
create policy "Authenticated admins can upload site assets"
  on storage.objects for insert to authenticated with check (bucket_id = 'site-assets');
create policy "Authenticated admins can update site assets"
  on storage.objects for update to authenticated using (bucket_id = 'site-assets');

-- Per-phone order cooldown to limit rapid repeat orders.
create table if not exists public.order_rate_limits (
  phone text primary key,
  last_order_at timestamptz not null
);

alter table public.order_rate_limits enable row level security;

create or replace function public.reserve_order_slot(p_phone text, p_cooldown_minutes integer default 10)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := now();
  affected_rows integer;
begin
  insert into public.order_rate_limits(phone, last_order_at)
  values (p_phone, v_now)
  on conflict (phone) do update
    set last_order_at = excluded.last_order_at
    where public.order_rate_limits.last_order_at
      <= v_now - make_interval(mins => p_cooldown_minutes);
  get diagnostics affected_rows = row_count;
  return affected_rows = 1;
end;
$$;

revoke all on function public.reserve_order_slot(text, integer) from public;
grant execute on function public.reserve_order_slot(text, integer) to anon, authenticated;
