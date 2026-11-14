// @ts-check
import { defineConfig } from 'astro/config';
import { fileURLToPath } from 'node:url';

// The data lives outside the project, in ../census and ../ledgers. Vite watches only the project
// folder, so without this the dev server never sees a JSON edit there (the page stays stale until a
// restart). Adding both folders to its watcher lets the content collections reload them.
const dataDirs = ['../census', '../ledgers'].map((d) => fileURLToPath(new URL(d, import.meta.url)));
const watchData = {
  name: 'ehlnofey-watch-data',
  /** @param {import('vite').ViteDevServer} server */
  configureServer(server) {
    server.watcher.add(dataDirs);
  },
};

// Served from GitHub Pages at https://whisperdealer.github.io/ehlnofey/.
export default defineConfig({
  site: 'https://whisperdealer.github.io',
  base: '/ehlnofey',
  vite: { server: { fs: { allow: ['..'] } }, plugins: [watchData] },
});
