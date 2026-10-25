# Sumber Djaja — Warehouse Stock Transfer App

**English** | [Bahasa Indonesia](README.id.md)

A full-stack implementation of **Studi Kasus 2: Mutasi Stok Antar Gudang** for the [full-stack developer practical test](Practical_Test_Fullstack_Developer.md). The app manages items, warehouses, stock balances, and transfers through a Flutter client and a REST API. Android is the primary target; web supports the same core workflows.

See the [product requirements](prd.md), [backend guide](backend/README.md), and [frontend guide](frontend/README.md) for detailed contracts, configuration, and implementation notes.

## Features

- Create and edit item and warehouse masters, with search, pagination, and duplicate-code validation.
- View stock per warehouse, including items with zero balances.
- Transfer multiple distinct items between warehouses with positive whole-number quantities.
- Update source stock, destination stock, and transfer history in one database transaction. Insufficient stock or another failed operation rolls back the entire transfer.
- Browse transfer history, filter by source/destination, and open immutable transfer details.
- Use responsive layouts, Bahasa Indonesia labels and validation, and timestamps displayed in WIB (UTC+7).
- Explore the API through Swagger UI and its OpenAPI specification.

## Technology and structure

| Layer | Technology |
| --- | --- |
| Frontend | Flutter / Dart, Android and web |
| Backend | Node.js / JavaScript ES modules, Express 5 |
| Database | MySQL / InnoDB, with MariaDB compatibility |
| Data access | Drizzle ORM, Drizzle Kit, versioned SQL migrations |
| API documentation | OpenAPI and Swagger UI |

```text
backend/
  src/                 API routes, validation, services, repositories, database
  drizzle/             SQL migrations and metadata
  docs/openapi.yaml    API specification
  compose.yaml         Local MySQL service
frontend/
  lib/app/             App setup, dependencies, theme, navigation
  lib/core/            API configuration, networking, utilities
  lib/shared/          Shared controllers and widgets
  lib/features/        Items, warehouses, stocks, transfers
prd.md                 Scope, business rules, acceptance criteria
```

