export class AppError extends Error {
  constructor(status, code, message, fields) {
    super(message);
    this.name = "AppError";
    this.status = status;
    this.code = code;
    this.fields = fields;
  }
}

// Drizzle wraps driver errors in `cause`; never send that internal error to clients.
export function databaseError(error) {
  let current = error;
  for (let depth = 0; current && depth < 8; depth += 1) {
    if (current.errno || (current.code && !(current instanceof AppError)))
      return current;
    current = current.cause;
  }
  return undefined;
}

export function isDuplicate(error) {
  return databaseError(error)?.code === "ER_DUP_ENTRY";
}
