import { existsSync } from 'node:fs';
import { defineConfig, type Plugin, type ViteDevServer } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { isAssetRequest, legacyRedirect, notFoundHtml } from './src/route-policy';

function routePolicy(): Plugin {
  const install = (server: ViteDevServer) => {
    server.middlewares.use((request, response, next) => {
      const pathname = new URL(request.url ?? '/', 'http://localhost').pathname;
      const redirect = legacyRedirect(pathname);
      if (redirect) {
        response.statusCode = 301;
        response.setHeader('Location', redirect);
        response.end();
        return;
      }

      if (isAssetRequest(pathname)) {
        const relativePath = `.${decodeURIComponent(pathname)}`;
        const assetPaths = [
          path.resolve(server.config.root, relativePath),
          path.resolve(server.config.publicDir, relativePath),
        ];
        assetPaths.push(path.resolve(server.config.root, server.config.build.outDir, relativePath));
        if (assetPaths.some((assetPath) => existsSync(assetPath))) {
          next();
          return;
        }

        response.statusCode = 404;
        response.setHeader('Content-Type', 'text/html; charset=utf-8');
        response.setHeader('Cache-Control', 'no-store');
        response.end(notFoundHtml);
        return;
      }

      next();
    });
  };

  return {
    name: 'secretmsg-route-policy',
    configureServer: install,
    configurePreviewServer: install,
  };
}

export default defineConfig({
  plugins: [routePolicy(), react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    host: true,
  },
});