The database contains `items`, `warehouses`, `warehouse_stocks`, `stock_transfers`, and `stock_transfer_items`. Foreign keys preserve relationships; ordered row locking protects stock during concurrent transfers. See the [database structure](backend/README.md#database-structure) for constraints and the [frontend structure](frontend/README.md#structure-and-reading-the-code) for screen/controller/repository responsibilities.

## Prerequisites

- Node.js 22+ and npm.
- MySQL 8.4 (recommended) or MariaDB 10.4+ with InnoDB, running locally through Laragon or another installation. Alternatively, use Docker with Compose for the included MySQL 8.4 service.
- Flutter with Dart 3.11+.
- For Android: Android Studio, accepted SDK licenses, an emulator or USB-debuggable device, Android SDK Platform 36, Build-Tools 36, and NDK `27.1.12297006`.
- For web: Chrome.

## Run locally

### 1. Start the backend

From the repository root, install dependencies and create the local configuration file. If `.env` already exists and is configured, keep it and skip the copy command:

```sh
cd backend
npm ci
cp .env.example .env
```

Choose one database option below, then continue to migration and startup.

#### Option A: Docker Compose

The example `.env` matches the included MySQL service:

```sh
docker compose up -d --wait
```

#### Option B: Laragon (without Docker)

1. Open Laragon and start its MySQL service. Use MySQL 8.4 or a compatible MariaDB 10.4+ installation with InnoDB.
2. Connect to that server through a database client as `root` or another administrator, and run the following SQL once for a fresh installation:

```sql
CREATE DATABASE warehouse_transfer
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'warehouse'@'127.0.0.1' IDENTIFIED BY 'warehouse_dev';
GRANT ALL PRIVILEGES ON warehouse_transfer.* TO 'warehouse'@'127.0.0.1';
```

3. Set the connection URL in `backend/.env`. This example assumes Laragon's database listens on port 3306:

```dotenv
DATABASE_URL=mysql://warehouse:warehouse_dev@127.0.0.1:3306/warehouse_transfer
```

Adjust the URL if your database port or credentials differ. The `MYSQL_*` variables configure Docker only; a Laragon setup uses `DATABASE_URL`. Laragon manages the database while the API runs through npm on port 3000. The repository can stay in its current folder.

See the [detailed Laragon setup](backend/README.md#option-b-laragon-without-docker) for terminal login commands, connection checks, and troubleshooting. Use one database service per port when switching between Laragon and Docker.

#### Migrate, seed, and start the API

For either database option, run from `backend/`:

```sh
npm run db:migrate
npm run db:seed
npm run dev
```

The seed runs only when all application tables are empty. For an existing installation with data, apply pending migrations and start the API without seeding again. Stop the API before manually seeding or resetting an existing installation; starting the API never resets or reseeds data.

The example configuration listens on `0.0.0.0:3000` for Android connectivity. For Docker, keep `DATABASE_URL` synchronized with its database settings if you change them. See the [backend configuration guide](backend/README.md#configuration) for all variables.

| Resource | Local URL |
| --- | --- |
| API base | <http://localhost:3000/api> |
| Database readiness | <http://localhost:3000/api/health> |
| Swagger UI | <http://localhost:3000/api/docs> |
| OpenAPI JSON | <http://localhost:3000/api/openapi.json> |

Documentation stays accessible when the database is unavailable; readiness returns HTTP 503 until the connection and migrated tables are ready.

### 2. Start the frontend

Open a second terminal at the repository root:

```sh
cd frontend
flutter doctor
flutter pub get
flutter devices
```

Start an Android emulator or connect a device, then replace `<android-device-id>` with its ID:

```sh
flutter run -d <android-device-id>
```

Alternatively, run the web app:

```sh
flutter run -d chrome --web-port=5173
```

### API connectivity

| Client | API base URL |
| --- | --- |
| Standard Android emulator | `http://10.0.2.2:3000/api` (default on Android) |
| Web on the development computer | `http://localhost:3000/api` (default on web) |
| Physical Android device on the same network | `http://<computer-LAN-IP>:3000/api` |

For a physical device, allow inbound traffic to port 3000 and supply the computer's LAN address:

```sh
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

`API_BASE_URL` must include `/api` and is configured at compile time; restart/rebuild after changing it. The backend example permits browser origins `http://localhost:5173` and `http://127.0.0.1:5173`. Update `CORS_ORIGINS` and restart the backend if the web origin changes. See the [frontend guide](frontend/README.md#android) for USB port forwarding and further device setup.

## Demo workflow

A fresh seed creates these opening balances:

| SKU | Item | Unit | Gudang A | Gudang B |
| --- | --- | --- | --- | --- |
| BRG-001 | Baut | pcs | 100 | 20 |
| BRG-002 | Mur | pcs | 50 | 0 |
| BRG-003 | Ring | pcs | 0 | 30 |

1. Open **Stok Gudang** and confirm both warehouses' balances.
2. Open **Mutasi**, select Gudang A as the source and Gudang B as the destination, and transfer 10 BRG-001. Optionally include 5 BRG-002.
3. Inspect the success reference, transfer details, and filtered history.
4. Confirm BRG-001 is now 90 in A and 30 in B. If included, BRG-002 is 45 in A and 5 in B.
5. Try an invalid quantity or insufficient stock and confirm validation preserves the form without changing stock or history.
6. Create/edit **Barang** and **Gudang** records. New records start with zero stock; metadata edits preserve balances.

For a fresh fixture after demo changes, follow the explicit [seed/reset instructions](backend/README.md#migrations-seed-and-reset). Full manual walkthroughs are in the [backend guide](backend/README.md#manual-walkthrough) and [frontend guide](frontend/README.md#verification-and-demo).

## Verification and builds

From `backend/`:

```sh
npm run check
npm run db:check
```

These validate JavaScript syntax, YAML parsing, and migration history. They do not verify transaction or concurrency behavior; use the backend manual walkthrough for those cases.

From `frontend/`:

```sh
dart format --output=none --set-exit-if-changed lib
flutter analyze
flutter build apk --debug
flutter build web
```

Build outputs are `frontend/build/app/outputs/flutter-apk/app-debug.apk` and `frontend/build/web/`. Supply `--dart-define=API_BASE_URL=...` when building for a different API address. No automated test suite is included; see the [frontend verification notes](frontend/README.md#verified-locally) for recorded local checks.

## Scope and behavior

Opening inventory comes from the seed; receiving and manual stock adjustments are outside scope. Transfers complete immediately without approval, editing, cancellation, or deletion. Item units cannot change once stock rows or transfer history exist. History displays current master names/codes rather than snapshots.

The backend does not provide server-side idempotency; repeated submissions can create repeated transfers. The frontend disables repeat submission while pending and never retries transfer POSTs automatically. An uncertain response requires reviewing history and refreshed stock before explicitly allowing another attempt.

Authentication, roles, release signing, and deployment are outside scope. HTTP configuration is intended for local development; an HTTPS web origin requires an HTTPS API.
