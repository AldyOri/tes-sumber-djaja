# Warehouse Stock Transfer API

**English** | [Bahasa Indonesia](README.id.md)

Backend for **Case 2: Mutasi Stok Antar Gudang**, based on [the PRD](../prd.md). Stack: Node.js/JavaScript ES modules, Express 5, MySQL/InnoDB, Drizzle ORM and Drizzle Kit. npm manages dependencies through the committed `package-lock.json`; the application scripts run on Node.js.

## Requirements and startup

- Node.js 22+ (developed with Node.js 24).
- npm (included with Node.js).
- MySQL 8.4 (recommended), or MariaDB 10.4+ with InnoDB. Use Laragon, an existing local database installation, or Docker Compose (the included service runs MySQL 8.4).

Run from the repository root. `cp` works in PowerShell and common Unix shells. Keep an existing `.env` if you have already configured it.

```sh
cd backend
npm ci
cp .env.example .env
```

Choose **one** database option below, then continue with migration and startup.

### Option A: Docker Compose

The example `.env` matches the database name, account, password, and port in `compose.yaml`:

```sh
docker compose up -d --wait
```

### Option B: Laragon (without Docker)

Laragon manages the local database service; the Express API runs separately through npm. Keep the repository in its current folder and use the API at `http://localhost:3000/api`.

