import { db } from "../../db/client.js";
import { AppError, isDuplicate } from "../../shared/app-error.js";
import { paginated } from "../../shared/pagination.js";
import * as repository from "./warehouses.repository.js";

function duplicate(error) {
  if (isDuplicate(error))
    throw new AppError(
      409,
      "DUPLICATE_WAREHOUSE_CODE",
      "Kode gudang sudah digunakan.",
      { code: "Gunakan kode gudang yang berbeda." },
    );
  throw error;
}

export async function listWarehouses(query) {
  const { data, total } = await repository.list(query);
  return paginated(data, total, query);
}

export async function createWarehouse(input) {
  try {
    return await repository.create(input);
  } catch (error) {
    duplicate(error);
  }
}

export async function updateWarehouse(id, input) {
  try {
    return await db.transaction(
      async (tx) => {
        const warehouse = await repository.find(id, tx, true);
        if (!warehouse)
          throw new AppError(
            404,
            "WAREHOUSE_NOT_FOUND",
            "Gudang tidak ditemukan.",
          );
        return repository.update(id, input, tx);
      },
      { isolationLevel: "read committed" },
    );
  } catch (error) {
    duplicate(error);
  }
}
