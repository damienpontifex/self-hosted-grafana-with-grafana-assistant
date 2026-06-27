# Grafana Assistant in self-hosted Grafana

Runs Grafana (via the `otel-lgtm` container) with the Grafana Assistant plugin,
connected to a Grafana Cloud stack.

ref: https://grafana.com/docs/grafana-cloud/machine-learning/assistant/get-started/self-managed/

## Setup

1. `just start`
2. Open http://localhost:3000 and **log in as `admin` / `admin`**.
   (Don't use the anonymous session — the Assistant requires a real user.)
3. http://localhost:3000/plugins/grafana-assistant-app?page=connection and
   click **Connect to Grafana Cloud**. This pairs the instance with your Cloud
   stack. It's a one-time interactive step and cannot be provisioned from a file.

The pairing is stored in the `grafana-data` volume, so it survives restarts and
container recreates.

> [!NOTE]
> `just clean` runs `docker compose down --volumes`, which deletes the
> `grafana-data` volume and the pairing. Use `just stop` / `just start`
> to keep it, or re-run the Connect flow after a full `just clean`.

## MCP connection for other AI interaction

```bash
mkdir .agents
docker compose exec lgtm cat /etc/lgtm/mcp.json > .agents/mcp.json
```

Claude Code:

```bash
bash <(docker compose exec lgtm cat /etc/lgtm/claude-mcp-setup.sh)
```

## Why not provision the Assistant via YAML? (learnings)

The obvious approach — a `provisioning/plugins/assistant.yaml` with `backendUrl`,
`instanceId`, and an access-policy token — **does not work** with the current
Assistant backend. Don't try it again. What we found:

- The Assistant backend requires an **interactive host pairing** (a device-auth
  style handshake: `/api/assistant/connect/init` → authorize at grafana.com →
  `/api/assistant/connect/poll`). Only "Connect to Grafana Cloud" performs it.
- A raw access-policy token is treated as deprecated "legacy auth". Probing the
  backend directly returns `401 "legacy auth cannot be upgraded because the host
  is not found"` — i.e. the token alone is rejected until a host is paired.
- This handshake is interactive by design and **cannot be expressed in a
  provisioning file**. `plugin.json` confirms it: no `routes`/token-auth config,
  only the managed-service-account `iam` model plus the connect pairing.

Dead-ends ruled out along the way (each looked like the cause, none were the
whole story): wrong provisioning path, `id:` vs `type:` in the YAML, token in the
wrong region, the `assistant:write` scope (hidden from the Cloud Portal "Add
scope" dropdown), and `backendUrl` being the stack URL instead of the dedicated
`https://assistant-<region>.grafana.net/assistant` host. Fixing all of those
still ended at the host-pairing requirement above.

Other otel-lgtm gotchas worth remembering:

- Grafana runs from `/otel-lgtm/grafana`; its provisioning dir is
  `/otel-lgtm/grafana/conf/provisioning` (not `/etc/grafana/...`).
- Grafana logs go to a **file**, not stdout. `ENABLE_LOGS_GRAFANA=true` (set in
  the compose file) routes them to `docker compose logs lgtm`. The file itself is
  `/data/grafana/data/log/grafana.log`.
- The Assistant's user-auth path needs `externalServiceAccounts` +
  `GF_AUTH_MANAGED_SERVICE_ACCOUNTS_ENABLED=true` (both set in the compose file),
  and requests must come from a **real logged-in user** — the anonymous session
  otel-lgtm enables by default is rejected with `invalid user`.
