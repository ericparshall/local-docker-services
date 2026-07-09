# signal-cli (REST API)

Local [signal-cli](https://github.com/AsamK/signal-cli) via the popular Docker wrapper
[bbernhard/signal-cli-rest-api](https://github.com/bbernhard/signal-cli-rest-api).

Exposes a **HTTP REST API** on a **static non-default host port**:

| | |
|--|--|
| **Host port** | **18701** (see [PORTS.md](../../PORTS.md)) |
| **URL** | `http://127.0.0.1:18701` |
| Container port | 8080 (image default; not exposed as host 8080) |

## Start / stop

```bash
cd services/signal-cli
cp .env.example .env          # first time only
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down           # stop (keeps ./data)
```

Swagger / docs (when up): try `http://127.0.0.1:18701/v1/docs` or the path from `/v1/about`.

## First-time setup (link a device)

Signal accounts are usually linked as a **secondary device** (recommended) rather than registering a brand-new number from the container.

1. Start the stack (`docker compose up -d`).
2. Create a QR / link URI via the REST API, e.g.:

   ```bash
   curl -X POST "http://127.0.0.1:18701/v1/qrcodelink?device_name=local-docker"
   ```

3. Open Signal on your phone → **Settings → Linked devices → Link new device** and scan the QR / use the URI.
4. Config and keys land in `./data` (gitignored). **Back this up**; losing it means re-linking.

See upstream docs for exact endpoints and modes:

- https://github.com/bbernhard/signal-cli-rest-api
- https://github.com/AsamK/signal-cli

## Configuration

| Variable | Default | Meaning |
|----------|---------|---------|
| `SIGNAL_HOST_PORT` | **`18701`** | Host port (project static; not 8080) |
| `SIGNAL_IMAGE_TAG` | `latest` | Image tag |
| `SIGNAL_MODE` | `native` | `native` / `normal` / `json-rpc` |

Copy `.env.example` → `.env` to override. Prefer keeping `18701` unless it collides; if you change it, update [PORTS.md](../../PORTS.md).

## Data

| Path | Purpose |
|------|---------|
| `./data` | signal-cli account store (`/home/.local/share/signal-cli` in the container) |

Do not commit `./data`. Treat it like private key material.

## Useful commands

```bash
# Health / version
curl -s http://127.0.0.1:18701/v1/about | jq .

# List registered accounts (after linking)
curl -s http://127.0.0.1:18701/v1/accounts | jq .

# Follow logs
docker compose logs -f signal-cli-rest-api
```

## Security notes

- The REST API is typically **unauthenticated**. Bind to localhost only (default), or put it behind Tailscale/VPN/auth proxy if you expose it.
- Do not publish this port to the public internet.

## Troubleshooting

| Symptom | Things to try |
|---------|----------------|
| Port already in use | Check [PORTS.md](../../PORTS.md); free 18701 or pick next free 187xx and update docs |
| Permission errors on `./data` | Ensure the Docker user can write the bind mount |
| Slow / flaky | Try `SIGNAL_MODE=normal` instead of `native` |
| API 404s | Confirm image is up and check upstream docs for path changes |

## Upstream

- Image: `bbernhard/signal-cli-rest-api` on Docker Hub
- Repo: https://github.com/bbernhard/signal-cli-rest-api
