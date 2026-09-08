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

-- =====================================================================
-- Jalgaon catalogue fields. Prices are intentionally nullable/zero for
-- new catalogue rows: the owner must enter current store prices in the
-- dashboard before publishing them.
-- =====================================================================
alter table public.products add column if not exists product_name text;
alter table public.products add column if not exists marathi_name text;
alter table public.products add column if not exists subcategory text;
alter table public.products add column if not exists brand text;
alter table public.products add column if not exists description text;
alter table public.products add column if not exists weight text;
alter table public.products add column if not exists purchase_price numeric(12,2);
alter table public.products add column if not exists selling_price numeric(12,2);
alter table public.products add column if not exists discount numeric(5,2) default 0;
alter table public.products add column if not exists stock_quantity numeric(12,3) default 0;
alter table public.products add column if not exists low_stock_threshold numeric(12,3) default 5;
alter table public.products add column if not exists is_available boolean default false;
alter table public.products add column if not exists is_featured boolean default false;
alter table public.products add column if not exists is_popular boolean default false;
alter table public.products add column if not exists is_offer boolean default false;
alter table public.products add column if not exists is_seasonal boolean default false;

update public.products
set product_name = coalesce(product_name, name),
    selling_price = coalesce(selling_price, price),
    is_available = coalesce(is_available, active),
    stock_quantity = coalesce(stock_quantity, case when active then 10 else 0 end),
    low_stock_threshold = coalesce(low_stock_threshold, 5),
    discount = coalesce(discount, case when mrp > price and mrp > 0 then round((mrp - price) * 100 / mrp, 2) else 0 end);

create or replace function public.sync_product_compatibility()
returns trigger language plpgsql as $$
begin
  if new.product_name is null or new.product_name = '' then new.product_name := new.name; end if;
  if new.name is null or new.name = '' then new.name := new.product_name; end if;
  if new.selling_price is null and new.price is not null then new.selling_price := new.price; end if;
  if new.price is null and new.selling_price is not null then new.price := new.selling_price; end if;
  if new.is_available is null then new.is_available := coalesce(new.active, false); end if;
  new.active := coalesce(new.is_available, new.active, false);
  new.discount := coalesce(new.discount, case when new.mrp > new.selling_price and new.mrp > 0 then round((new.mrp - new.selling_price) * 100 / new.mrp, 2) else 0 end);
  return new;
end;
$$;

drop trigger if exists products_sync_compatibility on public.products;
create trigger products_sync_compatibility before insert or update on public.products
for each row execute function public.sync_product_compatibility();

create index if not exists products_category_available_idx on public.products(category, is_available);
create index if not exists products_popular_idx on public.products(is_popular) where is_popular = true;
create index if not exists products_offer_idx on public.products(is_offer) where is_offer = true;

