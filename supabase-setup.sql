-- شغّل هذا السكريبت كاملاً مرة واحدة في Supabase: SQL Editor ثم New query ثم Run

-- 1) الجداول -------------------------------------------------------------
create table public.dresses (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  code       text,
  color      text,
  size       text,
  price      integer not null default 0,   -- سعر الكراء المعتاد بالدينار الجزائري
  note       text,
  photo_url  text,
  created_at timestamptz not null default now()
);

create table public.rentals (
  id         uuid primary key default gen_random_uuid(),
  dress_id   uuid not null references public.dresses(id) on delete cascade,
  customer   text not null,
  phone      text,
  start_date date not null,
  end_date   date not null check (end_date >= start_date),
  price      integer not null default 0,
  deposit    integer not null default 0,
  returned   boolean not null default false,
  extras     text[] not null default '{}',   -- المستلزمات المرفقة: باقة ورود، تاج...
  note       text,
  created_at timestamptz not null default now()
);

create index rentals_dress_idx    on public.rentals (dress_id, start_date, end_date);
create index rentals_customer_idx on public.rentals (customer);

-- 2) الحماية: فقط المستخدمون المسجّلون يقرأون ويكتبون -------------------------
alter table public.dresses enable row level security;
alter table public.rentals enable row level security;

create policy "staff full access dresses" on public.dresses
  for all to authenticated using (true) with check (true);

create policy "staff full access rentals" on public.rentals
  for all to authenticated using (true) with check (true);

-- 3) تخزين صور الفساتين -------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('dress-photos', 'dress-photos', true)
on conflict (id) do nothing;

create policy "staff upload photos" on storage.objects
  for insert to authenticated with check (bucket_id = 'dress-photos');

create policy "staff update photos" on storage.objects
  for update to authenticated using (bucket_id = 'dress-photos');

create policy "staff delete photos" on storage.objects
  for delete to authenticated using (bucket_id = 'dress-photos');

-- ملاحظة: إن كنت قد شغّلت النسخة السابقة من السكريبت، شغّل هذا السطر وحده بدلاً منه:
-- alter table public.rentals add column extras text[] not null default '{}';
