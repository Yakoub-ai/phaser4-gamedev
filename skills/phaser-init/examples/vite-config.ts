// vite.config.ts — Vite configuration for Phaser 4
import { defineConfig } from 'vite';

export default defineConfig({
  // IMPORTANT: Set to './' for itch.io and subdirectory hosting.
  // Change to '/repo-name/' for GitHub Pages.
  base: './',

  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    minify: 'terser',
    // Split Phaser into its own chunk — browsers cache it separately
    // (saves users from re-downloading Phaser when only game code changes)
    rollupOptions: {
      output: {
        manualChunks: {
          phaser: ['phaser'],
        },
      },
    },
    // Inline assets < 4kb (reduces HTTP requests for tiny assets)
    assetsInlineLimit: 4096,
  },

  server: {
    port: 5173,
    open: true,    // auto-open browser on dev start
    // host: '0.0.0.0',  // uncomment to access from phone on same network
  },

  // Vite serves public/ directory as-is (no hashing, no bundling)
  // Assets loaded by Phaser (this.load.image etc.) must be in public/
  publicDir: 'public',
});
