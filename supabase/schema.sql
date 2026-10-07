-- Run once in Supabase SQL Editor.
create table public.store_admins (user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.store_admins enable row level security;
create policy "Admins read own membership" on public.store_admins for select to authenticated using (user_id=(select auth.uid()));
grant select on public.store_admins to authenticated;
revoke all on public.store_admins from anon;
create table public.products (
 id uuid primary key default gen_random_uuid(),
 name text not null check(length(trim(name)) between 1 and 160),
 sku text not null check(length(trim(sku)) between 1 and 40),
 category text not null check(category in ('ผักและผลไม้','เนื้อสัตว์และไข่','เครื่องดื่ม','อาหารแห้ง','ของใช้ในบ้าน')),
 price numeric(12,2) not null check(price>=0),
 stock integer not null default 0 check(stock>=0),
 unit text not null default 'ชิ้น',
 image_url text not null default '',
 description text not null default '',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index products_sku_unique on public.products(lower(sku));
create index products_category_idx on public.products(category);
create index products_updated_idx on public.products(updated_at desc);
create table public.product_price_history (
 id bigint generated always as identity primary key,
 product_id uuid not null references public.products(id) on delete cascade,
 old_price numeric(12,2), new_price numeric(12,2) not null,
 changed_by uuid references auth.users(id) on delete set null,
 changed_at timestamptz not null default now()
);
create function public.track_product_price() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if TG_OP='INSERT' then
  insert into public.product_price_history(product_id,old_price,new_price,changed_by) values(NEW.id,null,NEW.price,auth.uid());
 elsif NEW.price is distinct from OLD.price then
  insert into public.product_price_history(product_id,old_price,new_price,changed_by) values(NEW.id,OLD.price,NEW.price,auth.uid());
 end if;
 return NEW;
end; $$;
revoke execute on function public.track_product_price() from public,anon,authenticated;
create trigger product_price_history_trigger after insert or update on public.products for each row execute function public.track_product_price();
create function public.touch_product() returns trigger language plpgsql set search_path='' as $$
begin NEW.updated_at=now(); return NEW; end; $$;
create trigger product_updated_trigger before update on public.products for each row execute function public.touch_product();
alter table public.products enable row level security;
alter table public.product_price_history enable row level security;
grant select on public.products to anon,authenticated;
grant insert,update on public.products to authenticated;
grant select on public.product_price_history to authenticated;
create policy "Visitors view products" on public.products for select to anon,authenticated using(true);
create policy "Admins create products" on public.products for insert to authenticated with check(exists(select 1 from public.store_admins where user_id=(select auth.uid())));
create policy "Admins update products" on public.products for update to authenticated using(exists(select 1 from public.store_admins where user_id=(select auth.uid()))) with check(exists(select 1 from public.store_admins where user_id=(select auth.uid())));
create policy "Admins view price history" on public.product_price_history for select to authenticated using(exists(select 1 from public.store_admins where user_id=(select auth.uid())));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('product-images','product-images',true,5242880,array['image/jpeg','image/png','image/webp']);
create policy "Admins upload images" on storage.objects for insert to authenticated with check(bucket_id='product-images' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.store_admins where user_id=(select auth.uid())));
create policy "Admins read image objects" on storage.objects for select to authenticated using(bucket_id='product-images' and exists(select 1 from public.store_admins where user_id=(select auth.uid())));
create policy "Admins remove own images" on storage.objects for delete to authenticated using(bucket_id='product-images' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.store_admins where user_id=(select auth.uid())));
-- After creating an owner in Authentication > Users:
-- insert into public.store_admins(user_id) values ('OWNER_USER_UUID');
