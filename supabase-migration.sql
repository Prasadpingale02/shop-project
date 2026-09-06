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
