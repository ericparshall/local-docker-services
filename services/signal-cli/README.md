# signal-cli (REST API)

Local [signal-cli](https://github.com/AsamK/signal-cli) via the popular Docker wrapper
[bbernhard/signal-cli-rest-api](https://github.com/bbernhard/signal-cli-rest-api).

Exposes a **HTTP REST API** on the host (default `http://localhost:8080`) so you can register a number/device, send/receive messages, and integrate with scripts or other local tools.

## Start / stop

```bash
cd services/signal-cli
cp .env.example .env          # first time only
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down           # stop (keeps ./data)
docker compose down -v        # stop + remove named volumes (not used by default)
```

API base URL: `http://localhost:${SIGNAL_HOST_PORT:-8080}`

Swagger / docs (when the container is up): `http://localhost:8080/v1/docs` or the OpenAPI path from `/v1/about`.

## First-time setup (link a device)

Signal accounts are usually linked as a **secondary device** (recommended) rather than registering a brand-new number from the container.

1. Start the stack (`docker compose up -d`).
2. Create a QR / link URI via the REST API, e.g.:

   ```bash
   # Example: request a device link (check current API paths in the upstream docs)
   curl -X POST "http://localhost:8080/v1/qrcodelink?device_name=local-docker"
   ```

3. Open Signal on your phone → **Settings → Linked devices → Link new device** and scan the QR / use the URI.
4. Config and keys land in `./data` (gitignored). **Back this up**; losing it means re-linking.

Registering a **new** phone number from the API is also possible but involves SMS/voice captchas and is more fragile—prefer linking when you can.

See upstream docs for exact endpoints and modes:

- https://github.com/bbernhard/signal-cli-rest-api
- https://github.com/AsamK/signal-cli

## Configuration

| Variable | Default | Meaning |
|----------|---------|---------|
| `SIGNAL_HOST_PORT` | `8080` | Host port |
| `SIGNAL_IMAGE_TAG` | `latest` | Image tag |
| `SIGNAL_MODE` | `native` | `native` / `normal` / `json-rpc` |

Copy `.env.example` → `.env` to override.

## Data

| Path | Purpose |
|------|---------|
| `./data` | signal-cli account store (`/home/.local/share/signal-cli` in the container) |

Do not commit `./data`. Treat it like private key material.

## Useful commands

```bash
# Health / version
curl -s http://localhost:8080/v1/about | jq .

# List registered accounts (after linking)
curl -s http://localhost:8080/v1/accounts | jq .

# Follow logs
docker compose logs -f signal-cli-rest-api
```

## Security notes

- The REST API is typically **unauthenticated**. Bind to localhost only (default), or put it behind Tailscale/VPN/auth proxy if you expose it.
- Do not publish `8080` to the public internet.
- Keep `./data` private and backed up.

## Troubleshooting

| Symptom | Things to try |
|---------|----------------|
| Port already in use | Change `SIGNAL_HOST_PORT` in `.env` |
| Permission errors on `./data` | Ensure the Docker user can write the bind mount; on Linux you may need to fix ownership |
| Slow / flaky | Try `SIGNAL_MODE=normal` instead of `native` |
| API 404s | Confirm image is up and check upstream docs for path changes |

## Upstream

- Image: `bbernhard/signal-cli-rest-api` on Docker Hub
- Repo: https://github.com/bbernhard/signal-cli-rest-api
