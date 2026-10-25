import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { parse } from "yaml";

function checkDirectory(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) checkDirectory(path);
    else if (entry.name.endsWith(".js")) {
      const result = spawnSync(process.execPath, ["--check", path], {
        stdio: "inherit",
      });
      if (result.status !== 0) process.exit(result.status ?? 1);
    }
  }
}

checkDirectory("src");
checkDirectory("scripts");

const config = spawnSync(process.execPath, ["--check", "drizzle.config.js"], {
  stdio: "inherit",
});
if (config.status !== 0) process.exit(config.status ?? 1);

parse(readFileSync("docs/openapi.yaml", "utf8"));
parse(readFileSync("compose.yaml", "utf8"));
console.info("JavaScript syntax and YAML parsing checks passed.");
