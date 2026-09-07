# Avisekh Dairy — Online Ordering System

A simple, no-monthly-fee ordering site for a milk/dairy business, backed by Supabase.
Customers book milk, paneer, curd, and ghee for pickup or home delivery — either as a
one-time booking or a daily subscription. You manage everything from a private
owner dashboard.

## Files

| File | What it's for |
|---|---|
| `index.html` | The customer-facing ordering site. Upload this wherever your customers will visit it. |
| `dashboard.html` | Your private admin dashboard — orders, subscriptions, customers, inventory. Keep the link to this private; don't put it in your public site's navigation. |
| `dairy_setup.sql` | Run once in Supabase to set up the database for the dairy menu, bookings, and subscriptions. |
| `inventory_menu_setup.sql`, `inventory_table_setup.sql`, `shop_settings_setup.sql` | Earlier setup scripts (menu/stock table and the open/closed toggle). Only needed if you're setting up a brand-new Supabase project from scratch — see Setup Order below. |

## Setup Order (new Supabase project)

If you're starting completely fresh, run these SQL files in Supabase's **SQL Editor**
in this order:

1. `shop_settings_setup.sql` — creates the open/closed toggle
2. `inventory_menu_setup.sql` or `inventory_table_setup.sql` — creates the inventory/menu table
3. `dairy_setup.sql` — adds booking fields, subscriptions, and replaces the menu with dairy items

If your Supabase project already has these tables from earlier testing, you can
**just run `dairy_setup.sql`** — every script is safe to re-run and won't duplicate
data or error on things that already exist.

## Customer Site Features

- **Browse & search** the live menu (Milk, Paneer, Curd, Ghee), grouped by category
- **Sold-out items** are clearly marked and can't be added to cart
- **Pickup or home delivery** — chosen at checkout, with an address field for delivery
- **One-time booking** — pick any date up to 7 days ahead
- **Daily subscription** — pick a start date and a duration (7 / 15 / 30 days, or
  "until I cancel")
- **Order tracking** — customers enter their Order ID to see live status
  (New → Preparing → Ready → Completed), auto-refreshing every few seconds
- **Shop closed banner** — if you mark the shop closed from the dashboard, customers
  see this immediately and can't check out

## Admin Dashboard Features

- **Orders tab** — every booking, with status updates and a one-tap WhatsApp message
  to the customer
- **Subscriptions tab** — every active/paused/cancelled subscription, with Pause,
  Reactivate, and Cancel controls, plus a **"Today's Deliveries"** summary combining
  one-time bookings and active subscriptions due today
- **Customers tab** — built automatically from order history (name, phone, lifetime
  spend, order count, WhatsApp link) — no separate customer table needed
- **Inventory tab** — add/edit items with price, current stock, minimum stock alert
  level, and a Mark Out / Mark In toggle; filters for In Stock / Low Stock / Out of
  Stock
- **Shop status banner** — one click to close the shop for the day with a custom
  message, or reopen it

## How Stock Works

- Every one-time booking automatically decreases the ordered item's stock
- If stock hits 0, the item is automatically marked out of stock and disappears
  from what customers can order
- You can also manually **Mark Out** an item any time (e.g. you know it'll run out
  before the stock counter catches up)
- **Subscriptions do not decrement stock automatically** — a daily subscription
  assumes ongoing production/supply rather than a fixed batch, so it won't
  artificially deplete your one-time-booking stock count

## A Note on Subscriptions

Supabase alone can't automatically turn a subscription into a new order every
single day without a scheduled job (Supabase supports this via **pg_cron**, which
you can enable from your project's **Database → Extensions** page if you want full
automation later).

Until you set that up, the **Subscriptions tab's "Today's Deliveries" summary** is
computed live every time you open it — combining today's one-time bookings with
every subscription that's currently active — so nothing gets missed even without
the automated version.

## Where to Get Help

- **Supabase errors**: almost always mean a SQL setup step hasn't been run yet, or
  needs to be re-run — check the **SQL Editor** first.
- **Customers not seeing changes**: the site rechecks stock, menu, and shop status
  every 30 seconds automatically — ask them to wait a moment or refresh.
- **WhatsApp number**: currently set to the placeholder `9999999999` in a few
  places in `index.html` and `dashboard.html` — search for that number and replace
  it with your real one before going live.
