# Guía de desarrollo — Valhalla Gym

Documento para retomar el proyecto: dónde quedó, cómo funciona por dentro y qué sigue.
**Actualizalo al final de cada sesión de trabajo** (sección [Estado actual](#estado-actual) y [Bitácora](#bitácora)).

---

## Para retomar en 5 minutos

```bash
git checkout feature/backend-email   # rama de trabajo actual
git pull
flutter pub get
flutter analyze                      # debería dar 0 errores
flutter run -d chrome --dart-define-from-file=secrets.json
```

1. Leé [Estado actual](#estado-actual) y [Próximos pasos](#próximos-pasos).
2. Si tenés graphify instalado: `graphify update .` y abrí `graphify-out/graph.html` para ver el mapa del código (la carpeta está en `.gitignore`).
3. Si no tenés `secrets.json`, mirá el [README](../README.md#2-credenciales).

---

## Estado actual

_Última actualización: 11/11/2026 — rama `feature/backend-email`_

**Funciona**
- Login con usuario + PIN, registro de personal, aprobación o rechazo por el admin.
- Recuperación de PIN con `resetPasswordForEmail` de Supabase y pantalla para elegir el PIN nuevo.
- Alumnos: alta con plan, edición, desactivación y listado filtrado por rol.
- RLS por rol en la base (migraciones del 03/11/2026).

**Hecho en `SupabaseService` pero sin pantalla**
- Pagos: `registerPayment`, `getAllPayment`, `getPaymentStudent`, `getPaymentByPeriod`, `updatePaymentStatus`
- Planes: `getPlans`, `addPlan`, `updatePlan`, `assignPlan`, `getPlanHistoryByStudent`
- Estadísticas: `getEstadisticasCompletas`, `getEstadisticasByProfesor`
- Alertas: `getStudentsWithPendingPayments`, `getStudentsWithExpiringPlans`

**Calidad:** `flutter analyze` da 2 avisos (`use_build_context_synchronously` en `dashboard_screen.dart:935` y `:942`). Hay un solo test (`test/widget_test.dart`).

---

## Próximos pasos

En orden sugerido:

1. **Pantalla de Pagos**: el servicio ya está. Conectarla en `navigateToPagos()` de `dashboard_screen.dart` (hoy está comentada).
2. **Arreglar el deploy de Vercel**: `build.sh` no pasa `--dart-define` y fija Flutter `3.8.0-124.0.dev`. Sin las credenciales, la web se detiene al iniciar. Pasarlas desde variables de entorno de Vercel:
   `flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY`
3. **Pantalla de Planes** (ABM y asignación a alumnos).
4. **Panel de estadísticas y alertas** (pagos pendientes, planes por vencer).
5. **Perfil y Configuración** (hoy solo muestran un aviso).
6. **Limpieza**:
   - `lib/router/app_router.dart` no se usa: `main.dart` usa `AuthWrapper`. Elegir uno y borrar el otro.
   - `component_list_alumnos.dart:290` tiene `onPressed: () => const AuthWrapper()`, que no hace nada.
   - Borrar `api/send-recovery-pin.js`, la sección `builds` de `vercel.json` y `package.json` cuando ya no se necesiten.
   - Resolver los 2 avisos de `flutter analyze`.
7. **Verificar** que las migraciones de `supabase/migrations/` estén aplicadas en el proyecto remoto.

---

## Cómo funciona

### Arranque
`main.dart` valida las credenciales (`core/config/env.dart`, leídas con `String.fromEnvironment`), inicializa Supabase, crea `AuthProvider` y muestra `AuthWrapper`.

### Autenticación
`AuthProvider` (`lib/providers/auth_provider.dart`) escucha `onAuthStateChange` de Supabase y expone un `AuthStatus`:

| Estado | Pantalla (`AuthWrapper`) |
|---|---|
| `checking` | spinner |
| `unauthenticated` | `LoginScreen` |
| `recovering` | `NewPinScreen` (se abrió el link del email) |
| `authenticated` | `DashboardScreen` |

- **Login:** el usuario escribe usuario + PIN. La RPC `get_email_by_username` devuelve el email y luego se llama a `signInWithPassword(email, pin)`. El PIN **es** la contraseña de Supabase Auth.
- **Registro:** crea el usuario con `status = 'pendiente'`. El admin lo aprueba (`activo` + `is_active = true`) o lo rechaza (`inactivo`).
- **Roles (`WorkArea`):** `admin`, `bigClass`, `smallClass`. Los getters `isAdmin` e `isProfesor` del provider deciden qué se muestra.

### Datos
Todas las consultas están en `SupabaseService` (métodos `static`). Convención en los modelos: `fromMap`, `toInsertMap` y `toUpdateMap`. Los métodos de escritura devuelven `{'success': bool, 'error'?: String}`.

---

## Base de datos

Proyecto de Supabase: **Valhalla-gym**.

| Tabla / vista | Contenido |
|---|---|
| `users` | Personal (admin y profesores): `username`, `work_area`, `status`, `is_active` |
| `students` | Alumnos |
| `plans` | Planes y su `monthly_price` |
| `student_plans` | Historial de planes asignados a cada alumno |
| `payments` | Pagos, `payment_status` (`pago`, `pendiente`, …) |
| `students_details` | Vista: alumno + plan actual + último pago (la usa el listado) |

**Funciones clave**
- `is_admin()` e `is_active_staff()`: los usan las políticas RLS.
- `get_email_by_username(username)`: usada en el login.
- `create_student_with_plan(...)`: alta de un alumno con su plan en una sola transacción.
- `protect_user_privileged_columns()`: trigger que impide que un usuario se cambie el rol o el estado.

**Migraciones:** van en `supabase/migrations/` con el formato `AAAAMMDDHHMMSS_descripcion.sql`. Nunca cambies la base desde el dashboard sin dejar su migración en el repo.

---

## Seguridad: reglas del proyecto

- Credenciales solo por `--dart-define` o `secrets.json`. Nunca en el código ni en commits.
- En la app, solo la **anon key**. La `service_role` nunca sale de Supabase.
- La protección real está en RLS: cada tabla nueva necesita políticas antes de usarse.
- El endpoint `api/send-recovery-pin.js` se retiró porque permitía enviar emails arbitrarios. No revivirlo.

---

## Convenciones

- Commits en español con prefijo: `feat`, `fix`, `chore`, `docs` (ej.: `feat(pagos): pantalla de listado`).
- Ramas: `feature/<tema>` desde `main`, PR a `main`.
- Antes de commitear: `flutter analyze` sin errores nuevos.

---

## Bitácora

Agregá una línea por sesión de trabajo (la más reciente arriba).

- **11/11/2026**: Se commitea todo el trabajo pendiente en 4 commits (plataformas, seguridad, auth, alumnos). README nuevo y esta guía.
- **03/11/2026**: Migraciones de seguridad (RLS por rol, bloqueo de escalada a admin). Endpoint de email retirado; la recuperación pasa a Supabase Auth. Credenciales pasan a `--dart-define`.
- **04/12/2025**: Backend de recuperación de PIN por email en Vercel (luego retirado).
- **17/11/2025**: v1.0.0, primera versión del sistema.
