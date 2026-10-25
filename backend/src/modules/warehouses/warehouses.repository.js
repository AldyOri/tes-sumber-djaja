import { asc, count, eq, sql } from "drizzle-orm";
import { db } from "../../db/client.js";
import { warehouses } from "../../db/schema.js";
import { offset } from "../../shared/pagination.js";
import { searchPattern } from "../../shared/validation.js";

export async function list(query, executor = db) {
  const pattern = searchPattern(query.search);
  const where = query.search
    ? sql`(${warehouses.code} like ${pattern} escape '!' or ${warehouses.name} like ${pattern} escape '!')`
    : undefined;
  const data = await executor
    .select()
    .from(warehouses)
    .where(where)
    .orderBy(asc(warehouses.code), asc(warehouses.id))
    .limit(query.limit)
    .offset(offset(query));
  const [{ total }] = await executor
    .select({ total: count() })
    .from(warehouses)
    .where(where);
  return { data, total };
}

export async function find(id, executor = db, lock = false) {
  const query = executor
    .select()
    .from(warehouses)
    .where(eq(warehouses.id, id))
    .limit(1);
  const [warehouse] = await (lock ? query.for("update") : query);
  return warehouse;
}

export async function create(input) {
  const [{ id }] = await db.insert(warehouses).values(input).$returningId();
  return find(id);
}

export async function update(id, input, executor) {
  await executor.update(warehouses).set(input).where(eq(warehouses.id, id));
  return find(id, executor);
}
