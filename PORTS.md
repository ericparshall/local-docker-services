# Port map (host)

All **local-docker-services** stacks bind **static host ports in `18700–18799`**.  
Do **not** use image defaults on the host (e.g. 5432, 6379, 8080, 3000) — those collide with local tools.

Container-internal ports may still be the image default; only the **left** side of `host:container` is our static assignment.

| Service | Host port(s) | Container | Protocol | Notes |
|---------|--------------|-----------|----------|--------|
| **signal-cli** | **18701** | 8080 | HTTP | Native `signal-cli daemon --http` (JSON-RPC + SSE) → `http://127.0.0.1:18701` — Hermes: `GET /api/v1/check` |

## Allocation rules

1. Pick the next free port in `18700–18799` when adding a service.
2. Put the host port in that service’s `.env.example` / `compose.yml` default (not an image-default host port).
3. Update **this file** and the service `README.md` in the same change.
4. Prefer one primary HTTP/API port per service; add extra rows for extra listeners (DB, metrics, etc.).

## Reserved / free block

| Range | Use |
|-------|-----|
| `18700` | Reserved (project sentinel / future gateway) |
| `18701` | signal-cli native HTTP daemon |
| `18702–18799` | Available for next services |

## Quick check

```powershell
# What's bound in our range?
netstat -ano | findstr ":187"
```
