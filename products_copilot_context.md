# Products Data Context & Schema

This file contains the exported dataset and schema for `public.products` from Supabase to provide context for GitHub Copilot in VS Code.

## Database Schema (`public.products`)

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Unique Identifier |
| `name` | `text` | Product Name |
| `category` | `text` | Product Category |
| `price` | `numeric` | Current selling price |
| `mrp` | `numeric` | Maximum Retail Price (Optional / Nullable) |
| `unit` | `text` | Unit of measurement (e.g., kg, 5 kg, gm) |
| `pricing_type` | `text` | Pricing logic (e.g., `By-Weight`, `Fixed`) |
| `active` | `boolean` | Availability status (`true`/`false`) |
| `created_at` | `timestamptz` | Record creation timestamp |
| `image_url` | `text` | URL to product image in Supabase Storage |

---

## Seed Data / Reference Records

Below is the structured data exported from the `public.products` table.

```json
[
  {
    "id": "ceda8d90-cd4e-4522-b1a9-77643ba8edef",
    "name": "Groundnut Oil",
    "category": "Cooking Oil",
    "price": 208.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": null
  },
  {
    "id": "d5dcc0d8-c2c9-4e29-bc95-63e20a72638e",
    "name": "Soya Oil",
    "category": "Cooking Oil",
    "price": 165.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/9b33a61e-9be4-4fc4-980e-4b45a86e7e67-WhatsApp-Image-2026-09-06-at-12.33.47-PM.jpeg"
  },
  {
    "id": "5128002d-9106-4895-af9a-b55c964eb212",
    "name": "Sunflower Oil",
    "category": "Cooking Oil",
    "price": 192.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/6932547e-d6ac-45dd-98b2-3f0a1d928eb3-shopping.webp"
  },
  {
    "id": "607bbcf1-3119-4937-8cdb-0993f553f96e",
    "name": "Salt",
    "category": "Essentials",
    "price": 22.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/4ec5da95-711d-4a1e-a437-89a9026ea6e0-shopping--1-.webp"
  },
  {
    "id": "a14fcf54-994d-4781-b827-d0adc344d904",
    "name": "Madhur  Sugar",
    "category": "Sugar",
    "price": 275.0,
    "mrp": 500.0,
    "unit": "5 kg",
    "pricing_type": "Fixed",
    "active": true,
    "created_at": "2026-09-05 15:39:06.550888+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/fa2eeed5-7f71-4c87-a672-5780961a0c21-shopping--2-.webp"
  },
  {
    "id": "73a2f3a0-b863-4900-82fd-1ce290113b1b",
    "name": "Sugar",
    "category": "Essentials",
    "price": 65.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/af738869-a427-4c7b-8e35-e03967b7a0ce-shopping--3-.webp"
  },
  {
    "id": "02354380-357e-43f5-b306-64c60e37fc1b",
    "name": "Atta",
    "category": "Grains & Flours",
    "price": 38.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/9d311b91-69d3-4997-8db1-723a6fa15419-126903_12-aashirvaad-atta-whole-wheat.webp"
  },
  {
    "id": "1654c75a-adc8-4489-910e-85af46941c98",
    "name": "Besan",
    "category": "Grains & Flours",
    "price": 96.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/120e1a3e-77f4-4f62-badc-89972f2e9933-shopping--4-.webp"
  },
  {
    "id": "6c53d0d7-038b-4a2a-a83e-1340333cff1f",
    "name": "Maida",
    "category": "Grains & Flours",
    "price": 42.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/fb764513-05d9-4ad0-8652-7b68c1508b47-shopping--5-.webp"
  },
  {
    "id": "78c8fffd-6f7d-4ed3-bf6b-be7acbf00a66",
    "name": "Rice",
    "category": "Grains & Flours",
    "price": 45.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/2fd7925b-7a61-44dd-9242-a414a9703496-shopping--7-.webp"
  },
  {
    "id": "654bc1de-f9f7-4919-9330-7701ec53b891",
    "name": "Suji",
    "category": "Grains & Flours",
    "price": 47.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/de1f3bfb-450a-433e-97e9-85b30e487751-shopping--8-.webp"
  },
  {
    "id": "e35f6993-b095-4f05-b1c7-d7bbb7be6992",
    "name": "Wheat",
    "category": "Grains & Flours",
    "price": 32.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/fdf9e39a-7a07-402d-9081-f3d1cc2b6bb1-shopping--9-.webp"
  },
  {
    "id": "73c996dd-ee8d-4cf4-a59d-e5a13fa4c90e",
    "name": "Gram Dal",
    "category": "Pulses (Dal)",
    "price": 87.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/32cf0727-3cfe-421b-8b83-4bbeaaa01430-shopping--10-.webp"
  },
  {
    "id": "bbfc80b8-0efc-4419-88eb-fd5108e1a5d7",
    "name": "Masoor Dal",
    "category": "Pulses (Dal)",
    "price": 90.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/5a7950a4-161c-498a-9de5-c9ec3476f4f7-shopping--11-.webp"
  },
  {
    "id": "12befa49-fe1c-4023-be1c-7bedc7adc907",
    "name": "Moong Dal",
    "category": "Pulses (Dal)",
    "price": 112.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/36a482ce-2b5d-4bfb-9ac9-a0785a9210db-shopping--12-.webp"
  },
  {
    "id": "a750e984-2c37-4360-9889-2e2742285a7c",
    "name": "Tur Dal",
    "category": "Pulses (Dal)",
    "price": 123.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/138c8c86-d471-4930-8b45-6021952522ae-shopping--10-.webp"
  },
  {
    "id": "6a8aa553-7255-4c78-bebf-2cbc4d37c642",
    "name": "Urad Dal",
    "category": "Pulses (Dal)",
    "price": 121.0,
    "mrp": null,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-01 12:38:42.939876+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/785396d1-d09f-4aa5-8aa8-41d48a7d5b5b-shopping.webp"
  },
  {
    "id": "bbbcc29f-8f33-4a80-b8b4-98b22c309dd3",
    "name": "kali udat dal",
    "category": "General",
    "price": 110.0,
    "mrp": 150.0,
    "unit": "kg",
    "pricing_type": "By-Weight",
    "active": true,
    "created_at": "2026-09-07 10:54:00.712939+00",
    "image_url": "https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/f933193c-81d0-449e-b3de-8507c4979238-shopping--13-.webp"
  }
]
```

