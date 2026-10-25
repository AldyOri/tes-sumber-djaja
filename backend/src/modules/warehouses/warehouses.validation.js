import { z } from "zod";
import { optionalText, requiredText } from "../../shared/validation.js";

export const warehouseBody = z
  .object({
    code: requiredText("Kode gudang", 50)
      .toUpperCase()
      .pipe(z.string().max(50, "Kode gudang maksimal 50 karakter.")),
    name: requiredText("Nama gudang", 150),
    address: optionalText("Alamat", 255),
  })
  .strict();
