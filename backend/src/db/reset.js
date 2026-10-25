import { env } from "../config/env.js";
import { pool } from "./client.js";
import {
  applicationTables,
  databaseName,
  seedEmptyDatabase,
  withMaintenanceLock,
} from "./seed.js";

try {
  if (env.NODE_ENV === "production")
    throw new Error("Reset tidak tersedia pada NODE_ENV=production.");
  if (!databaseName || !process.argv.includes(`--confirm=${databaseName}`)) {
    throw new Error(
      `Reset menghapus seluruh data aplikasi. Hentikan API, lalu jalankan npm run db:reset -- --confirm=${databaseName || "NAMA_DATABASE"}`,
    );
  }

  await withMaintenanceLock((database) =>
    database.transaction(async (tx) => {
      for (const table of applicationTables) await tx.delete(table);
      await seedEmptyDatabase(tx);
    }),
  );

  console.info(
    "Data aplikasi direset dan fixture demo dimuat ulang. Migrasi dipertahankan.",
  );
} catch (error) {
  console.error(
    error.cause
      ? "Reset gagal. Periksa koneksi database dan migrasi."
      : error.message,
  );
  process.exitCode = 1;
} finally {
  await pool.end();
}
