import { AppError, databaseError } from "../shared/app-error.js";

const contentionCodes = new Set(["ER_LOCK_DEADLOCK", "ER_LOCK_WAIT_TIMEOUT"]);
const unavailableCodes = new Set([
  "ECONNREFUSED",
  "ECONNRESET",
  "ETIMEDOUT",
  "EHOSTUNREACH",
  "PROTOCOL_CONNECTION_LOST",
  "ER_CON_COUNT_ERROR",
  "ER_SERVER_SHUTDOWN",
  "ER_ACCESS_DENIED_ERROR",
  "ER_BAD_DB_ERROR",
]);

export function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);

  let response = error;
  const driver = databaseError(error);
  if (!(error instanceof AppError)) {
    if (error.type === "entity.parse.failed") {
      response = new AppError(400, "INVALID_JSON", "Format JSON tidak valid.");
    } else if (error instanceof URIError && error.status === 400) {
      response = new AppError(
        400,
        "INVALID_PATH",
        "Format path URL tidak valid.",
      );
    } else if (error.type === "entity.too.large") {
      response = new AppError(
        413,
        "PAYLOAD_TOO_LARGE",
        "Ukuran permintaan terlalu besar.",
      );
    } else if (error.status === 415) {
      response = new AppError(
        415,
        "UNSUPPORTED_MEDIA_TYPE",
        "Gunakan JSON dengan encoding UTF-8.",
      );
    } else if (contentionCodes.has(driver?.code)) {
      response = new AppError(
        503,
        "DATABASE_BUSY",
        "Database sedang sibuk. Transaksi dibatalkan; silakan coba kembali.",
      );
    } else if (
      unavailableCodes.has(driver?.code) ||
      error.message === "Queue limit reached."
    ) {
      response = new AppError(
        503,
        "DATABASE_UNAVAILABLE",
        "Database tidak tersedia. Periksa riwayat dan stok sebelum mengirim ulang mutasi.",
      );
    } else {
      response = new AppError(
        500,
        "INTERNAL_ERROR",
        "Terjadi kesalahan pada server. Periksa riwayat dan stok sebelum mengirim ulang mutasi.",
      );
    }
  }

  if (response.status >= 500) {
    // Log metadata, not SQL, parameters, request bodies, or connection credentials.
    console.error(
      JSON.stringify({
        requestId: req.id,
        method: req.method,
        path: req.path,
        code: response.code,
        databaseCode: driver?.code,
        errorType: error.name,
      }),
    );
  }

  res.status(response.status).json({
    error: {
      code: response.code,
      message: response.message,
      ...(response.fields ? { fields: response.fields } : {}),
    },
  });
}
