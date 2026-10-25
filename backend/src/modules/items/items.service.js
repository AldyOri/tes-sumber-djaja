import { db } from "../../db/client.js";
import { AppError, isDuplicate } from "../../shared/app-error.js";
import { paginated } from "../../shared/pagination.js";
import * as repository from "./items.repository.js";

function duplicate(error) {
  if (isDuplicate(error))
    throw new AppError(409, "DUPLICATE_SKU", "SKU sudah digunakan.", {
      sku: "Gunakan SKU yang berbeda.",
    });
  throw error;
}

export async function listItems(query) {
  const { data, total } = await repository.list(query);
  return paginated(data, total, query);
}

export async function createItem(input) {
  try {
    return await repository.create(input);
  } catch (error) {
    duplicate(error);
  }
}

export async function updateItem(id, input) {
  try {
    return await db.transaction(
      async (tx) => {
        // Transfers acquire a shared lock on this same row before touching stock.
        const item = await repository.find(id, tx, true);
        if (!item)
          throw new AppError(404, "ITEM_NOT_FOUND", "Barang tidak ditemukan.");
        if (
          item.unit !== input.unit &&
          (await repository.hasStockOrHistory(id, tx))
        ) {
          throw new AppError(
            409,
            "ITEM_UNIT_LOCKED",
            "Satuan tidak dapat diubah setelah barang memiliki stok atau riwayat mutasi.",
            { unit: "Satuan barang sudah digunakan." },
          );
        }
        return repository.update(id, input, tx);
      },
      { isolationLevel: "read committed" },
    );
  } catch (error) {
    duplicate(error);
  }
}
