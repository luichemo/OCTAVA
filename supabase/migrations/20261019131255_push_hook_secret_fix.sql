-- push_hook_secret_ok compared against the Vault table's own `secret`
-- column (the encrypted value) instead of its parameter; qualify it.
create or replace function public.push_hook_secret_ok(secret text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from vault.decrypted_secrets s
                 where s.name = 'push_hook_secret' and s.decrypted_secret = push_hook_secret_ok.secret);
$$;
revoke execute on function public.push_hook_secret_ok(text) from public, anon, authenticated;
grant execute on function public.push_hook_secret_ok(text) to service_role;
notify pgrst, 'reload schema';
