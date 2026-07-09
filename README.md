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

## Layout

```
local-docker-services/
├── README.md
├── .gitignore
├── scripts/
│   ├── ensure-all-up.ps1      # bring every stack up (waits for Docker)
│   └── install-autostart.ps1  # install Windows logon Scheduled Task
└── services/
    └── signal-cli/            # Signal REST API (signal-cli wrapper)
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
3. Put durable state under a local `data/` folder (already gitignored)
4. Prefer host ports that won’t collide (document them in the service README)
5. New services are picked up automatically by `ensure-all-up.ps1`

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose v2)
- On Windows: WSL2 backend recommended

## Notes

- **Secrets**: never commit `.env` files or account data under `data/`
- **Ports**: each service README lists the host port it binds
- **Restart**: use `restart: always` so stacks return after reboot / Docker restart
