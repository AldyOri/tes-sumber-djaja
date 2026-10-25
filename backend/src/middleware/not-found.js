import { AppError } from "../shared/app-error.js";

export function notFound(_req, _res, next) {
  next(new AppError(404, "NOT_FOUND", "Endpoint tidak ditemukan."));
}
