#!/usr/bin/env node

/**
 * merge-json.js - Utility for merging JSON configurations from multiple presets
 *
 * Usage: node merge-json.js <base.json> <preset1.json> [preset2.json...] <output.json>
 */

const fs = require('fs');
const path = require('path');

function mergePermissions(target, source) {
    const result = { ...target };

    // Merge allow lists - deduplicate and concatenate
    if (source.allow) {
        result.allow = target.allow
            ? [...new Set([...target.allow, ...source.allow])]
            : [...source.allow];
    }

    // Merge deny lists - deduplicate and concatenate
    if (source.deny) {
        result.deny = target.deny
            ? [...new Set([...target.deny, ...source.deny])]
            : [...source.deny];
    }

    return result;
}

function mergeHooks(target, source) {
    const result = { ...target };

    for (const hookType in source) {
        if (source.hasOwnProperty(hookType)) {
            if (!result[hookType]) {
                result[hookType] = [...source[hookType]];
            } else {
                // Merge hook configurations, combining matchers and deduplicating commands
                const mergedHooks = [...result[hookType]];

                for (const sourceHook of source[hookType]) {
                    // Find existing hook with same matcher
                    const existingHookIndex = mergedHooks.findIndex(h => h.matcher === sourceHook.matcher);

                    if (existingHookIndex >= 0) {
                        // Merge hooks for the same matcher, deduplicating by command
                        const existingHook = mergedHooks[existingHookIndex];
                        const combinedHooks = [...existingHook.hooks];

                        for (const newHook of sourceHook.hooks) {
                            const isDuplicate = combinedHooks.some(h =>
                                h.type === newHook.type && h.command === newHook.command
                            );
                            if (!isDuplicate) {
                                combinedHooks.push(newHook);
                            }
                        }

                        mergedHooks[existingHookIndex] = {
                            ...existingHook,
                            hooks: combinedHooks
                        };
                    } else {
                        // Add new matcher
                        mergedHooks.push(sourceHook);
                    }
                }

                result[hookType] = mergedHooks;
            }
        }
    }

    return result;
}

function deepMerge(target, source) {
    if (!source || typeof source !== 'object') return target;
    if (!target || typeof target !== 'object') return source;

    const result = { ...target };

    for (const key in source) {
        if (source.hasOwnProperty(key)) {
            if (key === 'permissions') {
                // Special handling for Claude Code permissions
                result[key] = mergePermissions(result[key] || {}, source[key]);
            } else if (key === 'hooks') {
                // Special handling for Claude Code hooks
                result[key] = mergeHooks(result[key] || {}, source[key]);
            } else if (Array.isArray(source[key])) {
                // For other arrays, concatenate unique values
                result[key] = Array.isArray(result[key])
                    ? [...new Set([...result[key], ...source[key]])]
                    : [...source[key]];
            } else if (typeof source[key] === 'object' && source[key] !== null) {
                // For objects, recursively merge
                result[key] = deepMerge(result[key] || {}, source[key]);
            } else {
                // For primitives, source overwrites target
                result[key] = source[key];
            }
        }
    }

    return result;
}

function mergeJsonFiles(inputFiles, outputFile) {
    let merged = {};

    for (const file of inputFiles) {
        if (!fs.existsSync(file)) {
            console.warn(`Warning: File ${file} does not exist, skipping`);
            continue;
        }

        try {
            const content = fs.readFileSync(file, 'utf8');
            const data = JSON.parse(content);
            merged = deepMerge(merged, data);
            console.log(`Merged: ${file}`);
        } catch (error) {
            console.error(`Error processing ${file}: ${error.message}`);
            process.exit(1);
        }
    }

    try {
        fs.writeFileSync(outputFile, JSON.stringify(merged, null, 2));
        console.log(`Output written to: ${outputFile}`);
    } catch (error) {
        console.error(`Error writing output: ${error.message}`);
        process.exit(1);
    }
}

// CLI usage
if (require.main === module) {
    const args = process.argv.slice(2);

    if (args.length < 2) {
        console.error('Usage: node merge-json.js <input1.json> [input2.json...] <output.json>');
        process.exit(1);
    }

    const outputFile = args.pop();
    const inputFiles = args;

    mergeJsonFiles(inputFiles, outputFile);
}

module.exports = { deepMerge, mergeJsonFiles };
