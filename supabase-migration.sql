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
alter table public.products add column if not exists product_type text default 'grocery';

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

-- Requested 50-product starter catalogue. Prices and images remain unset so
-- the owner can enter current retail prices and upload the correct product
-- photo from the admin dashboard before making each row available.
with requested(name, marathi_name, category, unit, weight) as (
  values
  ('Rice','तांदूळ','Rice & Grains','kg','1 kg'),
  ('Wheat','गहू','Rice & Grains','kg','1 kg'),
  ('Atta','पीठ','Atta & Flour','kg','1 kg'),
  ('Maida',null,'Atta & Flour','kg','1 kg'),
  ('Besan','बेसन','Atta & Flour','kg','1 kg'),
  ('Toor Dal','तूर डाळ','Dal & Pulses','kg','1 kg'),
  ('Moong Dal','मूग डाळ','Dal & Pulses','kg','1 kg'),
  ('Chana Dal','हरभरा डाळ','Dal & Pulses','kg','1 kg'),
  ('Masoor Dal','मसूर डाळ','Dal & Pulses','kg','1 kg'),
  ('Urad Dal','उडीद डाळ','Dal & Pulses','kg','1 kg'),
  ('Sugar','साखर','Sugar, Salt & Jaggery','kg','1 kg'),
  ('Salt','मीठ','Sugar, Salt & Jaggery','kg','1 kg'),
  ('Jaggery','गूळ','Sugar, Salt & Jaggery','kg','1 kg'),
  ('Sunflower Oil','सूर्यफूल तेल','Oil & Ghee','litre','1 L'),
  ('Soybean Oil','सोयाबीन तेल','Oil & Ghee','litre','1 L'),
  ('Ghee','तूप','Oil & Ghee','pack','500 ml'),
  ('Turmeric','हळद','Masala & Spices','pack','100 g'),
  ('Chilli Powder','लाल तिखट','Masala & Spices','pack','100 g'),
  ('Coriander Powder','धणे पावडर','Masala & Spices','pack','100 g'),
  ('Cumin','जिरे','Masala & Spices','pack','100 g'),
  ('Garam Masala',null,'Masala & Spices','pack','100 g'),
  ('Tea',null,'Tea & Coffee','pack','250 g'),
  ('Coffee',null,'Tea & Coffee','pack','100 g'),
  ('Biscuits',null,'Biscuits & Snacks','pack','100 g'),
  ('Potato Chips',null,'Biscuits & Snacks','pack','100 g'),
  ('Namkeen',null,'Biscuits & Snacks','pack','200 g'),
  ('Poha','पोहे','Rice & Grains','kg','1 kg'),
  ('Sabudana','साबुदाणा','Rice & Grains','kg','1 kg'),
  ('Noodles',null,'Instant Food','pack','70 g'),
  ('Pasta',null,'Instant Food','pack','500 g'),
  ('Bread',null,'Dairy & Breakfast','pack','400 g'),
  ('Milk',null,'Dairy & Breakfast','litre','1 L'),
  ('Curd','दही','Dairy & Breakfast','pack','500 g'),
  ('Butter',null,'Dairy & Breakfast','pack','100 g'),
  ('Cheese',null,'Dairy & Breakfast','pack','200 g'),
  ('Tomato','टोमॅटो','Fresh Vegetables','kg','1 kg'),
  ('Onion','कांदा','Fresh Vegetables','kg','1 kg'),
  ('Potato','बटाटा','Fresh Vegetables','kg','1 kg'),
  ('Green Chilli','हिरवी मिरची','Fresh Vegetables','kg','250 g'),
  ('Ginger','आले','Fresh Vegetables','kg','250 g'),
  ('Garlic','लसूण','Fresh Vegetables','kg','250 g'),
  ('Banana','केळी','Fruits','dozen','1 dozen'),
  ('Apple','सफरचंद','Fruits','kg','1 kg'),
  ('Shampoo',null,'Personal Care','pack','180 ml'),
  ('Bath Soap',null,'Personal Care','piece','100 g'),
  ('Toothpaste',null,'Personal Care','pack','100 g'),
  ('Washing Powder',null,'Household Cleaning','kg','1 kg'),
  ('Dishwash Liquid',null,'Household Cleaning','pack','500 ml'),
  ('Floor Cleaner',null,'Household Cleaning','pack','1 L'),
  ('Agarbatti','अगरबत्ती','Pooja & Festival Items','pack','1 pack')
)
insert into public.products (
  name, product_name, marathi_name, category, brand, description, unit, weight,
  price, selling_price, purchase_price, mrp, discount, stock_quantity,
  low_stock_threshold, image_url, active, is_available, is_featured, is_popular,
  is_offer, is_seasonal
)
select name, name, marathi_name, category, null,
       'Update current store price, stock and product photo in the admin dashboard.',
       unit, weight, 0, 0, null, null, 0, 0, 5, null, false, false,
       false, false, false, category in ('Fresh Vegetables','Fruits')
