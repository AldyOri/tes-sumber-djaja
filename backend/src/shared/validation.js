import { z } from "zod";

export const MAX_INTEGER = 2147483647;
export const id = z
  .number({ error: "ID harus berupa angka bulat positif." })
  .int({ error: "ID harus berupa angka bulat." })
  .min(1)
  .max(MAX_INTEGER);
export const positiveQueryInteger = z
  .string()
  .regex(/^[1-9]\d*$/, "Gunakan angka bulat positif.")
  .transform(Number)
  .pipe(id);
export const idParams = z.object({ id: positiveQueryInteger }).strict();

export const requiredText = (label, maximum) =>
  z
    .string({ error: `${label} wajib berupa teks.` })
    .trim()
    .min(1, `${label} wajib diisi.`)
    .max(maximum, `${label} maksimal ${maximum} karakter.`);
export const optionalText = (label, maximum) =>
  z
    .string({ error: `${label} harus berupa teks.` })
    .trim()
    .max(maximum, `${label} maksimal ${maximum} karakter.`)
    .nullable()
    .optional()
    .transform((value) => value || null);

// Escape LIKE wildcards so search is a literal substring, using an explicit escape character.
export function searchPattern(search) {
  return `%${search.replace(/[!%_]/g, "!$&")}%`;
}
