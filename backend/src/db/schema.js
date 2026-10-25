import { sql } from "drizzle-orm";
import {
  check,
  datetime,
  index,
  int,
  mysqlTable,
  primaryKey,
  uniqueIndex,
  varchar,
} from "drizzle-orm/mysql-core";

const createdAt = () =>
  datetime("created_at", { mode: "date", fsp: 3 })
    .notNull()
    .default(sql`(UTC_TIMESTAMP(3))`);
const updatedAt = () =>
  datetime("updated_at", { mode: "date", fsp: 3 })
    .notNull()
    .default(sql`(UTC_TIMESTAMP(3))`)
    .$onUpdate(() => new Date());

export const items = mysqlTable(
  "items",
  {
    id: int("id").autoincrement().primaryKey(),
    sku: varchar("sku", { length: 50 }).notNull(),
    name: varchar("name", { length: 150 }).notNull(),
    unit: varchar("unit", { length: 20 }).notNull(),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (table) => [uniqueIndex("items_sku_unique").on(table.sku)],
);

export const warehouses = mysqlTable(
  "warehouses",
  {
    id: int("id").autoincrement().primaryKey(),
    code: varchar("code", { length: 50 }).notNull(),
    name: varchar("name", { length: 150 }).notNull(),
    address: varchar("address", { length: 255 }),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (table) => [uniqueIndex("warehouses_code_unique").on(table.code)],
);

export const warehouseStocks = mysqlTable(
  "warehouse_stocks",
  {
    warehouseId: int("warehouse_id")
      .notNull()
      .references(() => warehouses.id, {
        onDelete: "restrict",
        onUpdate: "restrict",
      }),
    itemId: int("item_id")
      .notNull()
      .references(() => items.id, {
        onDelete: "restrict",
        onUpdate: "restrict",
      }),
    quantity: int("quantity").notNull().default(0),
    updatedAt: updatedAt(),
  },
  (table) => [
    primaryKey({ columns: [table.warehouseId, table.itemId] }),
    index("warehouse_stocks_item_idx").on(table.itemId),
    check(
      "warehouse_stocks_quantity_check",
      sql`${table.quantity} between 0 and 2147483647`,
    ),
  ],
);

export const stockTransfers = mysqlTable(
  "stock_transfers",
  {
    id: int("id").autoincrement().primaryKey(),
    reference: varchar("reference", { length: 64 }).notNull(),
    sourceWarehouseId: int("source_warehouse_id")
      .notNull()
      .references(() => warehouses.id, {
        onDelete: "restrict",
        onUpdate: "restrict",
      }),
    destinationWarehouseId: int("destination_warehouse_id")
      .notNull()
      .references(() => warehouses.id, {
        onDelete: "restrict",
        onUpdate: "restrict",
      }),
    notes: varchar("notes", { length: 500 }),
    createdAt: createdAt(),
  },
  (table) => [
    uniqueIndex("stock_transfers_reference_unique").on(table.reference),
    index("stock_transfers_created_idx").on(table.createdAt, table.id),
    index("stock_transfers_source_idx").on(
      table.sourceWarehouseId,
      table.createdAt,
      table.id,
    ),
    index("stock_transfers_destination_idx").on(
      table.destinationWarehouseId,
      table.createdAt,
      table.id,
    ),
    check(
      "stock_transfers_different_warehouses_check",
      sql`${table.sourceWarehouseId} <> ${table.destinationWarehouseId}`,
    ),
  ],
);

export const stockTransferItems = mysqlTable(
  "stock_transfer_items",
  {
    id: int("id").autoincrement().primaryKey(),
    transferId: int("transfer_id")
      .notNull()
      .references(() => stockTransfers.id, {
        onDelete: "restrict",
        onUpdate: "restrict",
      }),
    itemId: int("item_id")
      .notNull()
      .references(() => items.id, {
        onDelete: "restrict",
        onUpdate: "restrict",
      }),
    quantity: int("quantity").notNull(),
  },
  (table) => [
    uniqueIndex("stock_transfer_items_transfer_item_unique").on(
      table.transferId,
      table.itemId,
    ),
    index("stock_transfer_items_item_idx").on(table.itemId),
    check(
      "stock_transfer_items_quantity_check",
      sql`${table.quantity} between 1 and 2147483647`,
    ),
  ],
);
