import { z } from "zod";
import { requiredText } from "../../shared/validation.js";

export const itemBody = z
  .object({
    sku: requiredText("SKU", 50)
      .toUpperCase()
      .pipe(z.string().max(50, "SKU maksimal 50 karakter.")),
    name: requiredText("Nama barang", 150),
    unit: requiredText("Satuan", 20),
  })
  .strict();
