# OBS1466: Your AI Is in Production. Who's Watching It?

Splunk companion repo for the conf26 talk. Contains searches, dashboards, sample data, and alert configurations.

## What this repo is for

Practitioners adapting the talk's searches and dashboards to their own AI observability setup. The telemetry model here is the reference; field names and index names are meant to be changed.

## Key conventions

- All searches target `index=demo_ai_obs`. Change this to your index.
- All searches filter `demo_name=ai_observability_conf26`. Remove or change this when adapting.
- Events are wrapped in a single `sourcetype=ai:agent_event` with `event_sourcetype` routing to sub-types (`ai:chat`, `ai:trace`, `ai:agent_log`, `ai:metric`). This is the collect-path layout. If your agent emits native sourcetypes directly via HEC, drop the `sourcetype=ai:agent_event event_sourcetype=<type>` wrapping and just filter on `sourcetype=ai:trace` etc.
- `demo_run_epoch` is the Unix epoch of the run start. Searches use `eventstats max(demo_run_epoch)` to pin to the latest run. In production, replace with a real time range or a run ID field.
- EDR events use `sourcetype=edr:process` and join on `host` and `trace_id`.

## Quick start

1. Send sample events: `cd examples && ./seed_splunk.sh`
2. Verify: `index=demo_ai_obs trace_id=tr_file_share_001 | stats count by sourcetype`
3. Run search 08 (agent workstream) to see the hidden story
4. Run search 12 (EDR correlation) to see the endpoint tie-in
5. Import `dashboards/ai_observability_demo.xml` and `dashboards/ai_health_dashboard.xml`

## Adapting to your environment

The two things to change first:
- `index=demo_ai_obs` → your AI telemetry index
- `demo_name=ai_observability_conf26` → remove or replace with your app name field

Then map your field names using the field reference table in README.md.

## Alert setup

See `examples/savedsearches.conf` for searches 04 (cost runaway) and 05 (prompt injection) as Splunk alert definitions. They ship `disabled = 1` — tune thresholds before enabling.
