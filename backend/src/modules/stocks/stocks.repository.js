import { and, asc, count, eq, sql } from "drizzle-orm";
import { db } from "../../db/client.js";
import { items, warehouseStocks } from "../../db/schema.js";
import { offset } from "../../shared/pagination.js";
import { searchPattern } from "../../shared/validation.js";

export async function list(warehouseId, query) {
  const pattern = searchPattern(query.search);
  const where = query.search
    ? sql`(${items.sku} like ${pattern} escape '!' or ${items.name} like ${pattern} escape '!')`
    : undefined;
  // Start from items so new items and absent balance rows are visible as zero.
  const data = await db
    .select({
      warehouseId: sql`${warehouseId}`.mapWith(Number),
      itemId: items.id,
      sku: items.sku,
      name: items.name,
      unit: items.unit,
      quantity: sql`coalesce(${warehouseStocks.quantity}, 0)`.mapWith(Number),
    })
    .from(items)
    .leftJoin(
      warehouseStocks,
      and(
        eq(warehouseStocks.itemId, items.id),
        eq(warehouseStocks.warehouseId, warehouseId),
      ),
    )
    .where(where)
    .orderBy(asc(items.sku), asc(items.id))
    .limit(query.limit)
    .offset(offset(query));
  const [{ total }] = await db
    .select({ total: count() })
    .from(items)
    .where(where);
  return { data, total };
}
