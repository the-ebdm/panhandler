#!/usr/bin/env bun

import { $ } from "bun";

console.log("Building @panhandler/types...");

// Clean dist directory and build info
await $`rm -rf dist tsconfig.tsbuildinfo`;

// Build with TypeScript (composite project)
await $`tsc --build`;

console.log("✅ @panhandler/types build complete"); 