1. Install/open Laragon and start its MySQL service from the service menu. Use MySQL 8.4 (recommended), or MariaDB 10.4+ with InnoDB. Check the actual server version; Laragon installations can contain different versions. See [Laragon's service menu](https://laragon.app/docs/context-menu) and [adding a MySQL version](https://laragon.org/docs/operations).
2. Open Laragon's **Terminal**, which provides its tools on `PATH`. Connect as `root` or another database administrator, using the database port configured in Laragon (3306 in these examples):

```sh
mysql -h 127.0.0.1 -P 3306 -u root -p
```

Enter that administrator account's password when prompted. If you configured an account with an empty password, press Enter. You can also execute the SQL below in a database client's query window connected as an administrator. See [Laragon's terminal environment](https://laragon.org/docs/isolated).

3. Check the server version, then create an empty database and an application account once for a fresh installation:

```sql
SELECT VERSION();

CREATE DATABASE warehouse_transfer
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'warehouse'@'127.0.0.1' IDENTIFIED BY 'warehouse_dev';
GRANT ALL PRIVILEGES ON warehouse_transfer.* TO 'warehouse'@'127.0.0.1';
```

In the `mysql` client, run `EXIT;` afterward to return to the terminal. The application account has migration and read/write privileges on its database. If the database/account already exists, reuse its configured credentials and privileges instead of recreating it. Account setup follows MySQL's [CREATE USER and GRANT workflow](https://dev.mysql.com/doc/refman/8.4/en/creating-accounts.html).

4. Edit `backend/.env` to match the database connection:

```dotenv
DATABASE_URL=mysql://warehouse:warehouse_dev@127.0.0.1:3306/warehouse_transfer
```

This URL matches the SQL example and `.env.example`. Change the port, username, password, or database name to match your installation. Percent-encode special characters in URL credentials, for example `@` as `%40` and `#` as `%23`. MariaDB also uses the `mysql://` URL scheme. The `MYSQL_*` variables are consumed only by Docker Compose; changing them does not configure Laragon or the API connection.

5. Optionally check the application login from Laragon's Terminal. Enter `warehouse_dev` at the password prompt, then run `SELECT DATABASE(), VERSION();` and `EXIT;`:

```sh
mysql -h 127.0.0.1 -P 3306 -u warehouse -p warehouse_transfer
```

Continue with the npm commands below in PowerShell or another terminal where Node.js 22+ and npm are available.

### Migrate, seed, and start

For either database option, run from `backend/`:

```sh
npm run db:migrate
npm run db:seed
npm run dev
```

Seed only an empty migrated application database. For an existing installation with data, apply pending migrations and start the API without running `db:seed` again. The schema uses `utf8mb4_unicode_ci`, available in both databases, and shared reads use `LOCK IN SHARE MODE` for compatibility.

The sample credentials are for the local demo. `.env` is ignored. Docker binds the database to localhost; for a local installation, use the loopback database connection above. The API binds to all interfaces for Android connectivity. Use `npm start` without watch mode. When adding dependencies, use `npm install <package>` (or `npm install --save-dev <package>`) and commit both `package.json` and `package-lock.json`.

- API: <http://localhost:3000/api>
- Readiness: <http://localhost:3000/api/health>
- Swagger UI: <http://localhost:3000/api/docs>
- OpenAPI JSON: <http://localhost:3000/api/openapi.json>

The API starts even if MySQL is unavailable so documentation remains accessible. Readiness returns 503 until the connection and migrated application tables are ready.

### Local database troubleshooting

- **Port already in use:** Laragon, XAMPP, a Windows MySQL service, and Docker can compete for port 3306. Run one database service on that port, or assign distinct ports and update `DATABASE_URL` to select the intended server.
- **`ECONNREFUSED` / connection refused:** start the database service and confirm its host/port match `DATABASE_URL`.
- **`ER_ACCESS_DENIED_ERROR` / access denied:** confirm the account, password, and host. The example account is `'warehouse'@'127.0.0.1'`, matching the URL's TCP host. Recheck its privileges as an administrator.
- **`ER_BAD_DB_ERROR` / unknown database:** create the database on the server selected by `DATABASE_URL` before running migrations.
- **Seed refuses to run:** application data already exists. Use it as-is, or follow the explicit [reset instructions](#migrations-seed-and-reset) to restore the fixture.

## Configuration

| Variable | Default/example | Purpose |
| --- | --- | --- |
| `NODE_ENV` | `development` | `development` or `production`; production disables reset. |
| `HOST` | `0.0.0.0` | HTTP listen address. |
| `PORT` | `3000` | HTTP port. |
| `DATABASE_URL` | See `.env.example` | Required MySQL connection URL. |
| `DB_POOL_SIZE` | `10` | Pool size, 1–100 connections. |
| `DB_LOCK_TIMEOUT_SECONDS` | `5` | InnoDB lock timeout, 1–60 seconds. |
| `CORS_ORIGINS` | `http://localhost:5173,http://127.0.0.1:5173` | Comma-separated browser origins; include scheme/port, omit trailing slash, no wildcard. |
| `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `MYSQL_PORT` | See `.env.example` | Docker Compose only; keep `DATABASE_URL` in sync when using Docker. Laragon uses `DATABASE_URL` directly. |

Restart the API after configuration changes. Docker initialization variables apply when its volume is first created; editing `.env` does not update an existing MySQL password. Same-origin Swagger requests and clients without Origin headers are accepted. CORS is a browser policy; this MVP has no authentication.

## Database structure

Schema source: [`src/db/schema.js`](src/db/schema.js). Versioned SQL and metadata: [`drizzle/`](drizzle/). The initial migration explicitly selects InnoDB, UTF-8, and `utf8mb4_unicode_ci`.

| Table | Relationships and constraints |
| --- | --- |
| `items` | Primary ID, unique SKU, name, unit, UTC creation/update timestamps. |
| `warehouses` | Primary ID, unique code, name, optional address, UTC timestamps. |
| `warehouse_stocks` | Composite PK `(warehouse_id, item_id)`, restricted FKs to both masters, quantity check 0–2,147,483,647. |
| `stock_transfers` | Primary ID, unique reference, restricted source/destination FKs, different-warehouse check, notes, UTC timestamp. |
| `stock_transfer_items` | Primary ID, restricted transfer/item FKs, unique `(transfer_id, item_id)`, quantity check 1–2,147,483,647. |

FKs and history timestamps are indexed. Stock is the operational source of truth. Seed balances are opening stock, so transfer history is not a full inventory ledger.

## Migrations, seed, and reset

```sh
# After changing the Drizzle schema, generate and review a new migration.
npm run db:generate -- --name=describe_change

# Check migration history, then apply pending migrations.
npm run db:check
npm run db:migrate

# Explicitly seed an empty migrated application database.
npm run db:seed
```

Migration application uses Drizzle's MySQL migrator on a dedicated connection and never seeds automatically. MySQL/MariaDB DDL is not fully transactional: inspect the database if a migration fails partway through before rerunning it. Keep future application tables on InnoDB with `utf8mb4_unicode_ci`.

If an earlier revision failed on its first `CREATE TABLE` with `Unknown collation: utf8mb4_0900_ai_ci`, update the code and rerun `npm run db:migrate`. That failed statement did not create the table, so this case needs no reset or data deletion. Migration errors now include the database error code without printing SQL or credentials.

If XAMPP subsequently stalls at `Creating table` and its `mysql_error.log` reports InnoDB tablespace errors (for example for `mysql.gtid_slave_pos.ibd`), resolve the database server issue before retrying. This is separate from the unsupported collation. The compatibility changes were manually verified on a clean MariaDB 10.4.28 instance, including repeat migration, seed, transfers, rollback, and concurrent stock requests.

The seed refuses to run if **any application table contains data**. It does not overwrite an active demo. Seed/reset commands share an advisory lock to prevent simultaneous maintenance scripts. Stop the API before either command so application writes cannot race with maintenance.

| SKU (ID) | Item | Unit | Gudang A (ID 1) | Gudang B (ID 2) |
| --- | --- | --- | --- | --- |
| BRG-001 (1) | Baut | pcs | 100 | 20 |
| BRG-002 (2) | Mur | pcs | 50 | 0 |
| BRG-003 (3) | Ring | pcs | 0 | 30 |

The zero balances deliberately have no physical stock row. Stock queries display zero; transfers create destination rows when needed. Creating a master record never adds starting stock.

To discard application data and restore the fixture, stop the API and explicitly confirm the database name from `DATABASE_URL`:

```sh
npm run db:reset -- --confirm=warehouse_transfer
```

Reset deletes application rows in FK order and seeds in one transaction. Failure rolls back previous data. Migration metadata is retained; auto-increment counters are not reset. There is no reset on startup. `NODE_ENV=production` disables the command. Stop the Docker service while retaining data with `docker compose down`.

## API contract

All paths below start with `/api`. POST/PUT require `Content-Type: application/json`; body limit is 64 KiB. The Swagger specification includes all request/response schemas and examples.

| Method | Path | Behavior |
| --- | --- | --- |
| GET | `/health` | Database/application readiness. |
| GET | `/items?search=&page=&limit=` | Paginated SKU/name search. |
| POST | `/items` | Create item with zero stock. |
| PUT | `/items/:id` | Replace item metadata. |
| GET | `/warehouses?search=&page=&limit=` | Paginated code/name search. |
| POST | `/warehouses` | Create warehouse with zero stock. |
| PUT | `/warehouses/:id` | Replace warehouse metadata. |
| GET | `/warehouses/:id/stocks?search=&page=&limit=` | All items and quantities, including zero stock. |
| POST | `/transfers` | Atomically complete a multi-item transfer. |
| GET | `/transfers?sourceWarehouseId=&destinationWarehouseId=&page=&limit=` | Filter history, newest first. |
| GET | `/transfers/:id` | Header and item details. |
| GET | `/docs` | Swagger UI. |
| GET | `/openapi.json` | OpenAPI specification. |

Pagination defaults to page 1, limit 20; maximum limit is 100. Master selectors must fetch subsequent pages. Omit unused warehouse filters rather than sending empty strings. Unknown keys and repeated query parameters are rejected. Search treats `%` and `_` literally. Lists use stable ordering with ID tie-breakers.

Successful responses use `{ "data": ... }`; lists also include `{ "meta": { "page": 1, "limit": 20, "total": 3 } }`. Errors use:

```json
{
  "error": {
    "code": "INSUFFICIENT_STOCK",
    "message": "Stok BRG-001 tidak mencukupi.",
    "fields": { "items.0.quantity": "Stok tersedia 100." }
  }
}
```

Statuses: 400 malformed JSON/invalid query or path syntax; 403 disallowed Origin; 404 absent resource; 409 duplicate code/insufficient stock/locked unit; 413 body too large; 415 unsupported content type/encoding; 422 invalid payload/reference or destination overflow; 503 unavailable database/lock contention; 500 unexpected failure. `fields` is optional. Responses include `X-Request-Id`; server logs use safe metadata without SQL, payloads, credentials, or returned stack traces.

## Transfer rules

[`transfers.service.js`](src/modules/transfers/transfers.service.js) owns the stock-changing transaction:

1. Acquire shared master locks in ascending warehouse/item ID order. Item edits acquire an exclusive item lock, preventing unit changes from racing with a transfer.
2. Create or lock balance rows in ascending `(warehouse_id, item_id)` order. The composite primary key serializes concurrent destination creation. No-op locking preserves existing balances and update timestamps.
3. Check every source balance and destination overflow before writes. Missing source rows count as zero. All quantities stay within the signed INT range.
4. Update both warehouses, insert the header/lines, and read the completed transfer in one Drizzle transaction.
5. Commit together, or roll back everything, including newly created balance rows, if any operation fails.

Transactions use READ COMMITTED and never retry automatically. `503 DATABASE_BUSY` means deadlock/lock timeout after rollback. Connection failure or an uncertain response can have an unknown commit outcome: refresh history and stock before submitting again. Independent repeated POSTs can create repeated transfers because idempotency is outside scope.

Transfers complete immediately, with no draft/status/approval stage or editing/deletion endpoint. Master deletion is not exposed. Metadata edits never change stock. Unit edits are rejected once a stock row or history exists, including a zero balance row. History reflects current master names/codes/SKU rather than snapshots.

Timestamps use UTC `DATETIME(3)` and ISO 8601 UTC responses. Display Asia/Jakarta (WIB, UTC+07:00) in the frontend. UI-facing validation messages use Bahasa Indonesia; identifiers use English.

## Manual walkthrough

No test files, test database service, or test framework are included, as requested. `npm run check` checks JavaScript syntax and YAML parsing; `npm run db:check` validates migration history. These checks do not prove transaction/concurrency behavior.

After migration and a fresh seed:

1. Open Swagger UI and retrieve both warehouses' stocks. Confirm the fixture table, including zeros.
2. POST `/transfers` with the following body:

   ```json
   {
     "sourceWarehouseId": 1,
     "destinationWarehouseId": 2,
     "notes": "Demo AC-03",
     "items": [{ "itemId": 1, "quantity": 10 }]
   }
   ```

3. Expect 201 with a generated reference. A now holds 90 BRG-001; B holds 30. Total remains 120. Open the returned transfer ID and filtered history.
4. Transfer 5 BRG-002 from A to B. A should hold 45 and B 5, creating B's absent balance once.
5. Submit two lines with one exceeding stock. Expect 409 and no stock/history changes. Also reject duplicate items, equal warehouses, decimals, numeric strings, zero, negatives, and invalid references.
6. Create/edit masters; confirm trimmed uppercase codes, duplicate errors, zero starting stock, and blocked unit edits for seeded items.
7. For concurrency, reset the fixture, start the API, and send two independent simultaneous transfers of 80 BRG-001 from A to B. Exactly one should succeed. A should end at 20, B at 100, with one history entry. Inspect results rather than retrying automatically.

Overflow and database-failure rollback require deliberate preparation in a disposable local database. Restore the fixture afterward; do not infer these cases passed from syntax checks.

## Flutter connectivity

`frontend/` is reserved for later Flutter implementation; no Flutter screens are created by this backend delivery.

| Target | API base URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:3000/api` |
| Physical Android device | `http://<computer-LAN-IP>:3000/api` |
| Web on the development computer | `http://localhost:3000/api` |

Android is the primary target. Install Flutter and the Android SDK, and start an emulator or connect a device. A physical device must share the computer's network; allow inbound TCP 3000 through the development firewall. Local Android HTTP needs Internet permission and debug-only cleartext configuration. Use HTTPS for a later deployment.

Once Flutter is initialized and its client reads `String.fromEnvironment('API_BASE_URL')`, the intended commands are:

```sh
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=http://localhost:3000/api
```

Pin the web port to match `CORS_ORIGINS`. The frontend should retain rejected form input, clear lines on source changes, refresh affected stocks/history on success, and never automatically retry transfer POSTs.

## Structure and scope

```text
compose.yaml          Local MySQL service
drizzle.config.js     Drizzle Kit configuration
drizzle/              SQL migrations, snapshots, journal
docs/openapi.yaml     API contract
scripts/check.js      Syntax/YAML checks
src/
  app.js              Middleware, routing, Swagger
  server.js           Startup and graceful shutdown
  config/env.js       Validated environment
  db/                 Client, schema, migration runner, seed/reset
  shared/             Errors, validation, pagination
  middleware/         Request validation and error handling
  modules/
    health/           Readiness
    items/            Routes, validation, service, repository
    warehouses/       Routes, validation, service, repository
    stocks/           Routes, validation, service, repository
    transfers/        Routes, validation, service, repository
```

Authentication, roles, receiving, manual adjustments, cancellation, deletion, deployment, and Flutter implementation are outside this backend delivery.
