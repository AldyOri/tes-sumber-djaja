import { and, asc, count, desc, eq, sql } from "drizzle-orm";
import { alias } from "drizzle-orm/mysql-core";
import { db } from "../../db/client.js";
import {
  items,
  stockTransferItems,
  stockTransfers,
  warehouses,
  warehouseStocks,
} from "../../db/schema.js";
import { offset } from "../../shared/pagination.js";

const source = alias(warehouses, "source");
const destination = alias(warehouses, "destination");
const headerSelection = {
  id: stockTransfers.id,
  reference: stockTransfers.reference,
  createdAt: stockTransfers.createdAt,
  notes: stockTransfers.notes,
  sourceWarehouse: { id: source.id, code: source.code, name: source.name },
  destinationWarehouse: {
    id: destination.id,
    code: destination.code,
    name: destination.name,
  },
};

function headers(executor) {
  return executor
    .select(headerSelection)
    .from(stockTransfers)
    .innerJoin(source, eq(stockTransfers.sourceWarehouseId, source.id))
    .innerJoin(
      destination,
      eq(stockTransfers.destinationWarehouseId, destination.id),
    );
}

export async function list(query) {
  const where = and(
    query.sourceWarehouseId
      ? eq(stockTransfers.sourceWarehouseId, query.sourceWarehouseId)
      : undefined,
    query.destinationWarehouseId
      ? eq(stockTransfers.destinationWarehouseId, query.destinationWarehouseId)
      : undefined,
  );
  const data = await headers(db)
    .where(where)
    .orderBy(desc(stockTransfers.createdAt), desc(stockTransfers.id))
    .limit(query.limit)
    .offset(offset(query));
  const [{ total }] = await db
    .select({ total: count() })
    .from(stockTransfers)
    .where(where);
  return { data, total };
}

export async function detail(id, executor = db) {
  const [header] = await headers(executor)
    .where(eq(stockTransfers.id, id))
    .limit(1);
  if (!header) return undefined;
  const lines = await executor
    .select({
      itemId: items.id,
      sku: items.sku,
      name: items.name,
      unit: items.unit,
      quantity: stockTransferItems.quantity,
    })
    .from(stockTransferItems)
    .innerJoin(items, eq(items.id, stockTransferItems.itemId))
    .where(eq(stockTransferItems.transferId, id))
    .orderBy(asc(stockTransferItems.id));
  return { ...header, items: lines };
}

export async function lockWarehouse(id, tx) {
  // This shared-lock syntax is supported by both MySQL and MariaDB.
  const [rows] = await tx.execute(sql`
    select ${warehouses.id} as id from ${warehouses}
    where ${warehouses.id} = ${id} lock in share mode
  `);
  return rows[0];
}

export async function lockItem(id, tx) {
  const [rows] = await tx.execute(sql`
    select ${items.id} as id, ${items.sku} as sku from ${items}
    where ${items.id} = ${id} lock in share mode
  `);
  return rows[0];
}

export async function lockBalance(warehouseId, itemId, tx) {
  // The composite primary key serializes concurrent creation. A no-op update
  // locks existing rows without overwriting quantity or its last-change time.
  await tx
    .insert(warehouseStocks)
    .values({ warehouseId, itemId, quantity: 0 })
    .onDuplicateKeyUpdate({
      set: {
        quantity: sql`${warehouseStocks.quantity}`,
        updatedAt: sql`${warehouseStocks.updatedAt}`,
      },
    });
  const [balance] = await tx
    .select()
    .from(warehouseStocks)
    .where(
      and(
        eq(warehouseStocks.warehouseId, warehouseId),
        eq(warehouseStocks.itemId, itemId),
      ),
    )
    .for("update");
  return balance;
}

export async function updateBalance(warehouseId, itemId, quantity, tx) {
  await tx
    .update(warehouseStocks)
    .set({ quantity })
    .where(
      and(
        eq(warehouseStocks.warehouseId, warehouseId),
        eq(warehouseStocks.itemId, itemId),
      ),
    );
}

export async function createHeader(input, tx) {
  const [{ id }] = await tx.insert(stockTransfers).values(input).$returningId();
  return id;
}

export async function createLines(transferId, lines, tx) {
  await tx
    .insert(stockTransferItems)
    .values(lines.map((line) => ({ ...line, transferId })));
}
