---
description: Analyze an existing Phaser project for architecture quality, performance risks, and improvement opportunities
---

Perform a comprehensive brownfield analysis of the current Phaser 4 project.

## Process

1. **Verify this is a Phaser project** — Check that `package.json` exists and contains a `phaser` dependency. If not, tell the user this command requires a Phaser project directory.

2. **Run the automated analysis script:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/phaser-analyze/scripts/analyze-project.sh"
   ```

3. **Perform deep code review using the phaser-analyze skill** — Go beyond the automated scan. Read actual scene files, trace the scene graph, assess architecture quality, and check for subtle issues the script cannot catch (e.g., asset key mismatches, lifecycle violations, update loop weight).

4. **Produce the analysis report** with these sections:
   - **Project Summary** — file count, scene count, LOC, estimated complexity
   - **Architecture Score** — A/B/C/D/F grade with rationale
   - **Performance Risks** — ordered by severity with concrete fix suggestions
   - **Code Quality Issues** — with file:line references
   - **Improvement Roadmap** — prioritized refactoring steps
   - **Quick Wins** — 3-5 changes for immediate improvement

5. **Suggest top 3 improvements**, linking to relevant skills:
   - `/phaser-migrate` for any Phaser v3 API issues
   - `/phaser-physics` for object pooling and physics group improvements
   - phaser-debugger agent for runtime performance investigation
   - `/phaser-build` to verify the project builds cleanly after fixes

## What Gets Analyzed

- **Architecture** — Scene organization, state management, asset loading strategy, code coupling
- **Performance** — Object pooling, particle caps, static vs dynamic groups, update loop weight, texture usage
- **API Correctness** — Removed v3 APIs, TypeScript strictness, asset key consistency, scene registration
- **Best Practices** — Lifecycle discipline, shutdown cleanup, camera bounds, input null safety, debug flags, console usage

## After Analysis

- **Grade A-B**: Project is healthy. Suggest minor optimizations and move on.
- **Grade C**: Targeted refactoring needed. Identify the 3 highest-impact fixes.
- **Grade D-F**: Major restructuring recommended. Create a phased refactoring plan starting with the most critical issues. Suggest using `/phaser-migrate` if v3 APIs are found.
