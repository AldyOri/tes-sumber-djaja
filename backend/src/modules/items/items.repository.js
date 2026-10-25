import { asc, count, eq, sql } from "drizzle-orm";
import { db } from "../../db/client.js";
import { items, stockTransferItems, warehouseStocks } from "../../db/schema.js";
import { offset } from "../../shared/pagination.js";
import { searchPattern } from "../../shared/validation.js";

export async function list(query, executor = db) {
  const pattern = searchPattern(query.search);
  const where = query.search
    ? sql`(${items.sku} like ${pattern} escape '!' or ${items.name} like ${pattern} escape '!')`
    : undefined;
  const data = await executor
    .select()
    .from(items)
    .where(where)
    .orderBy(asc(items.sku), asc(items.id))
    .limit(query.limit)
    .offset(offset(query));
  const [{ total }] = await executor
    .select({ total: count() })
    .from(items)
    .where(where);
  return { data, total };
}

export async function find(id, executor = db, lock = false) {
  const query = executor.select().from(items).where(eq(items.id, id)).limit(1);
  const [item] = await (lock ? query.for("update") : query);
  return item;
}

export async function create(input, executor = db) {
  const [{ id }] = await executor.insert(items).values(input).$returningId();
  return find(id, executor);
}

export async function update(id, input, executor) {
  await executor.update(items).set(input).where(eq(items.id, id));
  return find(id, executor);
}

export async function hasStockOrHistory(id, executor) {
  const [stock] = await executor
    .select({ itemId: warehouseStocks.itemId })
    .from(warehouseStocks)
    .where(eq(warehouseStocks.itemId, id))
    .limit(1);
  if (stock) return true;
  const [history] = await executor
    .select({ itemId: stockTransferItems.itemId })
    .from(stockTransferItems)
    .where(eq(stockTransferItems.itemId, id))
    .limit(1);
  return Boolean(history);
}
