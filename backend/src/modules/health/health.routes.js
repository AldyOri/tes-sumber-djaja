import { Router } from "express";
import { sql } from "drizzle-orm";
import { db } from "../../db/client.js";
import {
  items,
  stockTransferItems,
  stockTransfers,
  warehouses,
  warehouseStocks,
} from "../../db/schema.js";
import { AppError } from "../../shared/app-error.js";

export const healthRouter = Router();

healthRouter.get("/", async (_req, res) => {
  try {
    // Readiness requires both a connection and migrated application tables.
    for (const table of [
      items,
      warehouses,
      warehouseStocks,
      stockTransfers,
      stockTransferItems,
    ]) {
      await db
        .select({ ready: sql`1` })
        .from(table)
        .limit(1);
    }
    res.json({
      data: {
        status: "ok",
        database: "ready",
        timestamp: new Date().toISOString(),
      },
    });
  } catch {
    throw new AppError(
      503,
      "DATABASE_UNAVAILABLE",
      "Database belum siap. Periksa koneksi dan jalankan migrasi.",
    );
  }
});
