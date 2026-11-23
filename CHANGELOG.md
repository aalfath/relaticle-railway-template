# Changelog

## 3.12.0 (2026-11-23)

- First release of the template: Relaticle 3.12.0 (`ghcr.io/relaticle/relaticle:3.12.0@sha256:7085d9c0b83b0814a457654a10d660a87d1b5638214ecff4beb5d0df646b0a08`), Railway Postgres and Redis.
- First boot runs migrations under a lock, creates the admin from `ADMIN_EMAIL`/`ADMIN_PASSWORD` and generates the Passport keys on the volume.
- Queue worker, scheduler and Reverb run inside the app service, sized for a 0.5 GB plan (3 on-demand PHP-FPM children; the image's stock `www.conf` is overridden so the limit applies).