-- A realistic Jalgaon kirana catalogue template. These rows are unpublished
-- until the owner enters current prices, stock and images in the dashboard.
with catalogue(category, names) as (
  values
  ('Rice & Grains', array['Basmati Rice','Kolam Rice','Indrayani Rice','Sona Masoori Rice','Regular Rice','Jowar','Bajra','Brown Rice','Poha Thick','Poha Thin']),
  ('Atta & Flour', array['Whole Wheat Atta','Multigrain Atta','Jowar Flour','Bajra Flour','Besan','Rice Flour','Maida','Ragi Flour','Bhakri Flour','Thalipeeth Bhajani']),
  ('Dal & Pulses', array['Tur Dal','Moong Dal','Moong Whole','Masoor Dal','Urad Dal','Chana Dal','Matki','Moth Dal','Kabuli Chana','Rajma']),
  ('Oil & Ghee', array['Groundnut Oil','Sunflower Oil','Soya Oil','Mustard Oil','Rice Bran Oil','Cottonseed Oil','Coconut Oil','Til Oil','Cow Ghee','Vanaspati']),
  ('Sugar, Salt & Jaggery', array['Sugar','Iodised Salt','Rock Salt','Black Salt','Jaggery','Kolhapuri Jaggery','Jaggery Powder','Sugar Cubes','Mishri','Date Syrup']),
  ('Masala & Spices', array['Goda Masala','Garam Masala','Kitchen King Masala','Turmeric Powder','Red Chilli Powder','Coriander Powder','Cumin Powder','Black Pepper','Cumin Seeds','Mustard Seeds']),
  ('Biscuits & Snacks', array['Parle-G Biscuits','Marie Biscuits','Good Day Biscuits','Britannia Tiger','Monaco Biscuits','Cream Biscuits','Khari','Bhujia','Aloo Bhujia','Potato Chips']),
  ('Tea & Coffee', array['Tata Tea','Red Label Tea','Wagh Bakri Tea','Society Tea','Brooke Bond Tea','Green Tea','Instant Coffee','Filter Coffee','Coffee Powder','Tea Premix']),
  ('Beverages', array['Packaged Drinking Water','Maaza','Frooti','Real Juice','Tropicana Juice','Coca-Cola','Thums Up','Sprite','Limca','Glucose Drink']),
  ('Dairy & Breakfast', array['Milk','Curd','Buttermilk','Paneer','Butter','Cheese Slices','Bread','Eggs','Corn Flakes','Oats']),
  ('Personal Care', array['Bath Soap','Handwash','Shampoo Sachet','Shampoo Bottle','Hair Oil','Toothpaste','Toothbrush','Face Wash','Talcum Powder','Body Lotion']),
  ('Household Cleaning', array['Laundry Detergent','Dishwash Bar','Dishwash Liquid','Floor Cleaner','Toilet Cleaner','Phenyl','Bleaching Powder','Scrub Pad','Mosquito Coil','Garbage Bags']),
  ('Baby Care', array['Baby Diapers','Baby Wipes','Baby Soap','Baby Shampoo','Baby Oil','Baby Lotion','Baby Powder','Cerelac Wheat','Feeding Bottle','Cotton Buds']),
  ('Fresh Vegetables', array['Potato','Onion','Tomato','Green Chilli','Coriander','Ginger','Garlic','Lemon','Brinjal','Okra']),
  ('Fruits', array['Banana','Mango','Orange','Sweet Lime','Apple','Papaya','Guava','Pomegranate','Watermelon','Grapes']),
  ('Pooja & Festival Items', array['Agarbatti','Camphor','Cotton Wicks','Diya','Pooja Oil','Kumkum','Haldi Kumkum','Rangoli Powder','Coconut','Betel Nuts']),
  ('Stationery & Daily Needs', array['Ball Pen','Pencil','Eraser','Notebook','Writing Pad','School Notebook','Matchbox','Battery AA','Battery AAA','LED Bulb']),
  ('Dry Fruits & Nuts', array['Peanut','Almonds','Cashew','Raisins','Walnut','Pistachio','Dry Coconut','Anjeer','Dates','Flax Seeds']),
  ('Instant Food', array['Maggi Noodles','Yippee Noodles','Pasta','Vermicelli','Instant Poha','Instant Upma','Soup Pack','Ready Mix Dosa','Ready Mix Idli','Papad']),
  ('Packaged Food', array['Tomato Ketchup','Chilli Sauce','Soya Sauce','Pickle','Papad Packet','Chutney Powder','Jam','Honey','Peanut Butter','Coconut Milk'])
),
items as (
  select category, unnest(names) as item from catalogue
)
insert into public.products (
  name, product_name, category, subcategory, brand, description, unit, weight,
  price, selling_price, purchase_price, mrp, discount, stock_quantity,
  low_stock_threshold, active, is_available, is_featured, is_popular, is_offer, is_seasonal
)
select item, item, category, null, 'To be set', 'Catalogue item - update current store price and image before publishing.',
       case when category in ('Fresh Vegetables','Fruits') then 'kg' else 'pack' end,
       case when category in ('Fresh Vegetables','Fruits') then '1 kg' else 'standard pack' end,
       0, 0, null, null, 0, 0, 5, false, false, false, false, false,
       category in ('Fresh Vegetables','Fruits') and item in ('Mango','Grapes','Watermelon')
from items
where not exists (
  select 1 from public.products p where lower(coalesce(p.product_name, p.name)) = lower(items.item)
);
