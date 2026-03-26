-- Create the public storage bucket used by uploaded CVs and logos.
insert into storage.buckets (id, name, public)
values ('xpbridge-assets', 'xpbridge-assets', true)
on conflict (id) do update
set public = excluded.public;

-- Allow authenticated users to upload and read files in their own folders.
create policy "storage_select_own_resume_or_logo"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/' || auth.uid()::text || '/%'
    or name like 'logos/' || auth.uid()::text || '/%'
  )
);

create policy "storage_insert_own_resume_or_logo"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/' || auth.uid()::text || '/%'
    or name like 'logos/' || auth.uid()::text || '/%'
  )
);

create policy "storage_update_own_resume_or_logo"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/' || auth.uid()::text || '/%'
    or name like 'logos/' || auth.uid()::text || '/%'
  )
)
with check (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/' || auth.uid()::text || '/%'
    or name like 'logos/' || auth.uid()::text || '/%'
  )
);

create policy "storage_delete_own_resume_or_logo"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/' || auth.uid()::text || '/%'
    or name like 'logos/' || auth.uid()::text || '/%'
  )
);