## SQL Insert Seed Statements

```sql
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('ceda8d90-cd4e-4522-b1a9-77643ba8edef', 'Groundnut Oil', 'Cooking Oil', 208.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', NULL);
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('d5dcc0d8-c2c9-4e29-bc95-63e20a72638e', 'Soya Oil', 'Cooking Oil', 165.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/9b33a61e-9be4-4fc4-980e-4b45a86e7e67-WhatsApp-Image-2026-09-06-at-12.33.47-PM.jpeg');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('5128002d-9106-4895-af9a-b55c964eb212', 'Sunflower Oil', 'Cooking Oil', 192.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/6932547e-d6ac-45dd-98b2-3f0a1d928eb3-shopping.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('607bbcf1-3119-4937-8cdb-0993f553f96e', 'Salt', 'Essentials', 22.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/4ec5da95-711d-4a1e-a437-89a9026ea6e0-shopping--1-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('a14fcf54-994d-4781-b827-d0adc344d904', 'Madhur  Sugar', 'Sugar', 275.0, 500.0, '5 kg', 'Fixed', true, '2026-09-05 15:39:06.550888+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/fa2eeed5-7f71-4c87-a672-5780961a0c21-shopping--2-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('73a2f3a0-b863-4900-82fd-1ce290113b1b', 'Sugar', 'Essentials', 65.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/af738869-a427-4c7b-8e35-e03967b7a0ce-shopping--3-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('02354380-357e-43f5-b306-64c60e37fc1b', 'Atta', 'Grains & Flours', 38.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/9d311b91-69d3-4997-8db1-723a6fa15419-126903_12-aashirvaad-atta-whole-wheat.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('1654c75a-adc8-4489-910e-85af46941c98', 'Besan', 'Grains & Flours', 96.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/120e1a3e-77f4-4f62-badc-89972f2e9933-shopping--4-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('6c53d0d7-038b-4a2a-a83e-1340333cff1f', 'Maida', 'Grains & Flours', 42.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/fb764513-05d9-4ad0-8652-7b68c1508b47-shopping--5-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('78c8fffd-6f7d-4ed3-bf6b-be7acbf00a66', 'Rice', 'Grains & Flours', 45.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/2fd7925b-7a61-44dd-9242-a414a9703496-shopping--7-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('654bc1de-f9f7-4919-9330-7701ec53b891', 'Suji', 'Grains & Flours', 47.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/de1f3bfb-450a-433e-97e9-85b30e487751-shopping--8-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('e35f6993-b095-4f05-b1c7-d7bbb7be6992', 'Wheat', 'Grains & Flours', 32.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/fdf9e39a-7a07-402d-9081-f3d1cc2b6bb1-shopping--9-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('73c996dd-ee8d-4cf4-a59d-e5a13fa4c90e', 'Gram Dal', 'Pulses (Dal)', 87.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/32cf0727-3cfe-421b-8b83-4bbeaaa01430-shopping--10-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('bbfc80b8-0efc-4419-88eb-fd5108e1a5d7', 'Masoor Dal', 'Pulses (Dal)', 90.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/5a7950a4-161c-498a-9de5-c9ec3476f4f7-shopping--11-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('12befa49-fe1c-4023-be1c-7bedc7adc907', 'Moong Dal', 'Pulses (Dal)', 112.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/36a482ce-2b5d-4bfb-9ac9-a0785a9210db-shopping--12-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('a750e984-2c37-4360-9889-2e2742285a7c', 'Tur Dal', 'Pulses (Dal)', 123.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/138c8c86-d471-4930-8b45-6021952522ae-shopping--10-.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('6a8aa553-7255-4c78-bebf-2cbc4d37c642', 'Urad Dal', 'Pulses (Dal)', 121.0, NULL, 'kg', 'By-Weight', true, '2026-09-01 12:38:42.939876+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/785396d1-d09f-4aa5-8aa8-41d48a7d5b5b-shopping.webp');
INSERT INTO public.products (id, name, category, price, mrp, unit, pricing_type, active, created_at, image_url) VALUES ('bbbcc29f-8f33-4a80-b8b4-98b22c309dd3', 'kali udat dal', 'General', 110.0, 150.0, 'kg', 'By-Weight', true, '2026-09-07 10:54:00.712939+00', 'https://chbpiocnrrznwjoogthm.supabase.co/storage/v1/object/public/site-assets/products/f933193c-81d0-449e-b3de-8507c4979238-shopping--13-.webp');
```
