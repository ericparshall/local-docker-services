# Local Docker Services

A small git repo for **Docker Compose stacks** you run on your machine (dev tools, messengers, databases, etc.).

Each service lives in its own folder under `services/` with:

- `compose.yml` — the stack definition
- `.env.example` — documented env vars (copy to `.env`)
- `README.md` — how to start, stop, and use it
- local data volumes (gitignored)

## Quick start

```bash
# From a service directory
cd services/signal-cli
cp .env.example .env   # edit if needed
docker compose up -d
docker compose logs -f
docker compose down
```

## Ports

**Canonical map: [PORTS.md](./PORTS.md)**

Host ports live in **`18700–18799`** so they never collide with common defaults (8080, 5432, 6379, …).

| Service | Host port | URL |
|---------|-----------|-----|
| signal-cli (native HTTP daemon) | **18701** | `http://127.0.0.1:18701` |

## Layout

```
local-docker-services/
├── README.md
├── PORTS.md                   # static host port map (source of truth)
├── .gitignore
├── scripts/
│   ├── ensure-all-up.ps1      # bring every stack up (waits for Docker)
│   └── install-autostart.ps1  # install Windows logon Scheduled Task
└── services/
    └── signal-cli/            # signal-cli daemon --http → host :18701
        ├── compose.yml
        ├── .env.example
        └── README.md
```

## Always-on (Windows)

Three layers keep services running:

1. **Docker Desktop** starts at Windows logon (`AutoStart` + HKCU Run key).
2. **Container policy** `restart: always` — containers restart when the Docker engine restarts.
3. **Scheduled Task** `LocalDockerServices-EnsureUp` — at logon (+45s) runs `scripts/ensure-all-up.ps1`, which waits for Docker then `docker compose up -d` for every `services/*/compose.yml` (recovers after `compose down`).

```powershell
# Install / reinstall the logon task
powershell -ExecutionPolicy Bypass -File .\scripts\install-autostart.ps1

# Manual bring-up of all services right now
powershell -ExecutionPolicy Bypass -File .\scripts\ensure-all-up.ps1
```

Log: `logs/ensure-all-up.log` (gitignored).

## Adding a new service

1. Create `services/<name>/`
2. Add `compose.yml` (use `restart: always`), `.env.example`, and a short `README.md`
3. Assign a **static host port in 18700–18799** (not the image default) and update **[PORTS.md](./PORTS.md)**
4. Put durable state under a local `data/` folder (already gitignored)
5. New services are picked up automatically by `ensure-all-up.ps1`

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose v2)
- On Windows: WSL2 backend recommended

## Notes

- **Secrets**: never commit `.env` files or account data under `data/`
- **Ports**: static map in [PORTS.md](./PORTS.md) — never bind common defaults on the host
- **Restart**: use `restart: always` so stacks return after reboot / Docker restart
- **signal-cli**: Hermes needs the **native** HTTP daemon (`/api/v1/*`), not `signal-cli-rest-api` (`/v1/*`)
