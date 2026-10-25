import { fileURLToPath } from "node:url";
import { drizzle } from "drizzle-orm/mysql2";
import { migrate } from "drizzle-orm/mysql2/migrator";
import { pool } from "./client.js";
import { databaseError } from "../shared/app-error.js";

let connection;
try {
  connection = await pool.getConnection();
  await migrate(drizzle(connection), {
    migrationsFolder: fileURLToPath(new URL("../../drizzle", import.meta.url)),
  });

  console.info(
    "Migrasi database selesai. Jalankan db:seed secara terpisah untuk fixture demo.",
  );
} catch (err) {
  const driver = databaseError(err);
  const code = driver?.code ? ` [${driver.code}]` : "";
  console.error(
    `Migrasi gagal${code}. Periksa DATABASE_URL, izin database, dan kompatibilitas versi database.`,
  );
  process.exitCode = 1;
} finally {
  connection?.release();
  await pool.end();
}
