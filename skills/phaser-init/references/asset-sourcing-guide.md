# Asset Sourcing Guide

Comprehensive guide to finding, licensing, creating, and converting game assets for Phaser 4 projects.

## Free Asset Marketplaces

- **Kenney.nl** — Over 40,000 CC0 assets. Organized by category. Includes 2D sprites, UI elements, audio, tilesets. Gold standard for prototyping and game jams. Many assets are production-quality.
- **OpenGameArt.org** — Community-contributed. Mixed quality. Always check individual asset license. Great for specific needs (e.g., "medieval tileset").
- **itch.io/game-assets** — Filter by Free. Many professional-quality packs. Some are "name your price" ($0 allowed). Check license per pack.
- **freesound.org** — Massive sound library. CC0 and CC-BY. Great for SFX. Use filters: "duration < 5s" for game SFX.
- **Lospec.com** — Pixel art color palettes, tutorials, and community resources. Essential for pixel art games.

## License Compatibility Matrix

| License | Commercial Use | Attribution Required | Share-Alike | Recommended |
|---------|---------------|---------------------|-------------|-------------|
| CC0 | Yes | No | No | Best choice |
| CC-BY 4.0 | Yes | Yes (credit author) | No | Good |
| CC-BY-SA 4.0 | Yes | Yes | Yes (derivatives same license) | Caution |
| CC-BY-NC 4.0 | No | Yes | No | Avoid for commercial |
| MIT | Yes | Include license text | No | Good for code |

## Tool Installation Quick Reference

- **Aseprite:** Purchase from aseprite.org ($20) or compile from source (free). Best pixel art + animation tool.
- **Tiled:** Download from mapeditor.org (free). Essential for tilemap games. Export as JSON for Phaser.
- **free-tex-packer:** Use at free-tex-packer.com (web, no install). Upload individual sprites, download atlas JSON+PNG.
- **jsfxr:** Use at sfxr.me (web, no install). Generate retro sound effects, export as WAV. Convert to mp3+ogg with ffmpeg.
- **Bosca Ceoil:** Download from boscaceoil.net (free). Simple chiptune music creation. Export as WAV.

## Audio Conversion Workflow (using ffmpeg)

```bash
# Convert WAV to mp3 (128kbps for BGM, 96kbps for SFX)
ffmpeg -i sound.wav -codec:a libmp3lame -b:a 128k sound.mp3
ffmpeg -i sound.wav -codec:a libmp3lame -b:a 96k sfx.mp3

# Convert WAV to ogg
ffmpeg -i sound.wav -codec:a libvorbis -b:a 128k sound.ogg
```

## Spritesheet Creation Workflow

1. Create individual frame PNGs in Aseprite (or any editor)
2. Export as spritesheet: Aseprite -> File -> Export Sprite Sheet -> JSON Array + PNG
3. OR use free-tex-packer to combine frames into atlas

## Asset Budgets by Complexity

| Project Scale | Sprites | Audio Files | Tileset Tiles | Total Size |
|--------------|---------|-------------|---------------|------------|
| Game jam (48h) | 10-20 | 5-10 | 0-64 | < 5MB |
| Small indie | 30-50 | 15-25 | 64-256 | < 15MB |
| Medium indie | 50-100 | 25-40 | 256-1024 | < 30MB |
| Commercial | 100-200+ | 40-60+ | 1024+ | < 50MB |
