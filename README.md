# Vocero CRM on Railway — WhatsApp CRM with an AI agent inbox, owner pre-created

Vocero CRM is an open-source CRM for businesses that sell over WhatsApp (Cloud API): shared inbox, contacts, pipeline, notes, templates, optional AI agent, optional Instagram/Messenger/TikTok channels. Deploy on Railway with one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/eVGJ3T)

Built from the official image `ghcr.io/kevinrivm/vocero-crm:2.7.0` (app unmodified) plus PostgreSQL 16. Upstream: https://github.com/kevinrivm/vocero-crm

## What this template adds

Upstream closes public sign-up after the **first** registration, which creates the organization and its owner. On a public Railway URL anyone could be first. This packaging creates the owner account on a private loopback port **before** the public port opens, from a per-deploy generated password, so sign-up is already closed when your URL goes live.

## After deploy

1. Copy `VOCERO_ADMIN_PASSWORD` from the `vocero` service's **Variables** tab.
2. Sign in with `admin@example.com` and that password; change email and password in your account settings.
3. Connect WhatsApp in **Settings → WhatsApp**. The webhook URL is `https://<your-domain>/api/webhooks/wa/<META_WEBHOOK_VERIFY_TOKEN>` (the token is in Variables). A Meta WhatsApp Business app is required for a real inbox; Meta may charge per conversation.
4. Optional: add an AI provider key in **Settings → AI**.

## Services

| Service | Image | Volume |
|---|---|---|
| `vocero` | `ghcr.io/onepush-dev/vocero-crm:2.7.0-r3` | `/data` (attachments, logo, icon) |
| `Postgres` | `postgres:16-alpine` (pinned digest) | `/var/lib/postgresql/data` |

The optional Nea agent service and MinIO bucket from upstream compose are not included: Vocero runs as a full manual inbox without them, and attachments go to the `/data` volume.

## Variables (`vocero`)

| Variable | Default | Purpose |
|---|---|---|
| `DATABASE_URL` | reference to `Postgres` | PostgreSQL connection string. |
| `APP_BASE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL; used for auth and the WhatsApp webhook URL. |
| `BETTER_AUTH_SECRET` | generated | Signs login sessions. |
| `ENCRYPTION_KEY` | generated (43 base64 chars = 32 bytes) | Encrypts WhatsApp/AI tokens at rest. Never change it after connecting channels. |
| `META_WEBHOOK_VERIFY_TOKEN` | generated (64 hex) | Webhook verify token and secret URL segment. |
| `VOCERO_ADMIN_PASSWORD` | generated | Password of the owner account created on first boot. |
| `VOCERO_ADMIN_EMAIL` | `admin@example.com` (image default) | Owner login email. |

## License

Vocero CRM is MIT. This repository only adds a Dockerfile and `railway-start.sh`.
