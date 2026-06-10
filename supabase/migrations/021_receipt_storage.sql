insert into storage.buckets (id, name, public) values ('receipts', 'receipts', true)
on conflict (id) do update set public = true;

create policy "Receipts are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'receipts' );

create policy "Authenticated users can upload receipts"
  on storage.objects for insert
  with check ( bucket_id = 'receipts' and auth.role() = 'authenticated' );
