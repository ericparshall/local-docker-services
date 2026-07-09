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
└── services/
    └── signal-cli/          # Signal REST API (signal-cli wrapper)
        ├── compose.yml
        ├── .env.example
        └── README.md
```

## Adding a new service

1. Create `services/<name>/`
2. Add `compose.yml`, `.env.example`, and a short `README.md`
3. Put durable state under a local `data/` folder (already gitignored)
4. Prefer host ports that won’t collide (document them in the service README)

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose v2)
- On Windows: WSL2 backend recommended

## Notes

- **Secrets**: never commit `.env` files or account data under `data/`
- **Ports**: each service README lists the host port it binds
- **Restart**: stacks use `unless-stopped` so they come back after reboot when Docker is running
