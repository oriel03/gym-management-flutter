# Valhalla Gym — Sistema de gestión

App Flutter para administrar el gimnasio Valhalla: alumnos, planes, pagos y el personal (admin y profesores). El backend es Supabase (Auth + Postgres con RLS).

> **¿Volvés al proyecto después de un tiempo?** Leé [docs/GUIA_DESARROLLO.md](docs/GUIA_DESARROLLO.md): estado actual, dónde está cada cosa y qué sigue.

## Funcionalidades

| Módulo | Estado |
|---|---|
| Login con usuario + PIN | ✅ |
| Registro de personal con aprobación del admin | ✅ |
| Recuperación de PIN por email (Supabase Auth) | ✅ |
| Alumnos: alta con plan, edición, baja, búsqueda | ✅ |
| Vista por rol: el admin ve todo, cada profesor ve sus alumnos | ✅ |
| Pagos | 🟡 backend listo, falta pantalla |
| Planes (ABM y asignación) | 🟡 backend listo, falta pantalla |
| Estadísticas, pagos pendientes, planes por vencer | 🟡 backend listo, falta pantalla |
| Perfil y configuración | ⬜ pendiente |

## Tecnologías

- **Flutter** (Dart SDK ^3.8): Android, iOS, web y escritorio
- **Supabase**: autenticación, base de datos Postgres y Row Level Security
- **provider**: estado global (`AuthProvider`)
- **Vercel**: hosting de la versión web

## Puesta en marcha

### 1. Requisitos
- Flutter estable (probado con 3.38)
- Acceso al proyecto de Supabase **Valhalla-gym**

### 2. Credenciales
Las credenciales **no van en el código**. Creá `secrets.json` en la raíz (ya está en `.gitignore`):

```json
{
  "SUPABASE_URL": "https://<proyecto>.supabase.co",
  "SUPABASE_ANON_KEY": "<anon key>"
}
```

Los dos valores están en Supabase → *Project Settings → API*. Usá solo la **anon key**, nunca la `service_role`.

### 3. Ejecutar

```bash
flutter pub get
flutter run --dart-define-from-file=secrets.json            # dispositivo por defecto
flutter run -d chrome --dart-define-from-file=secrets.json  # web
```

Si faltan las credenciales, la app se detiene al iniciar con un mensaje claro (`lib/main.dart`).

### 4. Verificar

```bash
flutter analyze
flutter test
```

## Estructura

```
lib/
├── main.dart            Inicializa Supabase y los providers
├── core/config/env.dart Lee las credenciales de --dart-define
├── providers/           AuthProvider: sesión, rol y estado de auth
├── screens/             Login, recuperación, nuevo PIN, dashboard, AuthWrapper
├── components/          Formularios, lista de alumnos, navbar, calendario
├── models/              User, Student, StudentDetails, Plan, StudentPlan, Payment
├── services/            SupabaseService: todas las consultas a la base
└── utils/               Responsive (breakpoints) e imágenes
supabase/migrations/     Cambios de base de datos (RLS, funciones)
api/                     Endpoint de Vercel retirado (responde 410)
```

## Base de datos

Tablas: `users`, `students`, `plans`, `student_plans`, `payments` y la vista `students_details`. Los permisos se controlan con RLS mediante las funciones `is_admin()` e `is_active_staff()`. Más detalle en la [guía de desarrollo](docs/GUIA_DESARROLLO.md#base-de-datos).

## Deploy

La web se publica en Vercel (`vercel.json` + `build.sh`). **Importante:** el build todavía no pasa las credenciales con `--dart-define`; ver los pendientes en la guía.
