#!/usr/bin/env node

// Nightshift Pre-Commit Hook
// Located at: scripts/hooks/pre-commit.js
// This hook is copied to .git/hooks/pre-commit during installation
// Customize this file to add project-specific pre-commit checks

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

console.log("🔍 Nightshift Pre-Commit Hook");
console.log("==============================");

try {
    // Check for untracked docs
    const docs = execSync('git ls-files --others --exclude-standard -- "*.md"', {
        encoding: "utf8",
    }).trim();
    if (docs) {
        console.log("   📄 New documentation files detected:");
        docs.split("\n").forEach((d) => console.log("      " + d));
    }

    // Run npm lint if available
    if (fs.existsSync("package.json")) {
        const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
        if (pkg.scripts?.lint) {
            console.log("   Running npm run lint...");
            execSync("npm run lint", { stdio: "inherit" });
        }
    }

    console.log("   ✅ Pre-commit checks passed");
} catch (e) {
    console.error("   ❌ Pre-commit check failed:", e.message);
    process.exit(1);
}
