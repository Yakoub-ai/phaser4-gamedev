---
description: Start the Phaser dev server
---

Start the Phaser 4 development server with hot reload.

## Process

1. **Check for package.json** — If no `package.json` is found in the current directory, tell the user this is not a Node.js project and suggest running `/phaser-new` first.

2. **Check for node_modules** — If `node_modules/` does not exist, run `npm install` first.

3. **Check for phaser dependency** — Look in `package.json` for `"phaser"`. If missing, warn the user and suggest: `npm install phaser@beta`.

4. **Start the dev server:**
   ```bash
   npm run dev
   ```

5. **After starting**, tell the user:
   - The game is running at `http://localhost:5173` (default Vite port)
   - Open the browser and check the console for errors
   - Hot reload is active — changes to source files reload the game automatically
   - To stop the server: `Ctrl+C`

## Troubleshooting

If the server fails to start:
- **"Command not found: vite"** → run `npm install` first
- **"Port already in use"** → another server is running; stop it or Vite will auto-select the next port
- **Black screen in browser** → check browser DevTools console for errors; use the phaser-debugger agent
