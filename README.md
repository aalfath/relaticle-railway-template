[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/relaticle-1?utm_medium=integration&utm_source=button&utm_campaign=relaticle)

# Relaticle on Railway

One-click [Railway](https://railway.com) template for [Relaticle](https://github.com/relaticle/relaticle) **3.12.0**, the open-source CRM with a built-in AI assistant and a REST API and MCP server your AI agents can use (AGPL-3.0). The app service builds from this repository. When we bump the version here, Railway offers everyone who deployed the template an update.

## What the template deploys

| Service | Built from | What it does |
|---|---|---|
| `Relaticle` (public, port 8080) | [`Dockerfile`](Dockerfile) | The official image `ghcr.io/relaticle/relaticle:3.12.0`, pinned by digest. nginx + PHP-FPM serve the CRM. Next to them, s6-overlay supervises one queue worker for every queue (chat, imports, mail), the Laravel scheduler, and Reverb, the websocket server that streams the assistant's replies through `/reverb` on the same domain. Uploads, imports, exports and the Passport OAuth keys live on a volume at `/var/www/html/storage/app`. Health check `/up`. |
| `Postgres` | Railway's PostgreSQL | All CRM data. |
| `Redis` | Railway's Redis | Cache, sessions, queues and locks. |

Upstream's Compose file runs Horizon, the scheduler and Reverb as separate containers that share one storage volume. Railway volumes can't be shared between services, and upstream's production Horizon profile starts 12 or more workers (about 2 GB of RAM), so this template runs them inside the app service instead. Together they use about 230 MB.

## After deploy

1. Wait until the `Relaticle` service shows **Active**. The first boot runs the database migrations and takes about a minute.
2. Open the service's public URL. Sign in with the `ADMIN_EMAIL` you entered and the generated `ADMIN_PASSWORD` (open the `Relaticle` service's **Variables** tab to see it). This account is a verified CRM user and the system administrator at `/sysadmin`.
3. On first sign-in Relaticle asks for your name and a workspace name, then runs a short setup wizard (use case, invite your team). Finish it or click **Get started** to reach the CRM.
4. Change the password under your profile if you like. The template only uses `ADMIN_PASSWORD` to create the account the first time.
5. To use Rela, the AI assistant, add `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` (or `OLLAMA_BASE_URL` + `OLLAMA_MODEL`) to the `Relaticle` service. The CRM works without one.

**Sign-up is open.** Like upstream's self-hosted build, anyone who can reach the URL can create an account and their own workspace. New accounts must verify their email address, and the template sends mail to the log until you set up SMTP, so strangers can't get in by default. Invite your team from the workspace settings.

## Variables

| Variable | Value | Notes |
|---|---|---|
| `ADMIN_EMAIL` | *you enter it* | Email address for the first admin account. The only prompt. |
| `ADMIN_PASSWORD` | `${{secret(24)}}` | Generated. Used once, on first boot. |
| `APP_KEY` | `${{secret(32)}}` | Laravel encryption key. Don't change it after deploy. |
| `APP_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Change it if you add a custom domain. |
| `DB_*`, `REDIS_*` | References to `Postgres` and `Redis` | Private network. |
| `PORT` | `8080` | nginx listens here. |

Optional settings, added on the `Relaticle` service when you need them:

- **Email:** `MAIL_MAILER=smtp`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_ENCRYPTION`, `MAIL_FROM_ADDRESS`, `MAIL_FROM_NAME`.
- **AI assistant:** `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `OLLAMA_BASE_URL`/`OLLAMA_MODEL`, or `SELF_HOSTED_AI_URL`/`SELF_HOSTED_AI_KEY`/`SELF_HOSTED_AI_MODELS`.
- **Google or Microsoft sign-in:** `RELATICLE_FEATURE_SOCIAL_AUTH=true` plus `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` or `MICROSOFT_CLIENT_ID`/`MICROSOFT_CLIENT_SECRET`.
- **Empty workspaces:** `RELATICLE_FEATURE_ONBOARD_SEED=false` stops new workspaces from getting demo data.

The full list is in upstream's [self-hosting guide](https://github.com/relaticle/relaticle/blob/v3.12.0/packages/Documentation/resources/content/docs/guides/self-hosting.md).

## Resources

The whole app service idles at about 230 MB and fits Railway's 0.5 GB per-service limit (tested with 0.5 GB / 1 vCPU). The defaults in the `Dockerfile` keep it there: 3 PHP-FPM children (on demand, freed after 20 s idle), 64 MB opcache, no CLI opcache, one queue worker. On a bigger plan you can raise `PHP_FPM_PM_MAX_CHILDREN`. If a process inside dies, s6 restarts it. If the first-boot setup fails (for example, Postgres can't be reached for 3 minutes), the container exits non-zero and Railway restarts it.

## Updates

Every version bump lands on `main` with a [`CHANGELOG.md`](CHANGELOG.md) entry, with breaking changes listed first. Railway then shows an update notice in your project. Applying it rebuilds the app service, and the first boot of the new version runs its migrations under a lock. Back up Postgres before you apply a major version.

## Local test

```sh
docker compose -f compose.test.yml up -d --build
# http://localhost:8080 , admin@example.com / Test-Passw0rd-123 (test values only)
```

## Licence

The wrapper files in this repository are MIT. Relaticle itself is AGPL-3.0, © the Relaticle authors.
