-- Bete App Database Schema
-- Run these in order in the Supabase SQL Editor

-- ============================================
-- LISTINGS
-- ============================================
create table listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  description text,
  price numeric not null,
  listing_type text not null check (listing_type in ('rent', 'sale')),
  status text not null default 'active' check (status in ('active', 'rented', 'sold', 'pending')),
  neighborhood text not null,
  address text,
  latitude double precision,
  longitude double precision,
  has_water boolean not null default false,
  has_electricity boolean not null default false,
  distance_to_transport_m integer,
  verification_status text not null default 'unverified' check (verification_status in ('unverified', 'pending', 'verified')),
  last_verified_at timestamptz,
  created_at timestamptz not null default now()
);

alter table listings enable row level security;

create policy "Anyone can view active listings"
  on listings for select
  using (status = 'active');

create policy "Owners can view their own listings regardless of status"
  on listings for select
  using (auth.uid() = owner_id);

create policy "Owners can insert their own listings"
  on listings for insert
  with check (auth.uid() = owner_id);

create policy "Owners can update their own listings"
  on listings for update
  using (auth.uid() = owner_id);

create policy "Owners can delete their own listings"
  on listings for delete
  using (auth.uid() = owner_id);

-- ============================================
-- MEDIA
-- ============================================
create table media (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references listings(id) on delete cascade not null,
  media_type text not null check (media_type in ('photo', 'video')),
  url text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table media enable row level security;

create policy "Anyone can view media for active listings"
  on media for select
  using (
    exists (
      select 1 from listings
      where listings.id = media.listing_id
      and listings.status = 'active'
    )
  );

create policy "Owners can view media for their own listings"
  on media for select
  using (
    exists (
      select 1 from listings
      where listings.id = media.listing_id
      and listings.owner_id = auth.uid()
    )
  );

create policy "Owners can insert media for their own listings"
  on media for insert
  with check (
    exists (
      select 1 from listings
      where listings.id = media.listing_id
      and listings.owner_id = auth.uid()
    )
  );

create policy "Owners can delete media for their own listings"
  on media for delete
  using (
    exists (
      select 1 from listings
      where listings.id = media.listing_id
      and listings.owner_id = auth.uid()
    )
  );

-- ============================================
-- FAVORITES
-- ============================================
create table favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  listing_id uuid references listings(id) on delete cascade not null,
  created_at timestamptz not null default now(),
  unique (user_id, listing_id)
);

alter table favorites enable row level security;

create policy "Users can view their own favorites"
  on favorites for select
  using (auth.uid() = user_id);

create policy "Users can add their own favorites"
  on favorites for insert
  with check (auth.uid() = user_id);

create policy "Users can remove their own favorites"
  on favorites for delete
  using (auth.uid() = user_id);

-- ============================================
-- REPORTS
-- ============================================
create table reports (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references listings(id) on delete cascade not null,
  reporter_id uuid references auth.users(id) on delete set null,
  reason text not null,
  details text,
  status text not null default 'pending' check (status in ('pending', 'reviewed', 'dismissed')),
  created_at timestamptz not null default now()
);

alter table reports enable row level security;

create policy "Anyone signed in can submit a report"
  on reports for insert
  with check (auth.uid() = reporter_id);

create policy "Reporters can view their own submitted reports"
  on reports for select
  using (auth.uid() = reporter_id);

-- ============================================
-- NOTIFICATIONS
-- ============================================
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  type text not null,
  content text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table notifications enable row level security;

create policy "Users can view their own notifications"
  on notifications for select
  using (auth.uid() = user_id);

create policy "Users can mark their own notifications as read"
  on notifications for update
  using (auth.uid() = user_id);
