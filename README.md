# Zoc

Desktop time-tracking app for logging work against projects, clients, and tasks. Built with Flutter (FlutterFlow origin), focused on **Windows** and **macOS**, with optional system-tray support on Windows.

## Features

- **Authentication** — login, registration, email verification (OTP), password recovery/reset
- **Expediente (timesheet)** — select project, tasks, notes; mark remote vs on-site work
- **Periodic activity prompts** — timer-driven popup with optional screenshot capture when logging entries
- **Offline queue** — unsynced entries persisted locally and retried later
- **Work hours & completed tasks** — fetch and display user metrics from the API
- **Export** — PDF and CSV generation for activity reports
- **Desktop shell** — fixed window size, system tray (Windows): open, sign out, quit

## Platforms

| Platform | Status |
|----------|--------|
| Windows  | Primary (system tray + window manager) |
| macOS    | Supported (window manager) |
| Web / Android / iOS / Linux | Present in repo; not the main target |

Default desktop window: **510×435** (min), max **600×600**.

## Stack

- **Flutter** (stable) / Dart SDK `>=3.0.0 <4.0.0`
- **Routing** — `go_router`
- **State** — `provider` + `FFAppState` (persisted via secure storage)
- **Auth** — custom auth manager (Bearer access/refresh tokens)
- **Backend API** — REST (`/api/v1/...`)
- **Supabase** — client initialized for schema/tables (FlutterFlow-generated)
- **Locales** — Portuguese (`pt`)

## Project structure

```
lib/
├── main.dart                 # App bootstrap, window/tray, providers
├── app_state.dart            # Global persisted state
├── index.dart                # Page exports
├── auth/custom_auth/         # Token auth manager
├── backend/
│   ├── api_requests/         # REST calls, API config, manager
│   ├── schema/               # Typed structs
│   ├── supabase/             # Supabase client + table models
│   └── sqlite/               # Optional local SQLite (commented out in main)
├── expediente/               # Main timesheet screen
├── login/, entrar_con_senha/, logout*/, …
├── pages/popup_dialog/       # Activity logging popup
├── custom_code/actions/      # PDF/CSV, email helpers
├── utils/                    # Errors, screenshots, secure storage
└── flutter_flow/             # Theme, nav, i18n, shared widgets
```

## Screens & routes

| Screen | Route | Purpose |
|--------|-------|---------|
| Login | `/login` | Email/password sign-in |
| Entrar com senha | `/entrarConSenha` | Password entry flow |
| Final registration | `/finalRegistration` | Complete signup |
| Confirmar email | `/confEmail` | Email confirmation |
| Verify token | `/verifyToken` | OTP / token verification |
| Email enviado | `/emailEnviado` | Confirmation email sent |
| Recover password | `/recoverPassword` | Request reset |
| Redefinir senha | `/redefinirSenha` | Set new password |
| Senha alterada | `/senhaAlterada` | Password changed |
| Mensagem antes expediente | `/mensajeAntesExpediente` | Pre-timesheet notice |
| Expediente | `/expediente` | Main timesheet |
| Info | `/info` | App / account info |
| Logout | `/logout` | Session end (timer/activity) |
| Confirma logout | `/confirmaLogout` | Confirm sign-out |
| Logout confirmado | `/logoutConfirmado` | Signed out |

Navigation is defined in `lib/flutter_flow/nav/nav.dart`.

## API

Base URL is selected in `lib/backend/api_requests/api_config.dart`:

| Mode | Base URL |
|------|----------|
| Debug (`kDebugMode`) | `http://localhost:8089` |
| Release | `https://zoc-be-api-mzah.onrender.com` |

### Main endpoints

| Call | Method | Path |
|------|--------|------|
| Login | `POST` | `/api/v1/auth/login-app` |
| Register | `POST` | `/api/v1/auth/register-app` |
| Verify email | `POST` | `/api/v1/auth/verify-email` |
| Confirm email (OTP) | `POST` | `/api/v1/auth/confirm-email` |
| Resend confirmation | `POST` | `/api/v1/auth/resend-confirmation` |
| Forgot password | `POST` | `/api/v1/auth/forgot-password` |
| Reset password | `POST` | `/api/v1/auth/reset-password` |
| Add time entry | `POST` | `/api/v1/timemanager/entries` |
| Ignored popups | — | `/api/v1/timemanager/entries/ignored/{id}` |
| User projects | `GET` | `/api/v1/assignments/projects/user/{userId}` |
| Clients | `GET` | `/api/v1/clients` |
| Tasks by project | `GET` | `/api/v1/tasks/app/project/{id}` |
| Worked hours | `GET` | `/api/v1/users/work-hours/{userId}` |
| Tasks done | `GET` | `/api/v1/tasks/user/done/{userId}` |

Authenticated requests send `Authorization: Bearer <access_token>`.

Time entries may include: tasks, project id, remote flag, notes, timestamp, screenshot (base64), and ignored-popup flag.

## Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) stable
- For Windows builds: Visual Studio with desktop C++ workload
- For macOS builds: Xcode
- Local API on port **8089** when running in debug (or change `api_config.dart`)

### Setup

```bash
git clone git@github.com:zocdev/app.git
cd app
flutter pub get
```

### Run

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

### Build

```bash
flutter build windows --release
flutter build macos --release
```

Windows installers / redistributables may live under `installers/` (e.g. VC++ runtime).

## Configuration notes

- **API base URL** — `lib/backend/api_requests/api_config.dart`
- **Supabase** — `lib/backend/supabase/supabase.dart` (URL + anon key)
- **Persisted state** — email, user data, remember-me, offline `dataSave` queue via `SecureStorageService`
- **SQLite** — manager exists under `lib/backend/sqlite/`; initialization in `main.dart` is currently commented out

## Auth & session flow

1. User logs in via `LoginCall` → access/refresh tokens stored by `CustomAuthManager`
2. App loads projects/tasks/clients for the expediente screen
3. Periodic timer (logout / activity flow) can show `PopupDialog`, optionally attach a screenshot, and POST a time entry
4. Sign-out clears tokens and `FFAppState` user fields; Windows tray can trigger the same flows

## Development

```bash
flutter analyze
flutter test
```

Lint rules: `analysis_options.yaml` (`flutter_lints`).

## Repository

- GitHub: [zocdev/app](https://github.com/zocdev/app)
- Package name in `pubspec.yaml`: `zoc`
- App display name: **Zoc**




