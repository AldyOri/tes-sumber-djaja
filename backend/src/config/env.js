import "dotenv/config";
import { z } from "zod";

z.config(z.locales.id());

const integer = (fallback, maximum) =>
  z.coerce.number().int().min(1).max(maximum).default(fallback);
const schema = z.object({
  NODE_ENV: z.enum(["development", "production"]).default("development"),
  HOST: z.string().min(1).default("0.0.0.0"),
  PORT: integer(3000, 65535),
  DATABASE_URL: z
    .url()
    .refine((value) => value.startsWith("mysql://"), "Gunakan URL MySQL."),
  DB_POOL_SIZE: integer(10, 100),
  DB_LOCK_TIMEOUT_SECONDS: integer(5, 60),
  CORS_ORIGINS: z
    .string()
    .default("http://localhost:5173,http://127.0.0.1:5173"),
});

const result = schema.safeParse(process.env);
if (!result.success) {
  const fields = result.error.issues
    .map((issue) => issue.path.join("."))
    .join(", ");
  throw new Error(
    `Konfigurasi environment tidak valid: ${fields}. Periksa .env.example.`,
  );
}

export const env = {
  ...result.data,
  corsOrigins: result.data.CORS_ORIGINS.split(",")
    .map((value) => value.trim())
    .filter(Boolean),
};

if (env.corsOrigins.includes("*")) {
  throw new Error("CORS_ORIGINS harus berisi origin tertentu, bukan wildcard.");
}
