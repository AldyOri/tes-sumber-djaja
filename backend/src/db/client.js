import mysql from "mysql2/promise";
import { drizzle } from "drizzle-orm/mysql2";
import { env } from "../config/env.js";
import * as schema from "./schema.js";

export const pool = mysql.createPool({
  uri: env.DATABASE_URL,
  timezone: "Z",
  charset: "utf8mb4",
  connectionLimit: env.DB_POOL_SIZE,
  waitForConnections: true,
  queueLimit: 100,
  connectTimeout: 5000,
  enableKeepAlive: true,
  multipleStatements: false,
});

// mysql2 queues these commands before handing each new connection to a query.
pool.on("connection", (connection) => {
  const initialized = (error) => {
    if (error) {
      console.error(
        JSON.stringify({
          code: "DATABASE_SESSION_INIT_FAILED",
          databaseCode: error.code,
        }),
      );
      connection.destroy();
    }
  };

  connection.query("SET SESSION time_zone = '+00:00'", initialized);
  
  connection.query(
    "SET SESSION innodb_lock_wait_timeout = ?",
    [env.DB_LOCK_TIMEOUT_SECONDS],
    initialized,
  );
});

export const db = drizzle(pool, { schema, mode: "default" });
