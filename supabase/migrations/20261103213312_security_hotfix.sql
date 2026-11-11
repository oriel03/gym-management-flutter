-- =====================================================================
-- 20261103_security_hotfix.sql  —  Valhalla-gym (gsapclouuokwevixbnfw)
-- Objetivo: cerrar la escalada a admin, ajustar RLS por rol y quitar
-- permisos de tabla a usuarios no logueados. NO cambia datos.
-- Revisado contra: 1 usuario admin activo, 4 alumnos, 0 pagos.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Funciones helper: search_path fijo y chequeo de cuenta activa
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.users
    where id = (select auth.uid())
      and work_area = 'admin' and is_active and status = 'activo'
  );
$$;

create or replace function public.is_active_staff()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.users
    where id = (select auth.uid()) and is_active and status = 'activo'
  );
$$;

create or replace function public.get_email_by_username(p_username text)
returns text language sql stable security definer set search_path = '' as $$
  select email from public.users where username = lower(trim(p_username)) limit 1;
$$;

create or replace function public.update_updated_at_column()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function public.is_admin(), public.is_active_staff() from public, anon;
grant execute on function public.is_admin(), public.is_active_staff() to authenticated;
-- get_email_by_username sigue siendo pública porque el login la usa antes
-- de autenticar. Plan: pasar el login a email y borrarla.

-- ---------------------------------------------------------------------
-- 2. Permisos de tabla: anon (no logueado) no toca nada
-- ---------------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke truncate, references, trigger on all tables in schema public from authenticated;
alter default privileges for role postgres in schema public revoke all on tables from anon;

-- ---------------------------------------------------------------------
-- 3. USERS: nadie puede auto-asignarse admin ni auto-aprobarse
-- ---------------------------------------------------------------------
drop policy if exists "usuarios autenticados se registran" on public.users;
drop policy if exists "usuarios autenticados ven users"   on public.users;
drop policy if exists "admin o self editan users"          on public.users;

create policy "registro propio queda pendiente" on public.users
  for insert to authenticated
  with check (
    id = (select auth.uid())
    and work_area is distinct from 'admin'
    and status = 'pendiente'
    and is_active = false
  );

create policy "staff activo ve users, cada uno ve su fila" on public.users
  for select to authenticated
  using (public.is_active_staff() or id = (select auth.uid()));

create policy "admin edita todos, cada uno su fila" on public.users
  for update to authenticated
  using      (public.is_admin() or id = (select auth.uid()))
  with check (public.is_admin() or id = (select auth.uid()));

-- Un no-admin puede editar su nombre, pero no su rol ni su estado
create or replace function public.protect_user_privileged_columns()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() and (
       new.work_area is distinct from old.work_area
    or new.status    is distinct from old.status
    or new.is_active is distinct from old.is_active
    or new.id        is distinct from old.id) then
    raise exception 'Solo un admin puede cambiar rol o estado de un usuario';
  end if;
  return new;
end;
$$;
drop trigger if exists protect_user_privileged_columns on public.users;
create trigger protect_user_privileged_columns
  before update on public.users
  for each row execute function public.protect_user_privileged_columns();

-- ---------------------------------------------------------------------
-- 4. STUDENTS: crea staff activo; edita admin o el profesor del alumno
-- ---------------------------------------------------------------------
drop policy if exists "ver alumnos propios o admin"  on public.students;
drop policy if exists "autenticados crean alumnos"   on public.students;
drop policy if exists "autenticados editan alumnos"  on public.students;
drop policy if exists "solo admin borra alumnos"     on public.students;

create policy "admin o profesor del alumno ven" on public.students
  for select to authenticated
  using (public.is_admin() or exists (
    select 1 from public.student_plans sp
    where sp.student_id = students.id and sp.profesor_id = (select auth.uid())));

create policy "staff activo crea alumnos" on public.students
  for insert to authenticated
  with check (public.is_active_staff());

create policy "admin o profesor del alumno editan" on public.students
  for update to authenticated
  using (public.is_admin() or exists (
    select 1 from public.student_plans sp
    where sp.student_id = students.id and sp.profesor_id = (select auth.uid())))
  with check (public.is_active_staff());

create policy "solo admin borra alumnos" on public.students
  for delete to authenticated using (public.is_admin());

-- ---------------------------------------------------------------------
-- 5. STUDENT_PLANS
-- ---------------------------------------------------------------------
drop policy if exists "profesor ve sus planes, admin ve todos"  on public.student_plans;
drop policy if exists "profesor crea sus planes"                on public.student_plans;
drop policy if exists "profesor edita sus planes, admin todos"  on public.student_plans;
drop policy if exists "solo admin borra planes"                 on public.student_plans;

