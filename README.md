# Grafana assistant in self hosted

ref: https://grafana.com/docs/grafana-cloud/machine-learning/assistant/get-started/self-managed/

## Setup
1. `cp .env.example .env`
1. Get instance id from https://grafana.com/orgs/{your-org}
1. "Details" button under "Manage your Grafana Cloud stack" has the instance id as the last path element
    - e.g. https://grafana.com/orgs/{your-org}/stacks/{instance-id}
    - Copy instance id into `.env` file
1. Create policy at https://grafana.com/orgs/{your-org}/access-policies
1. Create policy with:
    - metrics:read
    - logs:read
    - traces:read
    - profiles:read
    - alerts:read
    - rules:read
    - dashboards:read
    - dashboards:write
    - datasources:read
1. Add token with the new policy
1. Copy token into `.env` file

## Launch
`just start`
