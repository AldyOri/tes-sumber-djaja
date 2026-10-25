import { randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import swaggerUi from "swagger-ui-express";
import { parse } from "yaml";
import { env } from "./config/env.js";
import { AppError } from "./shared/app-error.js";
import { errorHandler } from "./middleware/error-handler.js";
import { notFound } from "./middleware/not-found.js";
import { healthRouter } from "./modules/health/health.routes.js";
import { itemsRouter } from "./modules/items/items.routes.js";
import { warehousesRouter } from "./modules/warehouses/warehouses.routes.js";
import { stocksRouter } from "./modules/stocks/stocks.routes.js";
import { transfersRouter } from "./modules/transfers/transfers.routes.js";

export const openapi = parse(
  readFileSync(new URL("../docs/openapi.yaml", import.meta.url), "utf8"),
);
export const app = express();

app.disable("x-powered-by");
app.set("query parser", "simple");
app.use((req, res, next) => {
  req.id = randomUUID();
  res.set("X-Request-Id", req.id);
  next();
});
app.use(
  helmet({
    // Swagger UI uses inline scripts and styles. Local HTTP must not redirect its assets to HTTPS.
    contentSecurityPolicy: {
      directives: {
        "script-src": ["'self'", "'unsafe-inline'"],
        "upgrade-insecure-requests": null,
      },
    },
    strictTransportSecurity: env.NODE_ENV === "production" ? undefined : false,
  }),
);
app.use(
  cors((req, done) =>
    done(null, {
      origin(origin, callback) {
        const sameOrigin = origin === `${req.protocol}://${req.get("host")}`;
        if (!origin || sameOrigin || env.corsOrigins.includes(origin))
          return callback(null, true);
        callback(
          new AppError(403, "ORIGIN_NOT_ALLOWED", "Origin tidak diizinkan."),
        );
      },
      methods: ["GET", "POST", "PUT", "OPTIONS"],
      allowedHeaders: ["Content-Type"],
      exposedHeaders: ["X-Request-Id"],
    }),
  ),
);
app.use(express.json({ limit: "64kb", strict: false }));
app.use("/api", (req, _res, next) => {
  if (["POST", "PUT"].includes(req.method) && !req.is("application/json")) {
    return next(
      new AppError(
        415,
        "UNSUPPORTED_MEDIA_TYPE",
        "Gunakan Content-Type application/json.",
      ),
    );
  }
  next();
});

app.get("/api/openapi.json", (_req, res) => res.json(openapi));
app.use(
  "/api/docs",
  swaggerUi.serve,
  swaggerUi.setup(openapi, {
    customSiteTitle: "Warehouse Stock Transfer API",
    swaggerOptions: { validatorUrl: null },
  }),
);
app.use("/api/health", healthRouter);
app.use("/api/items", itemsRouter);
app.use("/api/warehouses", warehousesRouter);
app.use("/api/warehouses", stocksRouter);
app.use("/api/transfers", transfersRouter);
app.use(notFound);
app.use(errorHandler);
