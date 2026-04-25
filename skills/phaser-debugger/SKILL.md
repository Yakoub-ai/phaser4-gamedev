---
name: phaser-debugger
description: This skill should be used when the user reports a Phaser 4 bug, black screen, missing sprite, failed collision, broken physics, animation issue, crash, console error, performance problem, slow game, save/load issue, mobile runtime issue, or unexpected gameplay behavior.
version: 0.4.0
---

# Phaser 4 Debugger

Use this skill to diagnose and fix Phaser 4 issues from evidence rather than guessing.

## Workflow

1. Collect the exact symptom, error text, stack trace, browser/device context, and reproduction steps when available.
2. Read the relevant code before editing. For black screens, inspect `src/main.ts`, scene registration, scene transitions, preload paths, and browser console/network errors.
3. Trace likely root causes using Phaser lifecycle order: config, preload, create, update, asset keys, physics body creation, collisions, input, scene start/stop state, and rendering depth.
4. Make the smallest fix that addresses the root cause.
5. Verify with `npx tsc --noEmit` for TypeScript projects and, when practical, a local dev-server smoke test.

## Debugging Checklist

- Asset 404s and mismatched texture keys
- Scene not registered or wrong scene key
- `this.physics`, `this.input`, or `this.anims` used before scene initialization
- Arcade body missing because object was created without physics
- Collider/overlap registered with the wrong object or group
- Animation key/frame mismatch
- Depth/alpha/camera bounds hiding an object
- Phaser 3 API usage after upgrading to Phaser 4
- Per-frame allocations, unbounded groups, and missing object pooling

## Full Guidance

For the complete diagnostic playbook, read `references/agent-guidance.md`. It is copied from the Claude subagent definition but should be applied as a portable skill; ignore Claude-only fields such as `model`, `color`, and `tools`.
