import { createHash } from "node:crypto";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { count } from "drizzle-orm";
import { drizzle } from "drizzle-orm/mysql2";
import { env } from "../config/env.js";
import { pool } from "./client.js";
import * as schema from "./schema.js";

export const applicationTables = [
  schema.stockTransferItems,
  schema.stockTransfers,
  schema.warehouseStocks,
  schema.items,
  schema.warehouses,
];
export const databaseName = decodeURIComponent(
  new URL(env.DATABASE_URL).pathname.slice(1),
);

export async function withMaintenanceLock(work) {
  const connection = await pool.getConnection();
  const lockName = `warehouse-maintenance:${createHash("sha256").update(databaseName).digest("hex").slice(0, 40)}`;
  let acquired = false;
  try {
    const [[row]] = await connection.query(
      "SELECT GET_LOCK(?, 0) AS acquired",
      [lockName],
    );
    acquired = row.acquired === 1;
    if (!acquired) throw new Error("Proses seed/reset lain sedang berjalan.");
    return await work(drizzle(connection, { schema, mode: "default" }));
  } finally {
    try {
      if (acquired)
        await connection.query("SELECT RELEASE_LOCK(?)", [lockName]);
    } finally {
      connection.release();
    }
  }
}

export async function seedEmptyDatabase(tx) {
  for (const table of applicationTables) {
    const [{ total }] = await tx.select({ total: count() }).from(table);
    if (total !== 0)
      throw new Error(
        "Seed dibatalkan: database harus kosong. Gunakan db:reset secara eksplisit untuk memuat ulang demo.",
      );
  }
  await tx.insert(schema.warehouses).values([
    { id: 1, code: "GDG-A", name: "Gudang A", address: "Jakarta" },
    { id: 2, code: "GDG-B", name: "Gudang B", address: "Bekasi" },
  ]);
  await tx.insert(schema.items).values([
    { id: 1, sku: "BRG-001", name: "Baut", unit: "pcs" },
    { id: 2, sku: "BRG-002", name: "Mur", unit: "pcs" },
    { id: 3, sku: "BRG-003", name: "Ring", unit: "pcs" },
  ]);
  await tx.insert(schema.warehouseStocks).values([
    { warehouseId: 1, itemId: 1, quantity: 100 },
    { warehouseId: 2, itemId: 1, quantity: 20 },
    { warehouseId: 1, itemId: 2, quantity: 50 },
    { warehouseId: 2, itemId: 3, quantity: 30 },
  ]);
  // Missing rows deliberately represent BRG-002/B and BRG-003/A at zero.
}

const isEntryPoint =
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href;
if (isEntryPoint) {
  try {
    await withMaintenanceLock((database) =>
      database.transaction(seedEmptyDatabase),
    );
    console.info("Demo siap: 2 gudang, 3 barang, saldo awal sesuai PRD.");
  } catch (error) {
    console.error(
      error.cause
        ? "Seed gagal. Periksa koneksi database dan migrasi."
        : error.message,
    );
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}
