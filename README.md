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
```

## Searches

### Core story and investigation

- `01_agent_timeline.spl`
  Reconstructs the end-to-end incident timeline.

- `02_unapproved_file_share_detection.spl`
  Flags AI-created files paired with unapproved upload destinations.

- `07_agent_chat_transcript.spl`
  Shows the human-visible chat sequence.

- `08_agent_workstream.spl`
  Shows the hidden agent decisions, tool calls, file creation, and control outcomes.

- `09_raw_agent_logs.spl`
  Compact raw evidence view for analysts and screenshots.

- `10_live_agent_run.spl`
  Summary of the latest live agent run.

- `11_live_agent_workstream.spl`
  Timeline for the latest live run.

### Health, risk, and operations

- `03_ai_health_dashboard.spl`
  Reliability and risk summary view.

- `04_cost_runaway.spl`
  Detects spend velocity problems, retry loops, and expensive workflow patterns.

- `05_prompt_injection.spl`
  Treats prompt injection as observable security telemetry, not just input validation.

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
