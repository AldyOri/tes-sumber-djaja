import { app } from "./app.js";
import { env } from "./config/env.js";
import { pool } from "./db/client.js";

const server = app.listen(env.PORT, env.HOST, () => {
  console.info(`API listening on http://${env.HOST}:${env.PORT}/api`);
  console.info(`Swagger UI: http://localhost:${env.PORT}/api/docs`);
});

let shuttingDown = false;
async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  console.info(`Received ${signal}; closing HTTP server and database pool.`);
  const timeout = setTimeout(() => process.exit(1), 10000);
  timeout.unref();
  server.close(async () => {
    try {
      await pool.end();
      clearTimeout(timeout);
      process.exitCode = 0;
    } catch {
      process.exitCode = 1;
    }
  });
}

server.on("error", async (error) => {
  console.error(`HTTP server failed: ${error.code ?? error.name}`);
  await pool.end();
  process.exitCode = 1;
});
process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
