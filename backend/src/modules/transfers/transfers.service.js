import { randomUUID } from "node:crypto";
import { db } from "../../db/client.js";
import { AppError } from "../../shared/app-error.js";
import { MAX_INTEGER } from "../../shared/validation.js";
import { paginated } from "../../shared/pagination.js";
import { find as findWarehouse } from "../warehouses/warehouses.repository.js";
import * as repository from "./transfers.repository.js";

export async function listTransfers(query) {
  for (const field of ["sourceWarehouseId", "destinationWarehouseId"]) {
    if (query[field] && !(await findWarehouse(query[field]))) {
      throw new AppError(
        422,
        "INVALID_WAREHOUSE",
        "Filter gudang tidak valid.",
        { [field]: "Gudang tidak ditemukan." },
      );
    }
  }
  const { data, total } = await repository.list(query);
  return paginated(data, total, query);
}

export async function getTransfer(id) {
  const transfer = await repository.detail(id);
  if (!transfer)
    throw new AppError(404, "TRANSFER_NOT_FOUND", "Mutasi tidak ditemukan.");
  return transfer;
}

export async function createTransfer(input) {
  return db.transaction(
    async (tx) => {
      const warehouseIds = [
        input.sourceWarehouseId,
        input.destinationWarehouseId,
      ].sort((a, b) => a - b);
      const sortedLines = [...input.items].sort((a, b) => a.itemId - b.itemId);

      // Shared master locks allow transfers to run concurrently but keep master
      // updates (especially item unit changes) out until this transaction ends.
      for (const warehouseId of warehouseIds) {
        if (!(await repository.lockWarehouse(warehouseId, tx))) {
          const field =
            warehouseId === input.sourceWarehouseId
              ? "sourceWarehouseId"
              : "destinationWarehouseId";
          throw new AppError(
            422,
            "INVALID_WAREHOUSE",
            "Gudang tidak ditemukan.",
            { [field]: "Pilih gudang yang tersedia." },
          );
        }
      }
      const itemById = new Map();
      for (const line of sortedLines) {
        const item = await repository.lockItem(line.itemId, tx);
        if (!item) {
          const index = input.items.findIndex(
            (entry) => entry.itemId === line.itemId,
          );
          throw new AppError(422, "INVALID_ITEM", "Barang tidak ditemukan.", {
            [`items.${index}.itemId`]: "Pilih barang yang tersedia.",
          });
        }
        itemById.set(item.id, item);
      }

      // Always lock in ascending (warehouse_id, item_id) order, including zero
      // rows. Opposite-direction transfers therefore acquire the same locks.
      const balances = new Map();
      for (const warehouseId of warehouseIds) {
        for (const line of sortedLines) {
          const balance = await repository.lockBalance(
            warehouseId,
            line.itemId,
            tx,
          );
          balances.set(`${warehouseId}:${line.itemId}`, balance.quantity);
        }
      }

      const changes = [];
      input.items.forEach((line, index) => {
        const sourceBefore = balances.get(
          `${input.sourceWarehouseId}:${line.itemId}`,
        );
        const destinationBefore = balances.get(
          `${input.destinationWarehouseId}:${line.itemId}`,
        );
        const field = `items.${index}.quantity`;
        if (sourceBefore < line.quantity) {
          throw new AppError(
            409,
            "INSUFFICIENT_STOCK",
            `Stok ${itemById.get(line.itemId).sku} tidak mencukupi.`,
            { [field]: `Stok tersedia ${sourceBefore}.` },
          );
        }
        if (destinationBefore > MAX_INTEGER - line.quantity) {
          throw new AppError(
            422,
            "DESTINATION_OVERFLOW",
            "Stok gudang tujuan akan melebihi batas maksimum.",
            { [field]: `Stok tujuan maksimal ${MAX_INTEGER}.` },
          );
        }
        changes.push({
          warehouseId: input.sourceWarehouseId,
          itemId: line.itemId,
          quantity: sourceBefore - line.quantity,
        });
        changes.push({
          warehouseId: input.destinationWarehouseId,
          itemId: line.itemId,
          quantity: destinationBefore + line.quantity,
        });
      });

      changes.sort(
        (a, b) => a.warehouseId - b.warehouseId || a.itemId - b.itemId,
      );
      for (const change of changes) {
        await repository.updateBalance(
          change.warehouseId,
          change.itemId,
          change.quantity,
          tx,
        );
      }

      const createdAt = new Date();
      const reference = `MTS-${createdAt.toISOString().slice(0, 10).replaceAll("-", "")}-${randomUUID()}`;
      const transferId = await repository.createHeader(
        {
          reference,
          sourceWarehouseId: input.sourceWarehouseId,
          destinationWarehouseId: input.destinationWarehouseId,
          notes: input.notes,
          createdAt,
        },
        tx,
      );
      await repository.createLines(transferId, input.items, tx);
      return repository.detail(transferId, tx);
    },
    { isolationLevel: "read committed", accessMode: "read write" },
  );
}
