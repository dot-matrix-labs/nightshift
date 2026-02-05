#!/usr/bin/env node

// Nightshift Pre-Push Hook
// Located at: scripts/hooks/pre-push.js
// This hook is copied to .git/hooks/pre-push during installation
// Customize this file to add project-specific pre-push checks

const { execSync } = require("child_process");
const fs = require("fs");

console.log("🚀 Nightshift Pre-Push Hook");
console.log("============================");

try {
    const branch = execSync("git symbolic-ref --short HEAD", { encoding: "utf8" }).trim();

    // Check if this is a Nightshift branch
    if (branch.startsWith("ns/")) {
        console.log(`   📦 Nightshift branch detected: ${branch}`);
    }

    // Check for secrets if gitleaks is available
    if (fs.existsSync(".gitleaks.toml") || fs.existsSync(".gitleaksignore")) {
        console.log("   🔒 Gitleaks config found - consider running gitleaks");
    }

    console.log("   ✅ Pre-push checks passed");
} catch (e) {
    console.error("   ❌ Pre-push check failed:", e.message);
    process.exit(1);
}
