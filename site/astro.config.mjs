// @ts-check
import { defineConfig } from 'astro/config';

// Served from GitHub Pages at https://whisperdealer.github.io/ehlnofey/.
// The data lives outside the project, in ../census, so the dev server may read the parent folder.
export default defineConfig({
  site: 'https://whisperdealer.github.io',
  base: '/ehlnofey',
  vite: { server: { fs: { allow: ['..'] } } },
});
