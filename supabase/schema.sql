-- =====================================================================
-- Bete App — database schema (Supabase / Postgres)
--
-- Every statement is safe to re-run, so this one file works for:
--   * setting up a fresh Supabase project, and
--   * bringing an existing project up to date.
-- Run it in: Supabase Dashboard -> SQL Editor -> New query.
--
-- Make someone an admin (SQL editor only, the app cannot do this):
--   update profiles set is_admin = true where id = '<their user uid>';
-- =====================================================================

-- =====================================================================
-- PROFILES
-- =====================================================================
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

alter table profiles add column if not exists is_admin boolean not null default false;

alter table profiles enable row level security;

drop policy if exists "Anyone can view profiles" on profiles;
create policy "Anyone can view profiles"
  on profiles for select
  using (true);

drop policy if exists "Users can insert their own profile" on profiles;
create policy "Users can insert their own profile"
  on profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on profiles;
create policy "Users can update their own profile"
  on profiles for update
  using (auth.uid() = id);

-- Stops signed-in users from making themselves admin through the API.
-- Changes made from the Supabase dashboard / SQL editor are still allowed.
create or replace function protect_is_admin()
returns trigger
language plpgsql
as $$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.is_admin := false;
    else
      new.is_admin := old.is_admin;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_is_admin on profiles;
create trigger profiles_protect_is_admin
  before insert or update on profiles
  for each row execute function protect_is_admin();

-- =====================================================================
-- LISTINGS
-- =====================================================================
create table if not exists listings (
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

-- Rented/sold listings stay visible (with a badge in the app).
drop policy if exists "Anyone can view active listings" on listings;
drop policy if exists "Anyone can view non-deleted listings" on listings;
drop policy if exists "Anyone can view visible listings" on listings;
create policy "Anyone can view visible listings"
  on listings for select
  using (status in ('active', 'rented', 'sold'));

drop policy if exists "Owners can view their own listings regardless of status" on listings;
create policy "Owners can view their own listings regardless of status"
  on listings for select
  using (auth.uid() = owner_id);

drop policy if exists "Admins can view all listings" on listings;
create policy "Admins can view all listings"
  on listings for select
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid() and profiles.is_admin = true
    )
  );

drop policy if exists "Owners can insert their own listings" on listings;
create policy "Owners can insert their own listings"
  on listings for insert
  with check (auth.uid() = owner_id);

drop policy if exists "Owners can update their own listings" on listings;
create policy "Owners can update their own listings"
  on listings for update
  using (auth.uid() = owner_id);

drop policy if exists "Admins can update any listing" on listings;
create policy "Admins can update any listing"
  on listings for update
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid() and profiles.is_admin = true
    )
  );

-- Owners no longer delete (they mark rented/sold instead); only admins delete.
drop policy if exists "Owners can delete their own listings" on listings;
drop policy if exists "Admins can delete any listing" on listings;
create policy "Admins can delete any listing"
  on listings for delete
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid() and profiles.is_admin = true
    )
  );

-- Only admins can verify a listing: for everyone else the verification
-- fields are forced back to their previous values (or "unverified" on insert).
create or replace function protect_listing_verification()
returns trigger
language plpgsql
as $$
begin
  if current_user in ('authenticated', 'anon')
     and not coalesce((select is_admin from profiles where id = auth.uid()), false) then
    if tg_op = 'INSERT' then
      new.verification_status := 'unverified';
      new.last_verified_at := null;
    else
      new.verification_status := old.verification_status;
      new.last_verified_at := old.last_verified_at;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists listings_protect_verification on listings;
create trigger listings_protect_verification
  before insert or update on listings
  for each row execute function protect_listing_verification();

-- When a listing becomes rented/sold, notify every admin and everyone who
-- saved it. Runs inside the database so the app never inserts notifications.
create or replace function notify_listing_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  label text;
begin
  if new.status in ('rented', 'sold') and old.status is distinct from new.status then
    label := case when new.status = 'rented' then 'Rented' else 'Sold' end;

    insert into notifications (user_id, type, content)
    select id, 'listing_status', '"' || new.title || '" was marked as ' || label
    from profiles
    where is_admin = true;

    insert into notifications (user_id, type, content)
    select user_id, 'listing_status', '"' || new.title || '" you saved is now ' || label
    from favorites
    where listing_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists listings_notify_status_change on listings;
create trigger listings_notify_status_change
  after update of status on listings
  for each row execute function notify_listing_status_change();

