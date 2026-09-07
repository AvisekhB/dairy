-- ============================================================
-- PIVOT TO DAIRY BUSINESS
-- Run this once in Supabase: Dashboard → SQL Editor → New query → Run
--
-- This does three things:
--   1. Replaces the bakery menu in "inventory" with dairy items
--      (Milk, Paneer, Curd, Ghee)
--   2. Adds pickup/delivery + booking-date fields to "orders"
--   3. Creates a new "subscriptions" table for daily recurring orders
-- ============================================================

-- ------------------------------------------------------------
-- 1. REPLACE MENU
-- ⚠️ This deletes all current inventory rows (the bakery items).
--    Your order HISTORY is untouched — only the menu/stock list
--    is replaced. Comment out the delete if you want to keep both
--    menus side by side instead.
-- ------------------------------------------------------------
delete from public.inventory;

insert into public.inventory (name, category, item_type, order_type, unit, price, eggless, stock_qty, min_stock)
values
  ('Full Cream Milk','Milk','By-Weight','Ready-made','per litre',66,null,100,10),
  ('Toned Milk','Milk','By-Weight','Ready-made','per litre',56,null,100,10),
  ('Cow Milk','Milk','By-Weight','Ready-made','per litre',60,null,80,10),
  ('Fresh Paneer','Paneer','By-Weight','Ready-made','per kg',360,null,20,3),
  ('Malai Paneer','Paneer','By-Weight','Ready-made','per kg',420,null,15,3),
  ('Curd (Dahi)','Curd','By-Weight','Ready-made','per kg',80,null,40,5),
  ('Sweet Curd','Curd','By-Weight','Ready-made','per kg',90,null,20,3),
  ('Cow Ghee','Ghee','By-Weight','Ready-made','per litre',650,null,15,2),
  ('Buffalo Ghee','Ghee','By-Weight','Ready-made','per litre',700,null,15,2)
on conflict (name) do nothing;

-- ------------------------------------------------------------
-- 2. ADD BOOKING/DELIVERY FIELDS TO ORDERS
-- ------------------------------------------------------------
alter table public.orders add column if not exists fulfillment_method text default 'Pickup';
alter table public.orders add column if not exists address text;
alter table public.orders add column if not exists fulfillment_date date;

-- Make sure order tracking (get_order_status) returns every column,
-- including the new ones above. Safe to re-run.
create or replace function public.get_order_status(p_order_id text)
returns setof public.orders
language sql
security definer
set search_path = public
as $$
  select * from public.orders where id = p_order_id;
$$;

grant execute on function public.get_order_status(text) to anon, authenticated;

-- ------------------------------------------------------------
-- 3. SUBSCRIPTIONS (daily recurring bookings)
-- ------------------------------------------------------------
create table if not exists public.subscriptions (
  id text primary key,
  name text not null,
  phone text not null,
  fulfillment_method text not null default 'Pickup' check (fulfillment_method in ('Pickup','Delivery')),
  address text,
  start_date date not null,
  duration_days integer, -- null means "until cancelled"
  items jsonb not null,
  daily_total numeric not null default 0,
  status text not null default 'Active' check (status in ('Active','Paused','Cancelled')),
  note text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_subscriptions_updated_at on public.subscriptions;
create trigger trg_subscriptions_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

alter table public.subscriptions enable row level security;

-- Customers (anon key) can create a subscription at checkout
drop policy if exists "Anyone can create subscriptions" on public.subscriptions;
create policy "Anyone can create subscriptions"
on public.subscriptions for insert
to anon, authenticated
with check (true);

-- Only the logged-in owner can view/manage the subscriber list
drop policy if exists "Authenticated can view subscriptions" on public.subscriptions;
create policy "Authenticated can view subscriptions"
on public.subscriptions for select
to authenticated
using (true);

drop policy if exists "Authenticated can update subscriptions" on public.subscriptions;
create policy "Authenticated can update subscriptions"
on public.subscriptions for update
to authenticated
using (true);

drop policy if exists "Authenticated can delete subscriptions" on public.subscriptions;
create policy "Authenticated can delete subscriptions"
on public.subscriptions for delete
to authenticated
using (true);

-- ============================================================
-- NOTE ON AUTOMATION: Supabase alone can't automatically turn a
-- subscription into a fresh order each morning without a scheduled
-- job (e.g. pg_cron, which may need enabling in your project's
-- Database → Extensions page, or an external scheduler). Until you
-- set that up, the owner dashboard's Subscriptions tab shows a daily
-- "what to prepare today" summary computed live from active
-- subscriptions, so nothing is missed even without automation.
-- ============================================================
