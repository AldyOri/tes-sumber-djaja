import { AppError } from "../../shared/app-error.js";
import { paginated } from "../../shared/pagination.js";
import { find as findWarehouse } from "../warehouses/warehouses.repository.js";
import * as repository from "./stocks.repository.js";

export async function listStocks(warehouseId, query) {
  if (!(await findWarehouse(warehouseId)))
    throw new AppError(404, "WAREHOUSE_NOT_FOUND", "Gudang tidak ditemukan.");
  const { data, total } = await repository.list(warehouseId, query);
  return paginated(data, total, query);
}