-- =====================================================================
-- MEDIA
-- =====================================================================
create table if not exists media (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references listings(id) on delete cascade not null,
  media_type text not null check (media_type in ('photo', 'video')),
  url text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table media enable row level security;

drop policy if exists "Anyone can view media for active listings" on media;
drop policy if exists "Anyone can view media for visible listings" on media;
create policy "Anyone can view media for visible listings"
  on media for select
  using (
    exists (
      select 1 from listings
      where listings.id = media.listing_id
      and listings.status in ('active', 'rented', 'sold')
    )
  );

drop policy if exists "Owners can view media for their own listings" on media;
create policy "Owners can view media for their own listings"
  on media for select
  using (
    exists (
      select 1 from listings
      where listings.id = media.listing_id
      and listings.owner_id = auth.uid()
    )
  );

drop policy if exists "Owners can insert media for their own listings" on media;
create policy "Owners can insert media for their own listings"
  on media for insert
  with check (
    exists (
      select 1 from listings
      where listings.id = media.listing_id
      and listings.owner_id = auth.uid()
    )
  );

drop policy if exists "Owners can delete media for their own listings" on media;
create policy "Owners can delete media for their own listings"
  on media for delete
  using (
    exists (
      select 1 from listings
      where listings.id = media.listing_id
      and listings.owner_id = auth.uid()
    )
  );

-- =====================================================================
-- FAVORITES
-- =====================================================================
create table if not exists favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  listing_id uuid references listings(id) on delete cascade not null,
  created_at timestamptz not null default now(),
  unique (user_id, listing_id)
);

alter table favorites enable row level security;

drop policy if exists "Users can view their own favorites" on favorites;
create policy "Users can view their own favorites"
  on favorites for select
  using (auth.uid() = user_id);

drop policy if exists "Users can add their own favorites" on favorites;
create policy "Users can add their own favorites"
  on favorites for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can remove their own favorites" on favorites;
create policy "Users can remove their own favorites"
  on favorites for delete
  using (auth.uid() = user_id);

-- =====================================================================
-- REPORTS
-- =====================================================================
create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references listings(id) on delete cascade not null,
  reporter_id uuid references auth.users(id) on delete set null,
  reason text not null,
  details text,
  status text not null default 'pending' check (status in ('pending', 'reviewed', 'dismissed')),
  created_at timestamptz not null default now()
);

alter table reports enable row level security;

drop policy if exists "Anyone signed in can submit a report" on reports;
create policy "Anyone signed in can submit a report"
  on reports for insert
  with check (auth.uid() = reporter_id);

drop policy if exists "Reporters can view their own submitted reports" on reports;
create policy "Reporters can view their own submitted reports"
  on reports for select
  using (auth.uid() = reporter_id);

drop policy if exists "Admins can view all reports" on reports;
create policy "Admins can view all reports"
  on reports for select
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid() and profiles.is_admin = true
    )
  );

drop policy if exists "Admins can update reports" on reports;
create policy "Admins can update reports"
  on reports for update
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid() and profiles.is_admin = true
    )
  );

-- =====================================================================
-- NOTIFICATIONS
-- (rows are created by the listings_notify_status_change trigger above)
-- =====================================================================
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  type text not null,
  content text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table notifications enable row level security;

drop policy if exists "Users can view their own notifications" on notifications;
create policy "Users can view their own notifications"
  on notifications for select
  using (auth.uid() = user_id);

drop policy if exists "Users can mark their own notifications as read" on notifications;
create policy "Users can mark their own notifications as read"
  on notifications for update
  using (auth.uid() = user_id);

-- =====================================================================
-- TABLE PERMISSIONS
-- (needed because "automatically expose new tables" is turned off)
-- =====================================================================
grant select on public.listings to anon;
grant select, insert, update, delete on public.listings to authenticated;

grant select on public.media to anon;
grant select, insert, delete on public.media to authenticated;

grant select, insert, delete on public.favorites to authenticated;

grant select, insert, update on public.reports to authenticated;

grant select, update on public.notifications to authenticated;

grant select on public.profiles to anon;
grant select, insert, update on public.profiles to authenticated;

-- =====================================================================
-- STORAGE: listing photos (public bucket, 5 MB per file)
-- =====================================================================
insert into storage.buckets (id, name, public, file_size_limit)
values ('listing-photos', 'listing-photos', true, 5242880)
on conflict (id) do nothing;

drop policy if exists "Authenticated users can upload listing photos" on storage.objects;
create policy "Authenticated users can upload listing photos"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'listing-photos');

drop policy if exists "Users can delete their own listing photos" on storage.objects;
create policy "Users can delete their own listing photos"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'listing-photos' and owner = auth.uid());