# OBS1466: Your AI Is in Production. Who's Watching It?

Splunk `.conf` breakout companion material for:

**Your AI Is in Production. Who's Watching It? A Practitioner's Guide to Observability with Splunk**

This repository is the practical take-home kit for the session. It is intentionally focused on the most reusable artifacts:

- Splunk searches
- a Splunk dashboard export
- the field and operating model behind the talk

This is not a full demo-framework repo. The goal here is to give practitioners clean, useful building blocks they can adapt in their own environments.

## What This Covers

The session focuses on how to observe AI systems like production systems, not just model endpoints. The core use case is a real-world style incident:

1. a user asks an AI agent to create a file
2. the agent completes the task
3. no approved delivery path exists
4. the agent starts improvising
5. endpoint controls catch behavior that prompt logs alone would miss
6. Splunk reconstructs the full story across agent, trace, and endpoint telemetry

The searches in this repo are built around that operator view:

- intent
- actions taken
- policy or control outcome
- cost and performance signals
- searchable evidence for investigation

## Repository Layout

```text
dashboards/
  ai_observability_demo.xml
  ai_health_dashboard.xml

searches/
  01_agent_timeline.spl
  02_unapproved_file_share_detection.spl
  03_ai_health_dashboard.spl
  04_cost_runaway.spl
  05_prompt_injection.spl
  06_quality_latency_drift.spl
  07_agent_chat_transcript.spl
  08_agent_workstream.spl
  09_raw_agent_logs.spl
  10_live_agent_run.spl
  11_live_agent_workstream.spl
  12_edr_correlation.spl
```

## Searches

### Core story and investigation

- `01_agent_timeline.spl`
  Reconstructs the end-to-end incident timeline.

- `02_unapproved_file_share_detection.spl`
  Flags AI-created files paired with a blocked delivery path (`policy_action=blocked`).

- `07_agent_chat_transcript.spl`
  Shows the human-visible chat sequence.

- `08_agent_workstream.spl`
  Shows the hidden agent decisions, tool calls, file creation, and control outcomes.

- `09_raw_agent_logs.spl`
  Compact raw evidence view for analysts and screenshots.

- `10_live_agent_run.spl`
  Summary of the latest live agent run.

- `11_live_agent_workstream.spl`
  Timeline for the latest live run across all event types.

- `12_edr_correlation.spl`
  Joins agent trace events with EDR process/network blocks on the same host within a 5-minute window. This is the search that ties the chat, tool call, policy block, and endpoint control into one row. It is the core of the talk's true story.

### Health, risk, and operations

- `03_ai_health_dashboard.spl`
  Reliability and risk summary view.

- `04_cost_runaway.spl`
  Detects spend velocity problems, retry loops, and expensive workflow patterns. Save as a scheduled alert running every 15 minutes. The $50 threshold is a conference demo value — tune to 2–3× your normal per-session baseline before production use.

- `05_prompt_injection.spl`
  Treats prompt injection as observable security telemetry, not just input validation. Save as a scheduled alert running every 5 minutes. Threshold 0.75; includes `policy_action=blocked` regardless of score.

- `06_quality_latency_drift.spl`
  Surfaces quality, latency, and behavior drift patterns that matter in production.

## Dashboard

- `dashboards/ai_observability_demo.xml`
  Splunk dashboard export used to support the talk storyline and screenshots.

Depending on your environment, you may want to import this as a starting point and then retarget indexes, field names, or saved searches.

## Expected Telemetry Model

These artifacts are easiest to adapt when your telemetry can answer a few simple questions with searchable fields:

- Who initiated the request?
- Which workflow or agent handled it?
- What trace or correlation ID ties the events together?
- Which tools were called?
- What file or object was created?
- What external destination was attempted?
- What policy, guardrail, or endpoint control fired?
- What did it cost?
- How long did it take?

The exact field names can vary. The important part is having a stable telemetry contract that lets Splunk correlate intent, action, and control outcome.

### Field reference

All searches use `index=demo_ai_obs sourcetype=ai:agent_event`. The `event_sourcetype` field routes events to the appropriate search pattern.