from requested r
where not exists (
  select 1 from public.products p
  where lower(coalesce(p.product_name, p.name)) = lower(r.name)
);

-- =====================================================================
-- Complete Pingale Provisions catalogue.
-- Prices are consumer selling prices for Jalgaon/Kasoda retail packs,
-- with a modest MRP buffer for packaging, transport and shop margin.
-- Re-running this block is safe: existing rows are updated by product name
-- and missing rows are inserted, without deleting any existing products.
-- =====================================================================
with catalogue(name, marathi_name, category, brand, price, mrp, unit, stock, low_stock) as (
  values
  ('Kolam Rice','कोलम तांदूळ','Rice','Local Kolam',78,88,'kg',55,8),
  ('Indrayani Rice','इंद्रायणी तांदूळ','Rice','Local Indrayani',72,82,'kg',45,8),
  ('Basmati Rice','बासमती तांदूळ','Rice','Local Basmati',125,145,'kg',35,6),
  ('Steam Rice','स्टीम तांदूळ','Rice','Local Steam',58,68,'kg',40,8),
  ('Sona Masoori Rice','सोना मसुरी तांदूळ','Rice','Local Sona Masoori',70,80,'kg',40,8),
  ('HMT Rice','एचएमटी तांदूळ','Rice','Local HMT',68,78,'kg',35,8),
  ('Broken Rice','तुकडा तांदूळ','Rice','Local',42,50,'kg',30,6),
  ('Wheat','गहू','Flour','Local',32,38,'kg',70,10),
  ('Wheat Flour / Atta','गव्हाचे पीठ / आटा','Flour','Local Chakki',48,55,'kg',60,10),
  ('Maida','मैदा','Flour','Local',44,52,'kg',35,6),
  ('Besan','बेसन','Flour','Local',92,105,'kg',35,6),
  ('Rava / Suji','रवा / सुजी','Flour','Local',52,60,'kg',30,6),
  ('Rice Flour','तांदळाचे पीठ','Flour','Local',58,68,'kg',25,5),
  ('Jowar Flour','ज्वारीचे पीठ','Flour','Local',72,82,'kg',30,6),
  ('Bajra Flour','बाजरीचे पीठ','Flour','Local',58,68,'kg',25,5),
  ('Multigrain Atta','मल्टीग्रेन आटा','Flour','Local',68,78,'kg',25,5),
  ('Toor Dal','तूर डाळ','Pulses','Local',165,185,'kg',45,8),
  ('Moong Dal','मूग डाळ','Pulses','Local',135,155,'kg',35,6),
  ('Moong Whole','संपूर्ण मूग','Pulses','Local',125,145,'kg',30,6),
  ('Chana Dal','हरभरा डाळ','Pulses','Local',82,95,'kg',40,8),
  ('Masoor Dal','मसूर डाळ','Pulses','Local',88,102,'kg',35,6),
  ('Urad Dal','उडीद डाळ','Pulses','Local',145,165,'kg',30,6),
  ('Urad Whole','संपूर्ण उडीद','Pulses','Local',135,155,'kg',25,5),
  ('Matki','मटकी','Pulses','Local',110,125,'kg',25,5),
  ('Masoor Whole','संपूर्ण मसूर','Pulses','Local',92,105,'kg',25,5),
  ('Kabuli Chana','काबुली चणा','Pulses','Local',135,155,'kg',25,5),
  ('Kala Chana','काळा चणा','Pulses','Local',88,102,'kg',30,6),
  ('Green Peas Dry','सुका हिरवा वाटाणा','Pulses','Local',115,132,'kg',20,4),
  ('Jowar','ज्वारी','Grains & Pulses','Local',38,45,'kg',45,8),
  ('Bajra','बाजरी','Grains & Pulses','Local',34,40,'kg',40,8),
  ('Maize','मका','Grains & Pulses','Local',30,36,'kg',35,6),
  ('Rajma','राजमा','Grains & Pulses','Local',145,165,'kg',25,5),
  ('Vatana','वाटाणा','Grains & Pulses','Local',105,120,'kg',25,5),
  ('Soybean','सोयाबीन','Grains & Pulses','Local',72,84,'kg',35,6),
  ('Moong','मूग','Grains & Pulses','Local',125,145,'kg',25,5),
  ('Chana','हरभरा','Grains & Pulses','Local',78,90,'kg',35,6),
  ('Sunflower Oil','सूर्यफूल तेल','Edible Oil','Fortune',145,158,'litre',45,8),
  ('Soybean Oil','सोयाबीन तेल','Edible Oil','Saffola',132,145,'litre',55,10),
  ('Groundnut Oil','शेंगदाणा तेल','Edible Oil','Local',178,195,'litre',35,6),
  ('Mustard Oil','मोहरी तेल','Edible Oil','Local',178,198,'litre',20,4),
  ('Rice Bran Oil','राइस ब्रॅन तेल','Edible Oil','Fortune',148,165,'litre',25,5),
  ('Palm Oil','पाम तेल','Edible Oil','Local',118,130,'litre',20,4),
  ('Coconut Oil','खोबरेल तेल','Edible Oil','Parachute',190,215,'500ml',25,5),
  ('Turmeric Powder','हळद पावडर','Spices','Local',32,38,'100g',40,8),
  ('Red Chilli Powder','लाल तिखट','Spices','Local',38,45,'100g',40,8),
  ('Coriander Powder','धणे पावडर','Spices','Local',28,34,'100g',35,7),
  ('Cumin / Jeera','जिरे','Spices','Local',45,52,'100g',30,6),
  ('Mustard Seeds / Mohri','मोहरी','Spices','Local',18,22,'100g',30,6),
  ('Fennel / Badishep','बडीशेप','Spices','Local',28,34,'100g',25,5),
  ('Ajwain / Ova','ओवा','Spices','Local',28,34,'100g',25,5),
  ('Black Pepper','काळी मिरी','Spices','Local',58,68,'50g',20,4),
  ('Cloves','लवंग','Spices','Local',48,58,'25g',20,4),
  ('Cinnamon','दालचिनी','Spices','Local',28,34,'50g',20,4),
  ('Cardamom','वेलची','Spices','Local',72,85,'25g',15,3),
  ('Bay Leaf','तमालपत्र','Spices','Local',12,16,'25g',20,4),
  ('Garam Masala','गरम मसाला','Spices','Everest',42,50,'100g',30,6),
  ('Goda Masala','गोडा मसाला','Spices','Badshah',48,58,'100g',30,6),
  ('Kitchen King Masala','किचन किंग मसाला','Spices','Everest',42,50,'100g',25,5),
  ('Hing','हिंग','Spices','Local',34,42,'10g',20,4),
  ('Sugar','साखर','Sugar','Local',46,52,'kg',90,15),
  ('Jaggery / Gul','गूळ','Sugar','Local Kolhapuri',58,68,'kg',45,8),
  ('Jaggery Powder','गुळाची पावडर','Sugar','Local',68,78,'kg',25,5),
  ('Mishri','खडीसाखर','Sugar','Local',88,100,'kg',20,4),
  ('Brown Sugar','ब्राउन शुगर','Sugar','Local',95,110,'kg',15,3),
  ('Iodized Salt','आयोडाइज्ड मीठ','Salt','Tata',25,30,'kg',50,10),
  ('Rock Salt / Sendha Namak','सेंधव मीठ','Salt','Local',42,50,'kg',20,4),
  ('Black Salt','काळे मीठ','Salt','Local',35,42,'200g',20,4),
  ('Tea Powder','चहा पावडर','Tea & Coffee','Wagh Bakri',245,275,'500g',30,6),
  ('Green Tea','ग्रीन टी','Tea & Coffee','Local',135,155,'25 bags',15,3),
  ('Instant Coffee','इन्स्टंट कॉफी','Tea & Coffee','Bru',185,210,'100g',20,4),
  ('Filter Coffee','फिल्टर कॉफी','Tea & Coffee','Local',145,165,'200g',15,3),
  ('Parle-G','पार्ले-जी','Biscuits','Parle',10,12,'packet',80,15),
  ('Marie Biscuits','मेरी बिस्किट','Biscuits','Parle',30,35,'packet',50,10),
  ('Good Day','गुड डे','Biscuits','Britannia',30,35,'packet',50,10),
  ('Bourbon','बॉर्बन','Biscuits','Britannia',35,40,'packet',40,8),
  ('Cream Biscuits','क्रीम बिस्किट','Biscuits','Local',25,30,'packet',40,8),
  ('Glucose Biscuits','ग्लुकोज बिस्किट','Biscuits','Parle',20,25,'packet',50,10),
  ('Salt Biscuits','खारी बिस्किट','Biscuits','Local',30,35,'packet',35,7),
  ('Digestive Biscuits','डायजेस्टिव्ह बिस्किट','Biscuits','Britannia',45,50,'packet',30,6),
  ('Potato Chips','बटाटा वेफर्स','Snacks','Balaji',30,35,'packet',55,10),
  ('Banana Chips','केळी वेफर्स','Snacks','Local',55,65,'200g',25,5),
  ('Bhujia','भुजिया','Snacks','Haldiram',55,65,'200g',30,6),
  ('Sev','शेव','Snacks','Local',50,60,'200g',30,6),
  ('Bhel Mix','भेळ मिक्स','Snacks','Local',50,60,'200g',25,5),
  ('Chivda','चिवडा','Snacks','Local',55,65,'200g',30,6),
  ('Peanuts','शेंगदाणे','Snacks','Local',95,110,'kg',30,6),
  ('Roasted Chana','फुटाणा','Snacks','Local',85,98,'kg',25,5),
  ('Popcorn','पॉपकॉर्न','Snacks','Local',35,42,'packet',25,5),
  ('Poha','पोहे','Breakfast','Local',58,68,'kg',45,8),
  ('Corn Flakes','कॉर्न फ्लेक्स','Breakfast','Kellogg''s',210,240,'500g',20,4),
  ('Oats','ओट्स','Breakfast','Saffola',145,165,'500g',25,5),
  ('Sabudana','साबुदाणा','Breakfast','Local',78,90,'kg',35,7),
  ('Vermicelli / Shevaya','शेवया','Breakfast','Local',48,58,'200g',25,5),
  ('Dalia','दलिया','Breakfast','Local',55,65,'kg',20,4),
  ('Almonds','बदाम','Dry Fruits','Local',780,850,'kg',20,4),
  ('Cashews','काजू','Dry Fruits','Local',920,1000,'kg',18,3),
  ('Raisins','मनुका','Dry Fruits','Local',360,410,'kg',20,4),
  ('Walnuts','अक्रोड','Dry Fruits','Local',980,1080,'kg',12,3),
  ('Pistachios','पिस्ता','Dry Fruits','Local',1100,1220,'kg',12,3),
  ('Dates','खजूर','Dry Fruits','Local',260,300,'kg',20,4),
  ('Anjeer','अंजीर','Dry Fruits','Local',1250,1400,'kg',10,2),
  ('Tomato Ketchup','टोमॅटो केचप','Sauces & Spreads','Kissan',115,130,'500g',25,5),
  ('Chilli Sauce','चिली सॉस','Sauces & Spreads','Ching''s',95,110,'200g',20,4),
  ('Soy Sauce','सोया सॉस','Sauces & Spreads','Ching''s',85,98,'200ml',20,4),
  ('Green Chutney','हिरवी चटणी','Sauces & Spreads','Local',45,55,'200g',15,3),
  ('Peanut Butter','शेंगदाणा बटर','Sauces & Spreads','Pintola',210,235,'350g',15,3),
  ('Jam','जॅम','Sauces & Spreads','Kissan',110,125,'500g',20,4),
  ('Mayonnaise','मेयोनेझ','Sauces & Spreads','Veeba',145,165,'250g',15,3),
  ('Milk','दूध','Dairy','Local Dairy',62,68,'litre',35,8),
  ('Curd','दही','Dairy','Local Dairy',45,50,'500g',30,6),
  ('Buttermilk','ताक','Dairy','Local Dairy',25,30,'500ml',30,6),
  ('Paneer','पनीर','Dairy','Local Dairy',360,400,'kg',15,3),
  ('Butter','लोणी','Dairy','Amul',58,65,'100g',25,5),
  ('Cheese','चीज','Dairy','Amul',125,140,'200g',20,4),
  ('Ghee','तूप','Dairy','Amul',315,350,'500ml',18,3),
  ('Detergent Powder','डिटर्जंट पावडर','Household','Surf Excel',125,145,'kg',35,7),
  ('Detergent Bar','डिटर्जंट बार','Household','Rin',25,30,'piece',40,8),
  ('Dishwash Liquid','भांडी घासण्याचे लिक्विड','Household','Vim',115,130,'500ml',25,5),
  ('Dishwash Bar','भांडी घासण्याची वडी','Household','Vim',15,20,'piece',45,9),
  ('Floor Cleaner','फ्लोअर क्लीनर','Household','Harpic',135,155,'litre',20,4),
  ('Toilet Cleaner','टॉयलेट क्लीनर','Household','Harpic',105,120,'500ml',20,4),
  ('Phenyl','फिनाइल','Household','Local',75,90,'litre',20,4),
  ('Glass Cleaner','ग्लास क्लीनर','Household','Colin',110,125,'500ml',15,3),
  ('Scrub Pad','स्क्रब पॅड','Household','Scotch-Brite',35,45,'packet',25,5),
  ('Garbage Bags','कचरा पिशव्या','Household','Local',65,80,'packet',20,4),
  ('Bath Soap','अंघोळीचा साबण','Personal Care','Dove',48,55,'piece',45,9),
  ('Handwash','हँडवॉश','Personal Care','Dettol',95,110,'250ml',25,5),
  ('Shampoo','शॅम्पू','Personal Care','Clinic Plus',125,145,'180ml',25,5),
  ('Toothpaste','टूथपेस्ट','Personal Care','Colgate',105,120,'200g',30,6),
  ('Toothbrush','टूथब्रश','Personal Care','Colgate',35,45,'piece',35,7),
  ('Hair Oil','केसांचे तेल','Personal Care','Parachute',110,125,'250ml',25,5),
  ('Face Wash','फेस वॉश','Personal Care','Himalaya',145,165,'100ml',18,3),
  ('Talcum Powder','टॅल्कम पावडर','Personal Care','Pond''s',95,110,'100g',20,4),
  ('Onion','कांदा','Fresh Vegetables','Local',32,40,'kg',80,15),
  ('Potato','बटाटा','Fresh Vegetables','Local',28,36,'kg',70,12),
  ('Tomato','टोमॅटो','Fresh Vegetables','Local',38,48,'kg',55,10),
  ('Brinjal','वांगी','Fresh Vegetables','Local',42,52,'kg',30,6),
  ('Cabbage','कोबी','Fresh Vegetables','Local',30,38,'kg',30,6),
  ('Cauliflower','फ्लॉवर','Fresh Vegetables','Local',45,58,'kg',25,5),
  ('Carrot','गाजर','Fresh Vegetables','Local',48,60,'kg',25,5),
  ('Beetroot','बीट','Fresh Vegetables','Local',45,55,'kg',20,4),
  ('Cucumber','काकडी','Fresh Vegetables','Local',38,48,'kg',25,5),
  ('Green Chilli','हिरवी मिरची','Fresh Vegetables','Local',80,95,'kg',20,4),
  ('Coriander','कोथिंबीर','Fresh Vegetables','Local',15,20,'bunch',35,7),
  ('Bhindi','भेंडी','Fresh Vegetables','Local',55,68,'kg',25,5),
  ('Bitter Gourd','कारले','Fresh Vegetables','Local',58,70,'kg',20,4),
  ('Drumstick','शेवगा','Fresh Vegetables','Local',75,90,'kg',15,3),
  ('Spinach','पालक','Fresh Vegetables','Local',20,25,'bunch',30,6),
  ('Radish','मुळा','Fresh Vegetables','Local',30,38,'kg',20,4),
  ('Ginger','आले','Fresh Vegetables','Local',120,140,'kg',25,5),
  ('Garlic','लसूण','Fresh Vegetables','Local',180,210,'kg',25,5),
  ('Lemon','लिंबू','Fresh Vegetables','Local',90,110,'kg',20,4),
  ('Banana','केळी','Fruits','Local',55,65,'dozen',45,8),
  ('Apple','सफरचंद','Fruits','Local',180,210,'kg',30,6),
  ('Orange','संत्रे','Fruits','Local',95,115,'kg',30,6),
  ('Mosambi','मोसंबी','Fruits','Local',85,105,'kg',25,5),
  ('Pomegranate','डाळिंब','Fruits','Local',180,210,'kg',25,5),
  ('Guava','पेरू','Fruits','Local',70,85,'kg',25,5),
  ('Papaya','पपई','Fruits','Local',45,58,'kg',25,5),
  ('Watermelon','कलिंगड','Fruits','Local',28,38,'kg',30,6),
  ('Mango','आंबा','Fruits','Local',120,145,'kg',20,4),
  ('Grapes','द्राक्षे','Fruits','Local',110,135,'kg',25,5),
  ('Coconut','नारळ','Fruits','Local',35,45,'piece',35,7)
),
images(category, image_url) as (
  values
  ('Rice','https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'),
  ('Flour','https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80'),
  ('Pulses','https://images.unsplash.com/photo-1515543904379-3d757afe72e4?auto=format&fit=crop&w=600&q=80'),
  ('Grains & Pulses','https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?auto=format&fit=crop&w=600&q=80'),
  ('Edible Oil','https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80'),
  ('Spices','https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=600&q=80'),
  ('Sugar','https://images.unsplash.com/photo-1558642452-9d2a7deb7f62?auto=format&fit=crop&w=600&q=80'),
  ('Salt','https://images.unsplash.com/photo-1518110925495-5aa3d5b65d90?auto=format&fit=crop&w=600&q=80'),
  ('Tea & Coffee','https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=600&q=80'),
  ('Biscuits','https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=600&q=80'),
  ('Snacks','https://images.unsplash.com/photo-1621939514649-280e2aa4a736?auto=format&fit=crop&w=600&q=80'),
  ('Breakfast','https://images.unsplash.com/photo-1517673132405-a56a62b18caf?auto=format&fit=crop&w=600&q=80'),
  ('Dry Fruits','https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&w=600&q=80'),
  ('Sauces & Spreads','https://images.unsplash.com/photo-1472476443507-c7a5948772fc?auto=format&fit=crop&w=600&q=80'),
  ('Dairy','https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&w=600&q=80'),
  ('Household','https://images.unsplash.com/photo-1583947215259-38e31be8751f?auto=format&fit=crop&w=600&q=80'),
  ('Personal Care','https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=600&q=80'),
  ('Fresh Vegetables','https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80'),
  ('Fruits','https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=600&q=80')
)
updated as (
update public.products p
set product_name = c.name, marathi_name = c.marathi_name, category = c.category,
    brand = c.brand, price = c.price, selling_price = c.price, mrp = c.mrp,
    unit = c.unit, weight = c.unit, stock_quantity = c.stock,
    low_stock_threshold = c.low_stock, product_type = case
      when c.category in ('Fresh Vegetables','Fruits') then 'vegetable'
      when c.category = 'Dairy' then 'dairy'
      when c.category in ('Household','Personal Care') then lower(replace(c.category, ' ', '-'))
      else 'grocery' end,
    image_url = i.image_url, active = true, is_available = true,
    discount = round((c.mrp - c.price) * 100 / c.mrp, 2)
from catalogue c join images i on i.category = c.category
where lower(coalesce(p.product_name, p.name)) = lower(c.name)
returning p.id
)
insert into public.products (name, product_name, marathi_name, category, brand, price, selling_price, mrp, unit, weight, stock_quantity, low_stock_threshold, product_type, image_url, active, is_available)
select c.name, c.name, c.marathi_name, c.category, c.brand, c.price, c.price, c.mrp, c.unit, c.unit, c.stock, c.low_stock,
  case when c.category in ('Fresh Vegetables','Fruits') then 'vegetable' when c.category = 'Dairy' then 'dairy' when c.category in ('Household','Personal Care') then lower(replace(c.category, ' ', '-')) else 'grocery' end,
  i.image_url, true, true
from catalogue c join images i on i.category = c.category
where not exists (select 1 from public.products p where lower(coalesce(p.product_name, p.name)) = lower(c.name));
