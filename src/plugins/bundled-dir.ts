import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function resolveBundledPluginsDir(): string | undefined {
  const override = process.env.OPENCLAW_BUNDLED_PLUGINS_DIR?.trim();
  if (override) {
    if (fs.existsSync(override)) {
      return override;
    }
    // Log warning if override path doesn't exist
    console.warn(`[plugins] OPENCLAW_BUNDLED_PLUGINS_DIR=${override} does not exist`);
    // Fall through to auto-discovery
  }

  // bun --compile: ship a sibling `extensions/` next to the executable.
  try {
    const execDir = path.dirname(process.execPath);
    const sibling = path.join(execDir, "extensions");
    if (fs.existsSync(sibling)) {
      return sibling;
    }
  } catch {
    // ignore
  }

  // npm/dev: walk up from this module to find `extensions/` at the package root.
  try {
    let cursor = path.dirname(fileURLToPath(import.meta.url));
    const moduleUrl = import.meta.url;
    for (let i = 0; i < 6; i += 1) {
      const candidate = path.join(cursor, "extensions");
      if (fs.existsSync(candidate)) {
        return candidate;
      }
      const parent = path.dirname(cursor);
      if (parent === cursor) {
        break;
      }
      cursor = parent;
    }
    // Log when auto-discovery fails
    console.warn(`[plugins] bundled extensions not found (module=${moduleUrl})`);
  } catch (err) {
    console.warn(`[plugins] bundled extensions discovery error: ${String(err)}`);
  }

  return undefined;
}