| Field | Present in | Example value | Notes |
|-------|-----------|--------------|-------|
| `event_sourcetype` | all | `ai:trace`, `ai:chat`, `ai:agent_log`, `ai:metric` | Sub-type inside the wrapping `ai:agent_event` sourcetype |
| `trace_id` | all | `tr_live_20260902_143201` | Correlation key across all event types for one agent run |
| `demo_run_epoch` | all | `1725284521` | Unix epoch of the run start; searches pin to `max(demo_run_epoch)` to show the latest run |
| `demo_run_id` | all | `live_20260902_143201` | Human-readable run identifier |
| `span_name` | `ai:trace` | `model.turn`, `tool.file_write`, `tool.share_config_check` | Step in the agent workstream |
| `turn_seq` | `ai:trace` | `1`, `2` | Model turn number within the run |
| `tool_name` | `ai:agent_log` | `crm_query`, `file_write`, `share_config_check` | Tool the agent called |
| `tool_output_summary` | `ai:agent_log`, `ai:trace` | `"File written: open_renewal_accounts.csv"` | One-line outcome |
| `policy_action` | `ai:agent_log`, `ai:trace` | `blocked`, `allowed` | Guardrail or policy decision |
| `file_path` | `ai:agent_log`, `ai:trace` | `outputs/agent-files/open_renewal_accounts.csv` | Created or accessed file |
| `file_hash` | `ai:agent_log` | `sha256=7028648e...` | SHA-256 of the created file |
| `role` | `ai:chat` | `user`, `assistant` | Speaker in the chat transcript |
| `message` | `ai:chat` | `"Can you create a CSV..."` | Full message text |
| `message_preview` | `ai:chat` | first 250 chars | Truncated for display |
| `cost_usd` | `ai:metric` | `0.0042` | Model API cost for this run |
| `duration_ms` | `ai:metric` | `3820` | End-to-end latency in ms |
| `quality_score` | `ai:metric` | `0.92` | Application-defined output quality (0–1) |
| `input_tokens` | `ai:metric` | `1240` | Tokens sent to the model |
| `output_tokens` | `ai:metric` | `310` | Tokens returned |
| `prompt_injection_score` | `ai:metric` | `0.12` | Injection risk score (0–1); threshold alert at ≥ 0.75 |
| `model_name` | `ai:metric` | `claude-sonnet-4-6` | Model ID |
| `model_provider` | `ai:metric` | `bedrock` | API provider |
| `host` | all | `ai-agent-host` | Source host; join key for EDR correlation |
| `user_id` | all | `demo_user` | Initiating user |

**Adapting field names:** if your agent framework uses different names (e.g. `run_id` instead of `trace_id`, or `latency` instead of `duration_ms`), rename with `eval` before the `stats` step rather than editing every search individually.

**Native sourcetypes:** the searches above use `sourcetype=ai:agent_event event_sourcetype=<type>` because that is how the demo import path (`import_agent_logs_oneshot.sh` using Splunk `collect`) stamps events. If your agent emits events via HEC with their own sourcetypes (`ai:chat`, `ai:trace`, etc.), replace `sourcetype=ai:agent_event event_sourcetype=ai:metric` with `sourcetype=ai:metric` in searches 03–06 and 10–11.

## Splunk Adaptation Notes

These searches were built for a local demo index and a conference storyline. In a real deployment, you will usually update:

- index names
- sourcetypes
- field names
- alert thresholds
- dashboard panel queries

The searches are deliberately kept readable so teams can tune them quickly.

## Recommended First Steps

If you want to adapt this material in your own environment:

1. Start with `02_unapproved_file_share_detection.spl`
2. Validate that your telemetry includes a usable correlation field such as `trace_id`
3. Map your application, agent, and endpoint fields into one searchable story
4. Import the dashboard XML and retarget the panels
5. Tune thresholds for cost, latency, and injection based on your normal baselines

## Session Goal

The point of this material is not to convince you that every AI system needs a giant monitoring stack on day one.

It is to give you a practical starting point for answering:

- what the agent tried to do
- what it actually did
- what it touched
- what it cost
- and whether it stayed inside the boundary

If your AI is in production, those are not nice-to-have questions.
