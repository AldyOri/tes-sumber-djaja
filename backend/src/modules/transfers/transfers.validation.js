import { z } from "zod";
import {
  id,
  MAX_INTEGER,
  optionalText,
  positiveQueryInteger,
} from "../../shared/validation.js";
import { paginationShape } from "../../shared/pagination.js";

export const transferBody = z
  .object({
    sourceWarehouseId: id,
    destinationWarehouseId: id,
    notes: optionalText("Catatan", 500),
    items: z
      .array(
        z
          .object({
            itemId: id,
            quantity: z
              .number({ error: "Jumlah harus berupa angka JSON." })
              .int({ error: "Jumlah harus berupa angka bulat." })
              .min(1, "Jumlah harus lebih dari nol.")
              .max(MAX_INTEGER, `Jumlah maksimal ${MAX_INTEGER}.`),
          })
          .strict(),
        { error: "Daftar barang wajib diisi." },
      )
      .min(1, "Tambahkan minimal satu barang.")
      .max(50, "Maksimal 50 barang per mutasi."),
  })
  .strict()
  .superRefine((input, context) => {
    if (input.sourceWarehouseId === input.destinationWarehouseId) {
      context.addIssue({
        code: "custom",
        path: ["destinationWarehouseId"],
        message: "Gudang tujuan harus berbeda dari gudang asal.",
      });
    }
    const seen = new Set();
    input.items.forEach((line, index) => {
      if (seen.has(line.itemId))
        context.addIssue({
          code: "custom",
          path: ["items", index, "itemId"],
          message: "Barang yang sama tidak boleh ditambahkan dua kali.",
        });
      seen.add(line.itemId);
    });
  });

export const transferQuery = z
  .object({
    ...paginationShape,
    sourceWarehouseId: positiveQueryInteger.optional(),
    destinationWarehouseId: positiveQueryInteger.optional(),
  })
  .strict();
