import { z } from "zod";
import { positiveQueryInteger } from "./validation.js";

export const paginationShape = {
  page: positiveQueryInteger.default(1),
  limit: positiveQueryInteger
    .pipe(z.number().max(100, "Limit maksimal 100."))
    .default(20),
};

export const listQuery = z
  .object({
    ...paginationShape,
    search: z
      .string()
      .trim()
      .max(150, "Pencarian maksimal 150 karakter.")
      .default(""),
  })
  .strict();

export function offset({ page, limit }) {
  return (page - 1) * limit;
}

export function paginated(data, total, { page, limit }) {
  return { data, meta: { page, limit, total } };
}
