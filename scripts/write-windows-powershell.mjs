import { readFile, writeFile } from "node:fs/promises";

const [, , source, target] = process.argv;

if (!source || !target) {
  throw new Error("Usage: node write-windows-powershell.mjs <source> <target>");
}

const input = await readFile(source, "utf8");
const normalized = input.replace(/^\uFEFF/, "").replace(/\r?\n/g, "\r\n");

// Windows PowerShell 5.1 treats UTF-8 without a BOM as the active ANSI code
// page. A BOM prevents Chinese text from corrupting nearby quote characters.
await writeFile(target, `\uFEFF${normalized}`, "utf8");
