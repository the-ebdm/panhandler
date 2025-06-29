#!/usr/bin/env bun

import { $ } from "bun";

console.log("Building @panhandler/core...");

// Clean dist directory
await $`rm -rf dist`;

// Build with TypeScript
await $`tsc -p .`;

console.log("✅ @panhandler/core build complete"); 