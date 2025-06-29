#!/usr/bin/env bun

import { $ } from "bun";

console.log("Building @panhandler/types...");

// Clean dist directory
await $`rm -rf dist`;

// Build with TypeScript
await $`tsc -p .`;

console.log("✅ @panhandler/types build complete"); 