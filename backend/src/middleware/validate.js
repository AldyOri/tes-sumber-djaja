import { AppError } from "../shared/app-error.js";

export function validate(schemas) {
  return (req, _res, next) => {
    req.validated = {};
    for (const [source, schema] of Object.entries(schemas)) {
      const result = schema.safeParse(req[source]);
      if (!result.success) {
        const fields = {};
        for (const issue of result.error.issues) {
          const path = issue.path.join(".") || source;
          fields[path] ??=
            issue.code === "unrecognized_keys"
              ? "Terdapat field yang tidak didukung."
              : issue.message;
        }
        return next(
          new AppError(
            source === "body" ? 422 : 400,
            "VALIDATION_ERROR",
            "Data yang dikirim tidak valid.",
            fields,
          ),
        );
      }
      req.validated[source] = result.data;
    }
    next();
  };
}
