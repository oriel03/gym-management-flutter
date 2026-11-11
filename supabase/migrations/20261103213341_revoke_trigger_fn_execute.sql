-- La función del trigger no debe poder llamarse por /rest/v1/rpc
revoke execute on function public.protect_user_privileged_columns() from public, anon, authenticated;
