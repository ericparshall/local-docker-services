# signal-cli (native HTTP daemon)

Local [signal-cli](https://github.com/AsamK/signal-cli) running as an **HTTP daemon**
(`daemon --http`), which is what **Hermes Agent** expects for its Signal adapter.

| | |
|--|--|
| **Host port** | **18701** (see [PORTS.md](../../PORTS.md)) |
| **URL (Hermes)** | `http://127.0.0.1:18701` |
| **Health** | `GET /api/v1/check` → HTTP 200 |
| **SSE events** | `GET /api/v1/events?account=+E.164` |
| **JSON-RPC** | `POST /api/v1/rpc` |
| Container port | 8080 |
| Image | `registry.gitlab.com/packaging/signal-cli/signal-cli-jre` (or `-native`) |

> **Not** the `bbernhard/signal-cli-rest-api` wrapper (`/v1/about`, `/v1/qrcodelink`, …).
> Hermes calls `/api/v1/*` on the **native** daemon only.

## Start / stop

```bash
cd services/signal-cli
cp .env.example .env          # first time only
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down           # stop (keeps ./data)
```

## First-time setup (link a device)

Signal-cli should be a **linked secondary device** (like Signal Desktop), not a
fresh primary registration, unless you intentionally run a bot number.

1. Start the stack (`docker compose up -d`) so the data volume exists.
2. **Stop the daemon** briefly so only one process holds the account store:

   ```bash
   docker compose stop
   ```

3. Generate a link URI / QR payload:

   ```bash
   docker compose run --rm --no-deps signal-cli link -n "HermesAgent"
   ```

   Leave this running. It prints a `sgnl://linkdevice?...` URI (and may print a
   QR if the TTY supports it).

4. On your phone: **Signal → Settings → Linked devices → Link new device** and
   scan / enter the link.
5. When linking finishes, start the daemon again:

   ```bash
   docker compose up -d
   ```

6. Confirm the account is present:

   ```bash
   docker compose run --rm --no-deps signal-cli listAccounts
   curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:18701/api/v1/check
   # expect: 200
   ```

Account material lives under `./data` (gitignored). **Back it up**; losing it
means re-linking.

## Hermes Agent config

In `~/.hermes/.env` (Windows: `%LOCALAPPDATA%\hermes\.env`):

```bash
# Base URL only — do NOT append /v1/about or /api/v1/check
SIGNAL_HTTP_URL=http://127.0.0.1:18701
SIGNAL_ACCOUNT=+1XXXXXXXXXX          # E.164 of the linked number
SIGNAL_ALLOWED_USERS=+1XXXXXXXXXX    # recommended allowlist
```

Then:

```bash
hermes gateway restart
# or: hermes gateway run
```

Docs: https://hermes-agent.nousresearch.com/docs/user-guide/messaging/signal

## Configuration

| Variable | Default | Meaning |
|----------|---------|---------|
| `SIGNAL_HOST_PORT` | **`18701`** | Host port (project static; not 8080) |
| `SIGNAL_VARIANT` | `jre` | `jre` or `native` packaging image |
| `SIGNAL_IMAGE_TAG` | `latest` | Image tag |

Copy `.env.example` → `.env` to override. Prefer keeping `18701` unless it collides;
if you change it, update [PORTS.md](../../PORTS.md) and Hermes `SIGNAL_HTTP_URL`.

## Data

| Path | Purpose |
|------|---------|
| `./data` | signal-cli account store (`/var/lib/signal-cli` in the container) |

Do not commit `./data`. Treat it like private key material.

### Migrating from signal-cli-rest-api

The previous stack used `bbernhard/signal-cli-rest-api` with data at
`/home/.local/share/signal-cli`. Paths differ and an empty / unlinked store is
normal after the switch — **re-link** with the steps above. Do not expect old
REST-only layout files under `./data/data/` to be picked up automatically.

## Useful commands

```bash
# Health (Hermes health check path)
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:18701/api/v1/check

# List linked accounts (daemon may need to be stopped for exclusive lock)
docker compose stop
docker compose run --rm --no-deps signal-cli listAccounts
docker compose up -d

# Logs
docker compose logs -f signal-cli

# One-off signal-cli CLI (daemon stopped recommended)
docker compose stop
docker compose run --rm --no-deps signal-cli --help
docker compose up -d
```

## Security notes

- The HTTP daemon is **unauthenticated**. Publish only on localhost (default
  Docker Desktop host bind) or put it behind Tailscale / VPN / auth proxy.
- Do **not** expose port 18701 to the public internet.
- Protect `./data` like credentials.

## Troubleshooting

| Symptom | Things to try |
|---------|----------------|
| Hermes `health check failed (status 404)` | You are still on REST wrapper URLs. Use base `http://127.0.0.1:18701` and native `/api/v1/check` |
| Port already in use | Check [PORTS.md](../../PORTS.md); free 18701 or pick next free 187xx and update docs + Hermes |
| `Failed to read local accounts list` | Ensure `./data` is writable; recreate with `docker compose run --rm --entrypoint chown …` if needed |
| Link command conflicts with daemon | `docker compose stop` before `link` / `listAccounts`, then `up -d` |
| Flaky native binary | Set `SIGNAL_VARIANT=jre` (default) |

## Upstream

- signal-cli: https://github.com/AsamK/signal-cli
- Packaging images: https://packaging.gitlab.io/signal-cli/installation/docker/
- Hermes Signal docs: https://hermes-agent.nousresearch.com/docs/user-guide/messaging/signal
