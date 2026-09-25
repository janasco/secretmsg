#!/bin/bash
# Redeploy secretmsg.net / www.secretmsg.net via the secretmsg-frontend static-assets Worker.
# Usage: bash /opt/secretmsg/deploy-frontend.sh
#
# This file is the version-controlled source. The runtime copy lives at
# /opt/secretmsg/deploy-frontend.sh; keep the two in sync. The generated
# wrangler.toml MUST keep the ASSETS binding, not_found_handling = "none"
# and run_worker_first = false: apps/web/src/worker.ts depends on that
# contract to return real 404s for missing assets while still serving the
# prerendered route files and the SPA shell.
set -e
set -o pipefail
export PATH="/home/janasco/.local/bin:$PATH"
rm -rf /tmp/fe-dist
cp -r /opt/secretmsg/secretmsg/apps/web/dist /tmp/fe-dist
TMPF=/tmp/fe-dist/_redirects.tmp
# Drop the SPA fallback line; the Worker assets config handles SPA via not_found_handling.
grep -v '^/\*    /index.html' /tmp/fe-dist/_redirects > "$TMPF" && mv "$TMPF" /tmp/fe-dist/_redirects
mkdir -p /tmp/fe-assets
cat > /tmp/fe-assets/wrangler.toml <<'EOF'
name = "secretmsg-frontend"
compatibility_date = "2026-09-03"
compatibility_flags = ["nodejs_compat", "assets_navigation_has_no_effect"]
main = "/opt/secretmsg/secretmsg/apps/web/src/worker.ts"
usage_model = "standard"
workers_dev = false

[assets]
directory = "/tmp/fe-dist"
binding = "ASSETS"
not_found_handling = "none"
run_worker_first = false
EOF
cd /tmp/fe-assets
set -a; source /opt/secretmsg/secretmsg-private/.env.production; set +a
WRANGLER="node /opt/secretmsg/node_modules/wrangler/bin/wrangler.js"
$WRANGLER deploy --config wrangler.toml 2>&1 | tail -8
echo "FRONTEND_DEPLOY_OK"