---
name: phaser-asset-advisor
description: This skill should be used when the user asks about Phaser 4 asset loading, sprite sheets, texture atlases, image optimization, preloader scenes, loading bars, tile map assets, audio formats, bitmap fonts, free game assets, generated placeholder assets, asset organization, or asset pipeline performance.
version: 0.4.0
---

# Phaser 4 Asset Advisor

Use this skill to design, implement, or optimize Phaser 4 asset pipelines.

## Workflow

1. Identify the asset categories: backgrounds, sprites, animations, UI, atlases, tilemaps, audio, fonts, and generated placeholders.
2. Choose the right load method and format for each asset type.
3. Decide what belongs in BootScene versus PreloaderScene versus level-specific lazy loading.
4. Prefer atlases for many sprites, spritesheets for uniform frame grids, individual images for large single-use art, and paired audio formats where browser support requires it.
5. Keep load keys stable and document them in shared constants when the project already uses key registries.
6. Include optimization guidance for HTTP requests, GPU texture size, mobile memory, and build output.

## Common Outputs

- Asset folder layout
- `this.load.*` calls
- Preloader progress UI
- Atlas/spritesheet recommendations
- Audio loading and unlock plan
- Tilemap/Tiled workflow
- Asset budget and optimization checklist

## Full Guidance

For the complete asset pipeline playbook, read `references/agent-guidance.md`. It is copied from the Claude subagent definition but should be applied as a portable skill; ignore Claude-only fields such as `model`, `color`, and `tools`.
