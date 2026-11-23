#!/bin/sh
# Railway wrapper around the image's own entrypoint.
set -e
# nginx listens on Railway's PORT (the template sets PORT=8080).
export NGINX_HTTP_PORT="${PORT:-8080}"
# Laravel wants a 32-byte APP_KEY (raw or base64:...). Accept any other length
# by deriving a stable 32-byte key from it, so a hand-edited key can't 500 every page.
if [ -n "$APP_KEY" ] && [ "${APP_KEY#base64:}" = "$APP_KEY" ] && [ "${#APP_KEY}" -ne 32 ]; then
  APP_KEY="base64:$(php -r 'echo base64_encode(hash("sha256", getenv("APP_KEY"), true));')"
  export APP_KEY
fi
exec docker-php-serversideup-entrypoint "$@"