create policy "profesor ve sus planes, admin todos" on public.student_plans
  for select to authenticated
  using (profesor_id = (select auth.uid()) or public.is_admin());

create policy "staff activo crea sus planes, admin cualquiera" on public.student_plans
  for insert to authenticated
  with check ((profesor_id = (select auth.uid()) and public.is_active_staff()) or public.is_admin());

create policy "profesor edita sus planes, admin todos" on public.student_plans
  for update to authenticated
  using      (profesor_id = (select auth.uid()) or public.is_admin())
  with check (profesor_id = (select auth.uid()) or public.is_admin());

create policy "solo admin borra planes de alumno" on public.student_plans
  for delete to authenticated using (public.is_admin());

-- ---------------------------------------------------------------------
-- 6. PAYMENTS: una sola política de lectura; quien registra queda firmado
-- ---------------------------------------------------------------------
drop policy if exists "admin ve todos los pagos"          on public.payments;
drop policy if exists "profesor ve pagos de sus alumnos"  on public.payments;
drop policy if exists "autenticados registran pagos"      on public.payments;
drop policy if exists "solo admin edita pagos"            on public.payments;

alter table public.payments alter column registered_by set default auth.uid();

create policy "admin todos, profesor los de sus alumnos" on public.payments
  for select to authenticated
  using (public.is_admin() or exists (
    select 1 from public.student_plans sp
    where sp.id = payments.student_plan_id and sp.profesor_id = (select auth.uid())));

create policy "staff activo registra pagos a su nombre" on public.payments
  for insert to authenticated
  with check (public.is_active_staff()
              and (registered_by is null or registered_by = (select auth.uid())));

create policy "solo admin edita pagos" on public.payments
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- 7. PLANS: todos los logueados ven; solo admin modifica
-- ---------------------------------------------------------------------
drop policy if exists "todos ven planes"           on public.plans;
drop policy if exists "solo admin modifica planes" on public.plans;

create policy "logueados ven planes" on public.plans
  for select to authenticated using (true);
create policy "admin crea planes"  on public.plans for insert to authenticated with check (public.is_admin());
create policy "admin edita planes" on public.plans for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin borra planes" on public.plans for delete to authenticated using (public.is_admin());

-- ---------------------------------------------------------------------
-- 8. Índices en claves foráneas (advisor de performance)
-- ---------------------------------------------------------------------
create index if not exists idx_payments_registered_by   on public.payments (registered_by);
create index if not exists idx_payments_student_plan_id on public.payments (student_plan_id);
create index if not exists idx_student_plans_plan_id    on public.student_plans (plan_id);

-- ---------------------------------------------------------------------
-- 9. Alta de alumno + plan en una sola operación (atómica)
--    Causa: el profesor no puede leer un alumno recién creado hasta que
--    exista su student_plan (RLS), y si el 2.º insert fallaba quedaba un
--    alumno huérfano. La función valida permisos explícitamente.
-- ---------------------------------------------------------------------
create or replace function public.create_student_with_plan(
  p_student jsonb,
  p_plan_id int default null,
  p_profesor_id uuid default null,
  p_preferred_shift text default 'mañana'
) returns int language plpgsql security definer set search_path = '' as $$
declare
  v_id int;
  v_prof uuid := coalesce(p_profesor_id, (select auth.uid()));
begin
  if not public.is_active_staff() then
    raise exception 'No autorizado' using errcode = '42501';
  end if;
  if v_prof <> (select auth.uid()) and not public.is_admin() then
    raise exception 'Solo un admin puede asignar alumnos a otro profesor' using errcode = '42501';
  end if;

  insert into public.students (name, last_name, email, dni, phone, date_of_birth,
    emergency_contact, emergency_phone, medical_conditions, is_active)
  values (
    trim(p_student->>'name'), trim(p_student->>'last_name'), lower(trim(p_student->>'email')),
    trim(p_student->>'dni'), nullif(trim(p_student->>'phone'), ''),
    (nullif(p_student->>'date_of_birth', ''))::date,
    nullif(trim(p_student->>'emergency_contact'), ''), nullif(trim(p_student->>'emergency_phone'), ''),
    nullif(trim(p_student->>'medical_conditions'), ''), true)
  returning id into v_id;

  if p_plan_id is not null then
    insert into public.student_plans (student_id, plan_id, profesor_id, start_date, end_date,
      preferred_shift, is_active)
    values (v_id, p_plan_id, v_prof, current_date, current_date + 30,
      p_preferred_shift::public.shift_type, true);
  end if;

  return v_id;
end;
$$;
revoke execute on function public.create_student_with_plan(jsonb, int, uuid, text) from public, anon;
grant execute on function public.create_student_with_plan(jsonb, int, uuid, text) to authenticated;
