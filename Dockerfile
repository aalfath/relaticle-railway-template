# Relaticle CRM for Railway: the official image, pinned by version and digest.
# Upstream: https://github.com/relaticle/relaticle (AGPL-3.0)
FROM ghcr.io/relaticle/relaticle:3.12.0@sha256:7085d9c0b83b0814a457654a10d660a87d1b5638214ecff4beb5d0df646b0a08

# Run the container as root so the first-boot script can take ownership of the
# Railway volume (it mounts root-owned). PHP-FPM children, the queue workers,
# the scheduler and Reverb all drop to www-data.
USER root

# Reverb runs inside this container on 127.0.0.1:8081 (upstream proxies to a
# separate "reverb" container through Docker's DNS, which Railway doesn't have).
COPY railway/reverb.conf /etc/nginx/server-opts.d/reverb.conf
# PHP-FPM pool limits that actually apply (see the file).
COPY railway/zzzz-railway-pool.conf /usr/local/etc/php-fpm.d/zzzz-railway-pool.conf
# First-boot work: volume, Passport keys, wait for Postgres/Redis, migrations,
# caches and the admin account. A failure exits non-zero so Railway restarts it.
COPY railway/60-railway-init.sh /etc/entrypoint.d/60-railway-init.sh
# Queue workers, scheduler and Reverb as s6 services next to nginx + PHP-FPM,
# so they share the one storage volume (imports, exports and uploads).
COPY railway/s6/ /etc/s6-overlay/s6-rc.d/
COPY railway/check-services.php railway/ensure-admin.php /usr/local/share/railway/
COPY railway/railway-entrypoint.sh /usr/local/bin/railway-entrypoint

RUN chmod 755 /etc/entrypoint.d/60-railway-init.sh /usr/local/bin/railway-entrypoint \
 && chmod 644 /usr/local/share/railway/*.php /usr/local/etc/php-fpm.d/zzzz-railway-pool.conf \
 && for s in relaticle-queue relaticle-scheduler relaticle-reverb; do \
      chmod 755 /etc/s6-overlay/s6-rc.d/$s/run; \
      touch /etc/s6-overlay/user-bundles.d/user/contents.d/$s; \
    done \
 # nginx "worker_processes auto" starts one worker per host CPU (dozens on Railway).
 && sed -i 's/^worker_processes .*/worker_processes 2;/' /etc/nginx/nginx.conf.template \
 && grep -q '^worker_processes 2;' /etc/nginx/nginx.conf.template

# Defaults sized for a small Railway plan (0.5 GB per service). CLI opcache is
# off because every long-running artisan process would map its own segment
# (4 processes x 128 MB of shared memory got the container OOM-killed). Override any of
# them with a service variable.
ENV AUTORUN_ENABLED=false \
    NGINX_HTTP_PORT=8080 \
    PHP_FPM_PM_MAX_CHILDREN=3 \
    PHP_OPCACHE_MEMORY_CONSUMPTION=64 \
    PHP_OPCACHE_ENABLE_CLI=0 \
    APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    LOG_LEVEL=warning \
    DB_CONNECTION=pgsql \
    CACHE_STORE=redis \
    SESSION_DRIVER=redis \
    QUEUE_CONNECTION=redis \
    BROADCAST_CONNECTION=reverb \
    BROADCAST_REVERB_HOST=127.0.0.1 \
    BROADCAST_REVERB_PORT=8081 \
    BROADCAST_REVERB_SCHEME=http \
    TRUSTED_PROXIES=* \
    TRUSTED_HOSTS=healthcheck.railway.app,localhost,127.0.0.1 \
    MAIL_MAILER=log \
    RELATICLE_FEATURE_SOCIAL_AUTH=false

EXPOSE 8080
# The wrapper maps PORT to nginx, then hands over to the image's entrypoint
# (runs /etc/entrypoint.d/*, then /init starts s6-overlay).
ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]
CMD ["/init"]
